import CryptoKit
import Foundation

@MainActor
final class CatalogStore: ObservableObject {
    @Published private(set) var apps: [AppEntry] = []
    @Published private(set) var importError: String?
    @Published private(set) var persistenceError: String?
    @Published private(set) var isEnriching = false
    @Published private(set) var isEnrichmentPaused = false
    @Published private(set) var refreshingAppIDs: Set<AppEntry.ID> = []
    @Published private(set) var enrichmentProgress = ""
    @Published private(set) var pendingTranslation: PendingTranslation?
    @Published private(set) var catalogRevision = 0
    @Published var pendingWebsitePrompt: PendingWebsitePrompt?
    @Published var websiteReviewSummary: WebsiteReviewSummary?
    @Published var searchText = ""
    @Published var selectedCategory: String?
    @Published var selectedAppID: AppEntry.ID?

    private let persistence: CatalogPersistence
    private let targetLanguageProvider: @Sendable () -> String
    private let licenseStorage: any LicenseStorage
    private let homebrewCaskMetadataCache: HomebrewCaskMetadataCache
    private var enrichmentTask: Task<Void, Never>?
    private var promptedWebsiteAppIDs: Set<AppEntry.ID> = []
    static let needsReviewFilter = "__needs_review__"
    static let subcategoryFilterPrefix = "__subcategory__:"
    static let tagFilterPrefix = "__tag__:"

    struct FolderNode: Identifiable, Hashable {
        let name: String
        let path: String
        let count: Int
        let children: [FolderNode]

        var id: String { path }
    }

    init(
        persistence: CatalogPersistence = CatalogPersistence(),
        licenseStorage: any LicenseStorage = LicenseKeychainStore.shared,
        homebrewCaskMetadataCache: HomebrewCaskMetadataCache = .shared,
        targetLanguageProvider: @escaping @Sendable () -> String = {
            AppLanguageChoice.current.resolvedLanguage()
        }
    ) {
        self.persistence = persistence
        self.licenseStorage = licenseStorage
        self.homebrewCaskMetadataCache = homebrewCaskMetadataCache
        self.targetLanguageProvider = targetLanguageProvider
    }

    var filteredApps: [AppEntry] {
        apps.filter { app in
            let hasSearch = !searchText.normalizedForCatalogSearch.isEmpty
            let matchesCategory = hasSearch
                || selectedCategory == nil
                || (
                    selectedCategory == Self.needsReviewFilter
                        ? app.reviewStatus == .needsReview
                        : matchesSelectedCategory(app)
                )
            return matchesCategory && (!hasSearch || app.matchesSearch(searchText))
        }
    }

    var categories: [(name: String, count: Int)] {
        Dictionary(grouping: apps, by: \.category)
            .map { ($0.key, $0.value.count) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var selectedApp: AppEntry? {
        apps.first { $0.id == selectedAppID }
    }

    var needsReviewCount: Int {
        apps.filter { $0.reviewStatus == .needsReview }.count
    }

    var websitePromptExclusions: [AppEntry] {
        apps.filter {
            $0.suppressesWebsitePrompt
                && !hasLocalFileInExcludedScanArea($0)
        }
            .sorted(by: Self.sortApps)
    }

    var appsNeedingWebsiteReview: [AppEntry] {
        apps.filter { app in
            app.homepage == nil
                && !app.suppressesWebsitePrompt
                && !hasLocalFileInExcludedScanArea(app)
                && needsWebsiteReview(app)
        }
        .sorted(by: Self.sortApps)
    }

    var selectedCollectionTitle: String {
        guard let selectedCategory else {
            return AppLocalization.text("Alle Apps")
        }
        if selectedCategory == Self.needsReviewFilter {
            return AppLocalization.text("Zu prüfen")
        }
        if let selection = Self.decodeSubcategoryFilter(selectedCategory) {
            return selection.subcategory
        }
        if let tag = Self.decodeTagFilter(selectedCategory) {
            return "#\(tag)"
        }
        return selectedCategory
    }

    func folderTree(for category: String) -> [FolderNode] {
        let pathsByApp = apps
            .filter { $0.category == category }
            .map { ($0.id, folderPaths(for: $0)) }
        let paths = Set(pathsByApp.flatMap(\.1))
        let topLevel = paths.filter { !$0.contains("/") }
        return topLevel
            .map { makeFolderNode(path: $0, paths: paths, pathsByApp: pathsByApp) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func subcategoryFilter(category: String, subcategory: String) -> String {
        "\(subcategoryFilterPrefix)\(category)\u{1F}\(subcategory)"
    }

    static func tagFilter(_ tag: String) -> String {
        "\(tagFilterPrefix)\(tag)"
    }

    private static func decodeSubcategoryFilter(
        _ value: String
    ) -> (category: String, subcategory: String)? {
        guard value.hasPrefix(subcategoryFilterPrefix) else {
            return nil
        }
        let components = value
            .dropFirst(subcategoryFilterPrefix.count)
            .split(separator: "\u{1F}", maxSplits: 1)
            .map(String.init)
        guard components.count == 2 else {
            return nil
        }
        return (components[0], components[1])
    }

    static func decodeTagFilter(_ value: String) -> String? {
        guard value.hasPrefix(tagFilterPrefix) else {
            return nil
        }
        let tag = String(value.dropFirst(tagFilterPrefix.count))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return tag.isEmpty ? nil : tag
    }

    private func matchesSelectedCategory(_ app: AppEntry) -> Bool {
        guard let selectedCategory else {
            return true
        }
        if let selection = Self.decodeSubcategoryFilter(selectedCategory) {
            return app.category == selection.category
                && folderPaths(for: app).contains {
                    $0 == selection.subcategory
                        || $0.hasPrefix(selection.subcategory + "/")
                }
        }
        if let tag = Self.decodeTagFilter(selectedCategory) {
            let normalizedTag = tag.normalizedForCatalogSearch
            return app.tags.contains {
                $0.normalizedForCatalogSearch == normalizedTag
            }
        }
        return app.category == selectedCategory
    }

    var tags: [(name: String, count: Int)] {
        Dictionary(
            grouping: apps.flatMap(\.tags),
            by: { $0.normalizedForCatalogSearch }
        )
        .compactMap { _, values in
            values.first.map { ($0, values.count) }
        }
        .sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    var statistics: CatalogStatistics {
        CatalogStatistics(
            totalApps: apps.count,
            appsPerCategory: Dictionary(grouping: apps, by: \.category)
                .map { ($0.key, $0.value.count) }
                .sorted {
                    if $0.1 == $1.1 {
                        return $0.0.localizedStandardCompare($1.0)
                            == .orderedAscending
                    }
                    return $0.1 > $1.1
                },
            totalSizeInBytes: apps.reduce(0) {
                $0 + $1.totalSizeInBytes
            },
            appsWithoutDescription: apps.filter {
                $0.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && $0.details.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
            }.count,
            appsWithoutIcon: apps.filter { !$0.hasIcon }.count,
            appsWithoutHomepage: apps.filter { $0.homepage == nil }.count,
            appsWithLicenseData: apps.filter {
                licenseStorage.hasRecord(for: $0.id)
            }.count
        )
    }

    private func folderPaths(for app: AppEntry) -> Set<String> {
        var paths = Set<String>()
        for file in app.files {
            let components = file.relativePath.split(separator: "/").map(String.init)
            guard components.first == app.category, components.count > 2 else {
                continue
            }
            let folders = Array(components.dropFirst().dropLast())
            addFolderHierarchy(folders.joined(separator: "/"), to: &paths)
        }
        return paths
    }

    private func addFolderHierarchy(
        _ path: String,
        to paths: inout Set<String>
    ) {
        let folders = path.split(separator: "/").map(String.init)
        guard !folders.isEmpty else {
            return
        }
        for depth in 1...folders.count {
            paths.insert(folders.prefix(depth).joined(separator: "/"))
        }
    }

    private func makeFolderNode(
        path: String,
        paths: Set<String>,
        pathsByApp: [(AppEntry.ID, Set<String>)]
    ) -> FolderNode {
        let childPrefix = path + "/"
        let children = paths.filter {
            $0.hasPrefix(childPrefix)
                && !$0.dropFirst(childPrefix.count).contains("/")
        }
        .map {
            makeFolderNode(path: $0, paths: paths, pathsByApp: pathsByApp)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        let count = pathsByApp.filter { _, appPaths in
            appPaths.contains {
                $0 == path || $0.hasPrefix(childPrefix)
            }
        }.count
        return FolderNode(
            name: path.split(separator: "/").last.map(String.init) ?? path,
            path: path,
            count: count,
            children: children
        )
    }

    func loadBundledCatalog() async {
        do {
            let persistence = persistence
            if let savedApps = try await Task.detached(
                operation: { try persistence.load() }
            ).value {
                let repairedApps = Self.splittingMergedEntries(in: savedApps)
                let enrichedApps = AppMetadataEnricher().enrich(
                    repairedApps.filter(CatalogEntryFilter().shouldInclude)
                )
                apps = migrateIcons(in: enrichedApps)
                    .sorted(by: Self.sortApps)
                let removedExcludedApps = removeExcludedScanAreaApps()
                importError = nil
                if apps != savedApps || removedExcludedApps {
                    persist()
                }
                return
            }
        } catch {
            persistenceError = "Der gespeicherte Katalog konnte nicht geladen werden: \(error.localizedDescription)"
        }

        apps = []
        importError = nil
        persist()
    }

    static func splittingMergedEntries(in entries: [AppEntry]) -> [AppEntry] {
        entries.flatMap { entry in
            let splitEntries = AppCatalogBuilder().buildEntries(
                from: entry.files
            )
            guard !splitEntries.isEmpty else {
                return [entry]
            }
            let retainedIndex = splitEntries.firstIndex {
                $0.name.normalizedForCatalogSearch
                    == entry.name.normalizedForCatalogSearch
            } ?? 0
            return splitEntries.enumerated().map { index, splitEntry in
                guard index == retainedIndex else {
                    return splitEntry
                }
                var retainedEntry = entry
                retainedEntry.name = splitEntry.name
                retainedEntry.category = splitEntry.category
                retainedEntry.subcategory = splitEntry.subcategory
                retainedEntry.files = splitEntry.files
                return retainedEntry
            }
        }
    }

    func refreshDescriptionTranslations() {
        pendingTranslation = nil
        let targetLanguage = targetLanguageProvider()
        for index in apps.indices {
            let remainingSuggestions = apps[index].suggestions.filter {
                !($0.kind == .description
                    && $0.needsTranslation
                    && DescriptionLanguageProcessor.matches(
                        $0.detectedLanguage,
                        targetLanguage: targetLanguage
                    ))
            }
            apps[index].reviewSuggestions = remainingSuggestions
            guard !apps[index].customizations.description,
                  !apps[index].details.trimmingCharacters(
                      in: .whitespacesAndNewlines
                  ).isEmpty,
                  let language = DescriptionLanguageProcessor.detectedLanguage(
                      for: apps[index].details
                  ),
                  !DescriptionLanguageProcessor.matches(
                      language,
                      targetLanguage: targetLanguage
                  ),
                  !apps[index].suggestions.contains(where: {
                      $0.kind == .description
                          && $0.needsTranslation
                          && $0.detectedLanguage == language
                  })
            else {
                continue
            }
            addSuggestion(
                CatalogSuggestion(
                    kind: .description,
                    value: apps[index].details,
                    sourceLabel: "Gespeicherte Beschreibung",
                    detectedLanguage: language,
                    needsTranslation: true
                ),
                to: index
            )
        }
        queueNextTranslation()
    }

    func add(_ app: AppEntry) {
        add([app])
    }

    func add(_ newApps: [AppEntry]) {
        guard !newApps.isEmpty else {
            return
        }
        let enrichedApps = newApps.map {
            migrateIcon(in: AppMetadataEnricher().enrich($0))
        }
        apps.append(contentsOf: enrichedApps)
        apps.sort(by: Self.sortApps)
        selectedAppID = enrichedApps.last?.id
        persist()
    }

    func update(_ app: AppEntry) {
        guard let index = apps.firstIndex(where: { $0.id == app.id }) else {
            return
        }
        let previous = apps[index]
        var updated = app
        var customizations = previous.customizations
        if app.iconOrigin == .manual
            && (
                previous.iconFileName != app.iconFileName
                    || app.iconData != nil
            )
        {
            customizations.icon = true
        }
        if previous.summary != app.summary || previous.details != app.details {
            customizations.description = true
        }
        if previous.homepage != app.homepage
            || previous.downloadURL != app.downloadURL
            || previous.githubURL != app.githubURL
        {
            customizations.links = true
        }
        updated.userCustomizations = customizations
        updated.metadataSources = previous.metadataSources
        updated.iconOrigin = app.iconOrigin ?? previous.iconOrigin
        let resolvedMetadata = previous.iconFileName != app.iconFileName
            || app.iconData != nil
            || previous.summary != app.summary
            || previous.details != app.details
            || previous.homepage != app.homepage
            || previous.downloadURL != app.downloadURL
            || previous.githubURL != app.githubURL
        updated.reviewSuggestions = resolvedMetadata
            ? []
            : previous.reviewSuggestions
        if resolvedMetadata {
            updated.reviewStatus = .confirmed
        }
        for url in [updated.homepage, updated.githubURL].compactMap({ $0 }) {
            ConfirmedMetadataMatchStore.shared.confirm(
                appName: updated.name,
                url: url
            )
        }
        apps[index] = migrateIcon(in: updated)
        apps.sort(by: Self.sortApps)
        selectedAppID = app.id
        persist()
    }

    func applyOnlineMetadata(
        _ metadata: AppleArtworkLookup.Metadata,
        iconData: Data?,
        to appID: AppEntry.ID
    ) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else {
            return
        }
        guard metadata.match.decision == .automatic else {
            let identifier = "apple:\(metadata.trackID)"
            if !apps[index].customizations.links {
                if let homepage = metadata.homepage {
                    addSuggestion(
                        CatalogSuggestion(
                            kind: .homepage,
                            value: homepage.absoluteString,
                            sourceLabel: matchLabel(
                                "Apple",
                                match: metadata.match
                            ),
                            sourceURL: homepage,
                            sourceIdentifier: identifier
                        ),
                        to: index
                    )
                }
                if let downloadURL = metadata.downloadURL {
                    addSuggestion(
                        CatalogSuggestion(
                            kind: .download,
                            value: downloadURL.absoluteString,
                            sourceLabel: matchLabel(
                                "Apple",
                                match: metadata.match
                            ),
                            sourceURL: downloadURL,
                            sourceIdentifier: identifier
                        ),
                        to: index
                    )
                }
            }
            if let description = metadata.description,
               AppMetadataEnricher.needsDescriptionExpansion(
                   apps[index].details
               )
            {
                addDescriptionSuggestion(
                    description,
                    source: matchLabel("Apple", match: metadata.match),
                    sourceURL: metadata.homepage ?? metadata.downloadURL,
                    sourceIdentifier: identifier,
                    to: index
                )
            }
            persist()
            return
        }
        if apps[index].developer == nil {
            apps[index].developer = metadata.developer
        }
        if !apps[index].customizations.links {
            if apps[index].homepage == nil,
               let homepage = metadata.homepage {
                apps[index].homepage = homepage
            }
            if let downloadURL = metadata.downloadURL {
                apps[index].downloadURL = downloadURL
            }
        }
        if !apps[index].hasIcon,
           !apps[index].customizations.icon,
           let iconData,
           isAcceptableAutomaticOnlineIcon(iconData, for: apps[index])
        {
            apps[index].iconData = iconData
            apps[index].iconOrigin = .iTunes
            apps[index] = migrateIcon(in: apps[index])
            addSource("iTunes", to: index)
        }
        if AppMetadataEnricher.needsDescriptionExpansion(apps[index].details),
           !apps[index].customizations.description,
           let description = metadata.description,
           !description.isEmpty
        {
            recordDescription(description, source: "iTunes", for: appID)
        }
        if metadata.homepage != nil || metadata.downloadURL != nil {
            addSource("iTunes", to: index)
        }
        persist()
    }

    func enrichCatalog() async {
        guard enrichmentTask == nil else {
            return
        }
        isEnriching = true
        isEnrichmentPaused = false
        enrichmentProgress = "0 / 0"
        websiteReviewSummary = nil
        enrichmentTask = Task { [weak self] in
            await self?.runOnlineEnrichment()
        }
    }

    func isRefreshingApp(_ appID: AppEntry.ID) -> Bool {
        refreshingAppIDs.contains(appID)
    }

    func refreshApp(_ app: AppEntry) async {
        await refreshApp(id: app.id)
    }

    func refreshApp(id appID: AppEntry.ID) async {
        guard !refreshingAppIDs.contains(appID),
              apps.contains(where: { $0.id == appID })
        else {
            return
        }
        refreshingAppIDs.insert(appID)
        defer {
            refreshingAppIDs.remove(appID)
        }

        prepareForOnlineRefresh(appID)
        try? await homebrewCaskMetadataCache.refresh()
        applyLocalFastScanMetadata(to: appID)
        persist()

        guard let app = apps.first(where: { $0.id == appID }) else {
            return
        }
        markOnlineLookupStatus(.running, for: appID)
        let fastResult = await OnlineEnrichmentLookup.fastResult(for: app)
        let fastChanged = applyFastResult(fastResult)
        updateOnlineLookupStatus(
            for: appID,
            changed: fastChanged,
            recordMiss: !OnlineUpdateSettings.extendedSearchEnabled
        )
        persist()

        if OnlineUpdateSettings.extendedSearchEnabled,
           let refreshedApp = apps.first(where: { $0.id == appID }),
           !hasCompleteOnlineMetadata(refreshedApp)
        {
            markOnlineLookupStatus(.running, for: appID)
            let slowResult = await OnlineEnrichmentLookup.slowResult(
                for: refreshedApp
            )
            let slowChanged = applySlowResult(slowResult)
            updateOnlineLookupStatus(
                for: appID,
                changed: slowChanged,
                recordMiss: true
            )
            persist()
        }

        if let index = apps.firstIndex(where: { $0.id == appID }),
           needsReview(apps[index])
        {
            apps[index].reviewStatus = .needsReview
        }
        queueNextTranslation()
        updateWebsiteReviewSummaryAfterChange()
        persist()
    }

    func pauseEnrichment() {
        isEnrichmentPaused = true
    }

    func resumeEnrichment() {
        isEnrichmentPaused = false
    }

    func cancelEnrichment() {
        enrichmentTask?.cancel()
        enrichmentTask = nil
        isEnriching = false
        isEnrichmentPaused = false
        enrichmentProgress = ""
        for index in apps.indices
            where apps[index].onlineLookupStatus == .running
        {
            apps[index].onlineLookupStatus = .open
        }
        persist()
    }

    private func runOnlineEnrichment() async {
        isEnriching = true
        let measurement = ProcessUsageMeasurement()
        var measuredAppCount = 0
        let concurrency = OnlineUpdateSettings.currentConcurrency
        let usesExtendedSearch = OnlineUpdateSettings.extendedSearchEnabled
        defer {
            measurement.result(
                concurrency: concurrency,
                appCount: measuredAppCount
            ).save()
            isEnriching = false
            isEnrichmentPaused = false
            enrichmentProgress = ""
            enrichmentTask = nil
        }

        for index in apps.indices {
            pruneInvalidSuggestions(at: index)
            repairIncorrectAutomaticIconProtection(at: index)
            if let iconData = iconData(for: apps[index]),
               !IconQualityInspector.isLikelyAppIcon(iconData)
            {
                IconStore.shared.delete(fileName: apps[index].iconFileName)
                apps[index].iconFileName = nil
                apps[index].iconData = nil
            }
            if let homepage = apps[index].homepage,
               !OfficialWebsiteLookup.isOfficialCandidate(homepage)
            {
                apps[index].homepage = nil
            }
        }
        removeDuplicateAutomaticOnlineIcons()
        enrichmentProgress = "Homebrew-Cask-Katalog wird aktualisiert"
        try? await homebrewCaskMetadataCache.refresh()
        applyLocalFastScanMetadata()
        persist()

        let candidates = apps.filter {
            needsOnlineMetadata($0)
                && (
                    usesExtendedSearch
                        || !OnlineEnrichmentAttemptCache.shared.shouldSkip($0)
                )
        }
        measuredAppCount = candidates.count
        await runFastOnlineEnrichment(
            candidates,
            concurrency: concurrency,
            total: candidates.count,
            recordMisses: !usesExtendedSearch
        )

        if usesExtendedSearch {
            let candidateIDs = Set(candidates.map(\.id))
            let remaining = apps.filter {
                candidateIDs.contains($0.id)
                    && !hasCompleteOnlineMetadata($0)
            }
            measuredAppCount += remaining.count
            await runSlowOnlineEnrichment(
                remaining,
                concurrency: concurrency,
                completedOffset: candidates.count,
                total: candidates.count + remaining.count
            )
        }

        for index in apps.indices where needsReview(apps[index]) {
            apps[index].reviewStatus = .needsReview
        }
        persist()
        summarizeWebsiteReview(foundCount: apps.count)
    }

    private func needsOnlineMetadata(_ app: AppEntry) -> Bool {
        !app.hasIcon
            || app.homepage == nil
            || app.downloadURL == nil
            || (app.githubURL != nil && !app.customizations.links)
            || AppMetadataEnricher.needsDescriptionExpansion(app.details)
    }

    private func runFastOnlineEnrichment(
        _ candidates: [AppEntry],
        concurrency: Int,
        total: Int,
        recordMisses: Bool
    ) async {
        var completed = 0
        var nextIndex = 0
        await withTaskGroup(of: FastOnlineResult.self) { group in
            for _ in 0..<max(1, concurrency) where nextIndex < candidates.count {
                let app = candidates[nextIndex]
                nextIndex += 1
                await MainActor.run {
                    markOnlineLookupStatus(.running, for: app.id)
                }
                group.addTask {
                    await OnlineEnrichmentLookup.fastResult(for: app)
                }
            }
            while let result = await group.next() {
                await waitIfEnrichmentPaused()
                if Task.isCancelled {
                    group.cancelAll()
                    break
                }
                let changed = applyFastResult(result)
                completed += 1
                updateOnlineLookupStatus(
                    for: result.appID,
                    changed: changed,
                    recordMiss: recordMisses
                )
                enrichmentProgress = "Schnelle Suche \(completed) / \(total)"
                persist()
                if nextIndex < candidates.count {
                    let app = candidates[nextIndex]
                    nextIndex += 1
                    await MainActor.run {
                        markOnlineLookupStatus(.running, for: app.id)
                    }
                    group.addTask {
                        await OnlineEnrichmentLookup.fastResult(for: app)
                    }
                }
            }
        }
    }

    private func runSlowOnlineEnrichment(
        _ candidates: [AppEntry],
        concurrency: Int,
        completedOffset: Int,
        total: Int
    ) async {
        var completed = completedOffset
        var nextIndex = 0
        await withTaskGroup(of: SlowOnlineResult.self) { group in
            for _ in 0..<max(1, concurrency) where nextIndex < candidates.count {
                let app = candidates[nextIndex]
                nextIndex += 1
                await MainActor.run {
                    markOnlineLookupStatus(.running, for: app.id)
                }
                group.addTask {
                    await OnlineEnrichmentLookup.slowResult(for: app)
                }
            }
            while let result = await group.next() {
                await waitIfEnrichmentPaused()
                if Task.isCancelled {
                    group.cancelAll()
                    break
                }
                let changed = applySlowResult(result)
                completed += 1
                updateOnlineLookupStatus(
                    for: result.appID,
                    changed: changed,
                    recordMiss: true
                )
                enrichmentProgress = "Erweiterte Suche \(completed) / \(total)"
                persist()
                if nextIndex < candidates.count {
                    let app = candidates[nextIndex]
                    nextIndex += 1
                    await MainActor.run {
                        markOnlineLookupStatus(.running, for: app.id)
                    }
                    group.addTask {
                        await OnlineEnrichmentLookup.slowResult(for: app)
                    }
                }
            }
        }
    }

    private func waitIfEnrichmentPaused() async {
        while isEnrichmentPaused && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }

    private func markOnlineLookupStatus(
        _ status: OnlineLookupStatus,
        for appID: AppEntry.ID
    ) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else {
            return
        }
        apps[index].onlineLookupStatus = status
    }

    private func updateOnlineLookupStatus(
        for appID: AppEntry.ID,
        changed: Bool,
        recordMiss: Bool
    ) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else {
            return
        }
        if changed {
            apps[index].onlineLookupStatus = hasCompleteOnlineMetadata(apps[index])
                ? .found
                : .needsReview
            OnlineEnrichmentAttemptCache.shared.clear(apps[index])
        } else {
            apps[index].onlineLookupStatus = .failed
            if recordMiss {
                OnlineEnrichmentAttemptCache.shared.recordMiss(apps[index])
            }
        }
    }

    private func prepareForOnlineRefresh(_ appID: AppEntry.ID) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else {
            return
        }
        pruneInvalidSuggestions(at: index)
        repairIncorrectAutomaticIconProtection(at: index)
        if let iconData = iconData(for: apps[index]),
           !IconQualityInspector.isLikelyAppIcon(iconData)
        {
            IconStore.shared.delete(fileName: apps[index].iconFileName)
            apps[index].iconFileName = nil
            apps[index].iconData = nil
        }
        if let homepage = apps[index].homepage,
           !OfficialWebsiteLookup.isOfficialCandidate(homepage)
        {
            apps[index].homepage = nil
        }
        removeDuplicateAutomaticOnlineIcons()
    }

    private func hasCompleteOnlineMetadata(_ app: AppEntry) -> Bool {
        app.hasIcon
            && app.homepage != nil
            && app.downloadURL != nil
            && !AppMetadataEnricher.needsDescriptionExpansion(app.details)
    }

    private func applyLocalFastScanMetadata() {
        for index in apps.indices {
            applyLocalFastScanMetadata(at: index)
        }
    }

    private func applyLocalFastScanMetadata(to appID: AppEntry.ID) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else {
            return
        }
        applyLocalFastScanMetadata(at: index)
    }

    private func applyLocalFastScanMetadata(at index: Int) {
        if shouldReplaceIcon(in: apps[index]),
           let iconData = InstalledAppIconCatalog.shared.compactIconData(
            for: apps[index].name
           )
        {
            apps[index].iconData = iconData
            apps[index].iconOrigin = .localBundle
            apps[index] = migrateIcon(in: apps[index])
            addSource("Lokal installierte App", to: index)
        }

        guard !apps[index].customizations.links else {
            return
        }
        applyConfirmedURLs(to: index)
        applyKnownLocalMetadata(to: index)
        applyHomebrewCaskMetadata(to: index)
    }

    private func applyConfirmedURLs(to index: Int) {
        for url in ConfirmedMetadataMatchStore.shared.confirmedURLs(
            for: apps[index].name
        ) {
            guard let host = url.host?.lowercased() else {
                continue
            }
            if host == "github.com" || host.hasSuffix(".github.com") {
                if apps[index].githubURL == nil {
                    apps[index].githubURL = url
                    addSource("Bestätigte lokale Zuordnung", to: index)
                }
            } else if host == "apps.apple.com" || host.hasSuffix(".apps.apple.com") {
                if apps[index].downloadURL == nil {
                    apps[index].downloadURL = url
                    addSource("Bestätigte lokale Zuordnung", to: index)
                }
            } else if apps[index].homepage == nil {
                apps[index].homepage = url
                addSource("Bestätigte lokale Zuordnung", to: index)
            }
        }
    }

    private func applyKnownLocalMetadata(to index: Int) {
        guard let metadata = LocalKnownMetadataLookup.metadata(for: apps[index])
        else {
            return
        }
        if apps[index].homepage == nil, let homepage = metadata.homepage {
            apps[index].homepage = homepage
            addSource("Lokaler Hersteller-Hinweis", to: index)
        }
        if apps[index].downloadURL == nil, let downloadURL = metadata.downloadURL {
            apps[index].downloadURL = downloadURL
            addSource("Lokaler Hersteller-Hinweis", to: index)
        }
        if apps[index].githubURL == nil, let githubURL = metadata.githubURL {
            apps[index].githubURL = githubURL
            addSource("Lokaler Hersteller-Hinweis", to: index)
        }
    }

    private func applyHomebrewCaskMetadata(to index: Int) {
        guard let metadata = homebrewCaskMetadataCache.metadata(
            for: apps[index]
        ) else {
            return
        }
        if apps[index].homepage == nil, let homepage = metadata.homepage {
            apps[index].homepage = homepage
            addSource("Homebrew-Cask-Katalog", to: index)
        }
        if apps[index].downloadURL == nil, let downloadURL = metadata.downloadURL {
            apps[index].downloadURL = downloadURL
            addSource("Homebrew-Cask-Katalog", to: index)
        }
        if apps[index].githubURL == nil, let githubURL = metadata.githubURL {
            apps[index].githubURL = githubURL
            addSource("Homebrew-Cask-Katalog", to: index)
        }
        if let description = metadata.description,
           !description.isEmpty,
           AppMetadataEnricher.needsDescriptionExpansion(apps[index].details),
           !apps[index].customizations.description
        {
            apps[index].summary = AppMetadataEnricher.summary(
                from: description
            )
            apps[index].details = AppMetadataEnricher.expandedDescription(
                sourceText: description,
                category: apps[index].category,
                subcategory: apps[index].subcategory,
                keywords: apps[index].keywords
            )
            addSource("Homebrew-Cask-Katalog", to: index)
        }
    }

    @discardableResult
    private func applyFastResult(_ result: FastOnlineResult) -> Bool {
        let before = apps.first(where: { $0.id == result.appID })
        if let metadata = result.apple {
            applyOnlineMetadata(
                metadata,
                iconData: result.appleIconData,
                to: result.appID
            )
        }
        guard let index = apps.firstIndex(where: { $0.id == result.appID }),
              let metadata = result.website
        else {
            return hasAppChanged(result.appID, comparedTo: before)
        }
        if let iconData = metadata.iconData {
            if applyIconData(iconData, to: result.appID) {
                addSource("Herstellerseite", to: index)
            }
        }
        if let description = metadata.description,
           !description.isEmpty,
           AppMetadataEnricher.needsDescriptionExpansion(apps[index].details),
           !apps[index].customizations.description
        {
            recordDescription(
                description,
                source: "Herstellerseite",
                sourceURL: apps[index].homepage,
                for: result.appID
            )
        }
        return hasAppChanged(result.appID, comparedTo: before)
    }

    @discardableResult
    private func applySlowResult(_ result: SlowOnlineResult) -> Bool {
        let before = apps.first(where: { $0.id == result.appID })
        guard let index = apps.firstIndex(where: { $0.id == result.appID }) else {
            return false
        }
        var confirmedHomepageURL: URL?
        if let homepage = result.homepage, apps[index].homepage == nil {
            if homepage.match.decision == .automatic {
                apps[index].homepage = homepage.url
                confirmedHomepageURL = homepage.url
                addSource("Bestätigte Websuche", to: index)
            } else {
                addSuggestion(
                    CatalogSuggestion(
                        kind: .homepage,
                        value: homepage.url.absoluteString,
                        sourceLabel: matchLabel(
                            "DuckDuckGo · mögliche Herstellerseite",
                            match: homepage.match
                        ),
                        sourceURL: homepage.url
                    ),
                    to: index
                )
            }
        }
        if let metadata = result.website {
            if let iconData = metadata.iconData {
                if applyIconData(iconData, to: result.appID) {
                    addSource("Herstellerseite", to: index)
                }
            }
            if let description = metadata.description,
               !description.isEmpty,
               AppMetadataEnricher.needsDescriptionExpansion(apps[index].details),
               !apps[index].customizations.description
            {
                recordDescription(
                    description,
                    source: "Herstellerseite",
                    sourceURL: confirmedHomepageURL ?? apps[index].homepage,
                    for: result.appID
                )
            }
        }
        if let metadata = result.github {
            if metadata.match.decision == .automatic,
               !apps[index].customizations.links
            {
                apps[index].githubURL = metadata.projectURL
                apps[index].homepage = metadata.homepageURL ?? apps[index].homepage
                apps[index].downloadURL = metadata.downloadURL
            }
            if let iconData = metadata.iconData,
               metadata.match.decision == .automatic,
               shouldReplaceIcon(in: apps[index]),
               isAcceptableAutomaticOnlineIcon(iconData, for: apps[index])
            {
                apps[index].iconData = iconData
                apps[index].iconOrigin = .github
                apps[index] = migrateIcon(in: apps[index])
            }
            if let description = metadata.description,
               metadata.match.decision == .automatic
            {
                recordDescription(
                    description,
                    source: "GitHub-Repository",
                    sourceURL: metadata.projectURL,
                    for: result.appID
                )
            }
            if metadata.match.decision == .automatic {
                addSource("GitHub-Repository", to: index)
            } else {
                addSuggestion(
                    CatalogSuggestion(
                        kind: .github,
                        value: metadata.projectURL.absoluteString,
                        sourceLabel: matchLabel(
                            "GitHub",
                            match: metadata.match
                        ),
                        sourceURL: metadata.projectURL
                    ),
                    to: index
                )
                if let homepageURL = metadata.homepageURL {
                    addSuggestion(
                        CatalogSuggestion(
                            kind: .homepage,
                            value: homepageURL.absoluteString,
                            sourceLabel: matchLabel(
                                "GitHub · mögliche Herstellerseite",
                                match: metadata.match
                            ),
                            sourceURL: metadata.projectURL
                        ),
                        to: index
                    )
                }
                if let description = metadata.description {
                    addDescriptionSuggestion(
                        description,
                        source: matchLabel(
                            "GitHub",
                            match: metadata.match
                        ),
                        sourceURL: metadata.projectURL,
                        to: index
                    )
                }
            }
        }
        if let reddit = result.reddit,
           AppMetadataEnricher.needsDescriptionExpansion(apps[index].details),
           !apps[index].customizations.description
        {
            addDescriptionSuggestion(
                reddit.description,
                source: "Reddit r/macapps (subjektiv)",
                sourceURL: reddit.sourceURL,
                to: index
            )
        }
        return hasAppChanged(result.appID, comparedTo: before)
    }

    private func hasAppChanged(
        _ appID: AppEntry.ID,
        comparedTo before: AppEntry?
    ) -> Bool {
        guard let before,
              let after = apps.first(where: { $0.id == appID })
        else {
            return false
        }
        return before != after
    }

    private func githubMetadata(
        for app: AppEntry
    ) async -> GitHubRepositoryLookup.Metadata? {
        if let sourceURL = app.githubURL ?? app.homepage,
           let metadata = await GitHubRepositoryLookup.shared.metadata(
                for: sourceURL,
                category: app.category,
                subcategory: app.subcategory,
                needsIcon: shouldReplaceIcon(in: app)
           )
        {
            return metadata
        }
        return await GitHubRepositoryLookup.shared.metadata(
            for: app,
            needsIcon: shouldReplaceIcon(in: app)
        )
    }

    @discardableResult
    func applyIconData(_ iconData: Data, to appID: AppEntry.ID) -> Bool {
        guard iconData.count <= IconImageConverter.maximumStoredBytes,
              let index = apps.firstIndex(where: { $0.id == appID }),
              shouldReplaceIcon(in: apps[index]),
              isAcceptableAutomaticOnlineIcon(iconData, for: apps[index])
        else {
            return false
        }
        apps[index].iconData = iconData
        apps[index].iconOrigin = .website
        apps[index] = migrateIcon(in: apps[index])
        persist()
        return true
    }

    func acceptSuggestion(_ suggestionID: CatalogSuggestion.ID, for appID: AppEntry.ID) {
        guard let index = apps.firstIndex(where: { $0.id == appID }),
              var suggestion = apps[index].suggestions.first(
                where: { $0.id == suggestionID }
              )
        else {
            return
        }
        if suggestion.kind == .description && suggestion.needsTranslation {
            suggestion.value =
                DescriptionLanguageProcessor.originalWithLanguageNote(
                    suggestion.value,
                    language: suggestion.detectedLanguage
                )
            suggestion.needsTranslation = false
            if pendingTranslation?.suggestionID == suggestionID {
                pendingTranslation = nil
            }
        }
        switch suggestion.kind {
        case .description:
            apps[index].details = AppMetadataEnricher.expandedDescription(
                sourceText: suggestion.value,
                category: apps[index].category,
                subcategory: apps[index].subcategory,
                keywords: apps[index].keywords
            )
            apps[index].summary = AppMetadataEnricher.summary(
                from: suggestion.value
            )
        case .homepage:
            apps[index].homepage = URL(string: suggestion.value)
        case .download:
            apps[index].downloadURL = URL(string: suggestion.value)
        case .github:
            apps[index].githubURL = URL(string: suggestion.value)
        case .icon:
            break
        }
        rememberConfirmedMatch(
            suggestion: suggestion,
            appName: apps[index].name
        )
        addSource(suggestion.sourceLabel, to: index)
        if suggestion.kind == .description {
            apps[index].reviewSuggestions = apps[index].suggestions.filter {
                $0.kind != .description
            }
        } else {
            removeSuggestion(suggestionID, from: index)
        }
        if !needsReview(apps[index]) {
            apps[index].reviewStatus = .confirmed
        }
        persist()
        queueNextTranslation()
        if suggestion.kind == .homepage {
            Task {
                await enrichFromConfirmedWebsite(for: appID)
            }
        }
    }

    func dismissSuggestion(_ suggestionID: CatalogSuggestion.ID, for appID: AppEntry.ID) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else {
            return
        }
        if let suggestion = apps[index].suggestions.first(
            where: { $0.id == suggestionID }
        ) {
            rememberRejectedMatch(
                suggestion: suggestion,
                appName: apps[index].name
            )
        }
        removeSuggestion(suggestionID, from: index)
        persist()
    }

    func resolveReview(for appID: AppEntry.ID) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else {
            return
        }
        apps[index].reviewSuggestions = []
        apps[index].reviewStatus = .confirmed
        persist()
    }

    func confirmWebsite(_ rawValue: String, for appID: AppEntry.ID) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else {
            return
        }
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: value)?.scheme == nil
            ? URL(string: "https://\(value)")
            : URL(string: value)
        guard let url else {
            return
        }
        apps[index].homepage = url
        ConfirmedMetadataMatchStore.shared.confirm(
            appName: apps[index].name,
            url: url
        )
        apps[index].websitePromptSuppressed = false
        var customizations = apps[index].customizations
        customizations.links = true
        apps[index].userCustomizations = customizations
        promptedWebsiteAppIDs.insert(appID)
        pendingWebsitePrompt = nil
        persist()
        Task {
            await enrichFromConfirmedWebsite(for: appID)
        }
        updateWebsiteReviewSummaryAfterChange()
    }

    private func enrichFromConfirmedWebsite(for appID: AppEntry.ID) async {
        guard let app = apps.first(where: { $0.id == appID }),
              let homepage = app.homepage,
              let metadata = await WebMetadataLookup.shared.metadata(
                for: homepage,
                needsIcon: !app.customizations.icon
                    && app.iconOrigin != .manual
                    && app.iconOrigin != .localBundle
              ),
              let index = apps.firstIndex(where: { $0.id == appID })
        else {
            return
        }

        if let iconData = metadata.iconData,
           !apps[index].customizations.icon,
           apps[index].iconOrigin != .manual,
           apps[index].iconOrigin != .localBundle,
           isAcceptableAutomaticOnlineIcon(iconData, for: apps[index])
        {
            IconStore.shared.delete(fileName: apps[index].iconFileName)
            apps[index].iconFileName = nil
            apps[index].iconData = iconData
            apps[index].iconOrigin = .website
            apps[index] = migrateIcon(in: apps[index])
            addSource("Bestätigte Herstellerseite", to: index)
        }
        if let description = metadata.description,
           !description.isEmpty,
           AppMetadataEnricher.needsDescriptionExpansion(apps[index].details),
           !apps[index].customizations.description
        {
            recordDescription(
                description,
                source: "Bestätigte Herstellerseite",
                sourceURL: homepage,
                for: appID
            )
        }
        persist()
    }

    func dismissWebsitePrompt(for appID: AppEntry.ID) {
        promptedWebsiteAppIDs.insert(appID)
        pendingWebsitePrompt = nil
    }

    func suppressWebsitePrompt(for appID: AppEntry.ID) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else {
            return
        }
        apps[index].websitePromptSuppressed = true
        promptedWebsiteAppIDs.insert(appID)
        pendingWebsitePrompt = nil
        persist()
        updateWebsiteReviewSummaryAfterChange()
    }

    func allowWebsitePrompt(for appID: AppEntry.ID) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else {
            return
        }
        apps[index].websitePromptSuppressed = false
        promptedWebsiteAppIDs.remove(appID)
        persist()
        updateWebsiteReviewSummaryAfterChange()
    }

    func completeTranslation(
        _ translation: String?,
        for pending: PendingTranslation
    ) {
        guard let index = apps.firstIndex(where: { $0.id == pending.appID }),
              let suggestionIndex = apps[index].suggestions.firstIndex(
                where: { $0.id == pending.suggestionID }
              )
        else {
            pendingTranslation = nil
            queueNextTranslation()
            return
        }
        var suggestions = apps[index].suggestions
        if let translation, !translation.isEmpty {
            suggestions[suggestionIndex].value = translation
            suggestions[suggestionIndex].needsTranslation = false
            apps[index].reviewSuggestions = suggestions
            if !apps[index].customizations.description {
                acceptSuggestion(suggestions[suggestionIndex].id, for: pending.appID)
            }
        } else {
            suggestions[suggestionIndex].value =
                DescriptionLanguageProcessor.originalWithLanguageNote(
                    suggestions[suggestionIndex].value,
                    language: suggestions[suggestionIndex].detectedLanguage
                )
            suggestions[suggestionIndex].needsTranslation = false
            apps[index].reviewSuggestions = suggestions
            apps[index].reviewStatus = .needsReview
            persist()
        }
        pendingTranslation = nil
        queueNextTranslation()
    }

    func delete(_ app: AppEntry) {
        apps.removeAll { $0.id == app.id }
        IconStore.shared.delete(fileName: app.iconFileName)
        licenseStorage.delete(for: app.id)
        if selectedAppID == app.id {
            selectedAppID = nil
        }
        persist()
    }

    func deleteAll() {
        for app in apps {
            IconStore.shared.delete(fileName: app.iconFileName)
            licenseStorage.delete(for: app.id)
        }
        apps.removeAll()
        selectedAppID = nil
        selectedCategory = nil
        pendingTranslation = nil
        pendingWebsitePrompt = nil
        promptedWebsiteAppIDs.removeAll()
        persist()
    }

    func mergeScannedApps(_ scannedApps: [AppEntry]) {
        websiteReviewSummary = nil
        let includedScannedApps = scannedApps.filter {
            !hasLocalFileInExcludedScanArea($0)
        }
        let existingApps = apps.filter {
            !hasLocalFileInExcludedScanArea($0)
        }
        let result = CatalogScanReconciler().reconcile(
            existingApps: existingApps,
            scannedApps: includedScannedApps
        )
        let excludedRemovedApps = apps.filter {
            hasLocalFileInExcludedScanArea($0)
        }
        for removedApp in excludedRemovedApps {
            IconStore.shared.delete(fileName: removedApp.iconFileName)
            licenseStorage.delete(for: removedApp.id)
        }
        for removedApp in result.removedApps {
            IconStore.shared.delete(fileName: removedApp.iconFileName)
            licenseStorage.delete(for: removedApp.id)
        }
        apps = result.apps.filter {
            !hasLocalFileInExcludedScanArea($0)
        }
        _ = removeExcludedScanAreaApps()
        apps = migrateIcons(in: apps)
        applyLocalFastScanMetadata()
        apps.sort(by: Self.sortApps)
        persist()
    }

    func replaceCatalog(
        with importedApps: [AppEntry],
        licenses: [UUID: AppLicenseRecord] = [:]
    ) throws {
        let includedApps = importedApps
            .filter(CatalogEntryFilter().shouldInclude)
            .filter {
                !hasLocalFileInExcludedScanArea($0)
            }
            .sorted(by: Self.sortApps)
        let includedIDs = Set(includedApps.map(\.id))
        try licenseStorage.save(
            licenses.filter { includedIDs.contains($0.key) }
        )
        apps = migrateIcons(in: includedApps)
        selectedAppID = nil
        selectedCategory = nil
        persist()
    }

    func clearPersistenceError() {
        persistenceError = nil
    }

    func exportApps() -> [AppEntry] {
        apps.map { app in
            var exported = app
            exported.iconData = iconData(for: app)
            exported.iconFileName = nil
            return exported
        }
    }

    private func persist() {
        do {
            apps = migrateIcons(in: apps)
            try persistence.save(apps)
            persistenceError = nil
            catalogRevision &+= 1
        } catch {
            persistenceError = "Der Katalog konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    private func needsReview(_ app: AppEntry) -> Bool {
        !app.suggestions.isEmpty
            || !app.hasIcon
            || app.homepage == nil
            || AppMetadataEnricher.needsDescriptionExpansion(app.details)
    }

    private func needsWebsiteReview(_ app: AppEntry) -> Bool {
        if app.suggestions.contains(where: { $0.kind == .homepage }) {
            return false
        }
        if isLowValueInstallerMetadataPrompt(app) {
            return false
        }
        switch app.onlineLookupStatus {
        case .failed, .needsReview:
            return true
        case .open, .running, .found, nil:
            return false
        }
    }

    private func isLowValueInstallerMetadataPrompt(_ app: AppEntry) -> Bool {
        guard !app.files.isEmpty,
              app.files.allSatisfy({ $0.fileType != "app" })
        else {
            return false
        }
        let normalized = ([app.name, app.subcategory] + app.files.map(\.fileName))
            .joined(separator: " ")
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .lowercased()
        return [
            "activation",
            "runtime",
            "icon pack",
            "plugin",
            "cleaner tool",
            "helper",
            "uninstaller"
        ].contains { normalized.contains($0) }
    }

    private func shouldReplaceIcon(in app: AppEntry) -> Bool {
        guard !app.customizations.icon, app.iconOrigin != .manual else {
            return false
        }
        return !app.hasIcon || app.iconOrigin == .iTunes
    }

    private func isAcceptableAutomaticOnlineIcon(
        _ candidateIconData: Data,
        for app: AppEntry
    ) -> Bool {
        guard IconQualityInspector.isLikelyOnlineAppIcon(candidateIconData) else {
            return false
        }
        let fingerprint = iconFingerprint(for: candidateIconData)
        let normalizedName = normalizedIconOwnerName(app.name)
        return !apps.contains { other in
            guard other.id != app.id,
                  isAutomaticOnlineIcon(other),
                  normalizedIconOwnerName(other.name) != normalizedName,
                  let otherIconData = iconData(for: other)
            else {
                return false
            }
            return iconFingerprint(for: otherIconData) == fingerprint
        }
    }

    private func removeDuplicateAutomaticOnlineIcons() {
        let grouped = Dictionary(grouping: apps.indices) { index in
            iconData(for: apps[index]).map(iconFingerprint)
        }
        for (fingerprint, indices) in grouped {
            guard fingerprint != nil else {
                continue
            }
            let onlineIndices = indices.filter {
                isAutomaticOnlineIcon(apps[$0])
            }
            let distinctNames = Set(
                onlineIndices.map {
                    normalizedIconOwnerName(apps[$0].name)
                }
            )
            guard onlineIndices.count > 1, distinctNames.count > 1 else {
                continue
            }
            for index in onlineIndices {
                IconStore.shared.delete(fileName: apps[index].iconFileName)
                apps[index].iconFileName = nil
                apps[index].iconData = nil
                apps[index].iconOrigin = nil
            }
        }
    }

    private func isAutomaticOnlineIcon(_ app: AppEntry) -> Bool {
        app.iconOrigin == .website
            || app.iconOrigin == .github
            || app.iconOrigin == .iTunes
    }

    private func iconFingerprint(for data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func normalizedIconOwnerName(_ name: String) -> String {
        name
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private func pruneInvalidSuggestions(at index: Int) {
        let appName = apps[index].name
        let suggestions = apps[index].suggestions.filter { suggestion in
            guard suggestion.kind == .homepage
                    || suggestion.kind == .download
                    || suggestion.kind == .github
                    || suggestion.kind == .icon
            else {
                return true
            }
            let valueURL = URL(string: suggestion.value)
            return !MetadataMatchScorer.hasConflictingProductQualifier(
                appName: appName,
                candidateURL: valueURL ?? suggestion.sourceURL
            )
        }
        if suggestions.count != apps[index].suggestions.count {
            apps[index].reviewSuggestions = suggestions
        }
    }

    private func hasLocalFileInExcludedScanArea(_ app: AppEntry) -> Bool {
        let policy = ScanExclusionPolicy(
            customExcludedDirectories: ScannerSettings.excludedPathHints
        )
        let appPath = [
            app.category,
            app.subcategory,
            app.files.first?.fileName ?? app.name
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "/")
        let appPathComponents = appPath
            .split(separator: "/")
            .map(String.init)
        if policy.shouldExclude(
            url: URL(fileURLWithPath: appPath),
            relativePathComponents: appPathComponents
        ) {
            return true
        }

        return app.files.contains { file in
            let relativePathComponents = file.relativePath
                .split(separator: "/")
                .map(String.init)
            if policy.shouldExclude(
                url: URL(fileURLWithPath: file.relativePath),
                relativePathComponents: relativePathComponents
            ) {
                return true
            }

            let sourcePath = [
                file.sourceCategory,
                file.sourceSubcategory,
                file.fileName
            ]
            .filter { !$0.isEmpty }
            .joined(separator: "/")
            let sourcePathComponents = sourcePath
                .split(separator: "/")
                .map(String.init)
            return policy.shouldExclude(
                url: URL(fileURLWithPath: sourcePath),
                relativePathComponents: sourcePathComponents
            )
        }
    }

    @discardableResult
    private func removeExcludedScanAreaApps() -> Bool {
        let removedApps = apps.filter {
            hasLocalFileInExcludedScanArea($0)
        }
        guard !removedApps.isEmpty else {
            return false
        }

        let removedIDs = Set(removedApps.map(\.id))
        for removedApp in removedApps {
            IconStore.shared.delete(fileName: removedApp.iconFileName)
            licenseStorage.delete(for: removedApp.id)
        }
        apps.removeAll {
            removedIDs.contains($0.id)
        }
        if let selectedAppID,
           removedIDs.contains(selectedAppID) {
            self.selectedAppID = nil
        }
        return true
    }

    private func clearAutomaticGitHubMetadata(at index: Int) {
        let sources = apps[index].metadataSources ?? []
        if sources == ["GitHub-Repository"] {
            apps[index].homepage = nil
            apps[index].downloadURL = nil
        }
        apps[index].githubURL = nil
        if apps[index].metadataSources?.contains("GitHub-Repository") == true {
            apps[index].metadataSources?.removeAll {
                $0 == "GitHub-Repository"
            }
        }
        if apps[index].iconOrigin == .github {
            IconStore.shared.delete(fileName: apps[index].iconFileName)
            apps[index].iconFileName = nil
            apps[index].iconData = nil
            apps[index].iconOrigin = nil
        }
    }

    private func repairIncorrectAutomaticIconProtection(at index: Int) {
        guard apps[index].customizations.icon,
              apps[index].iconOrigin == nil,
              let sources = apps[index].metadataSources,
              sources.contains("iTunes"),
              apps[index].githubURL != nil
        else {
            return
        }
        var customizations = apps[index].customizations
        customizations.icon = false
        apps[index].userCustomizations = customizations
        apps[index].iconOrigin = .iTunes
    }

    private func addSuggestion(_ suggestion: CatalogSuggestion, to index: Int) {
        guard !isRejectedSuggestion(suggestion, appName: apps[index].name)
        else {
            return
        }
        var suggestions = apps[index].suggestions
        guard !suggestions.contains(where: {
            $0.kind == suggestion.kind
                && $0.value.caseInsensitiveCompare(suggestion.value)
                    == .orderedSame
        }) else {
            return
        }
        suggestions.append(suggestion)
        apps[index].reviewSuggestions = suggestions
        apps[index].reviewStatus = .needsReview
    }

    private func addDescriptionSuggestion(
        _ description: String,
        source: String,
        sourceURL: URL?,
        sourceIdentifier: String? = nil,
        to index: Int
    ) {
        let language = DescriptionLanguageProcessor.detectedLanguage(
            for: description
        )
        let targetLanguage = targetLanguageProvider()
        addSuggestion(
            CatalogSuggestion(
                kind: .description,
                value: description,
                sourceLabel: source,
                sourceURL: sourceURL,
                sourceIdentifier: sourceIdentifier,
                detectedLanguage: language,
                needsTranslation:
                    !DescriptionLanguageProcessor.matches(
                        language,
                        targetLanguage: targetLanguage
                    )
            ),
            to: index
        )
        queueNextTranslation()
    }

    private func isRejectedSuggestion(
        _ suggestion: CatalogSuggestion,
        appName: String
    ) -> Bool {
        if let sourceURL = suggestion.sourceURL,
           ConfirmedMetadataMatchStore.shared.isRejected(
            appName: appName,
            url: sourceURL
           )
        {
            return true
        }
        guard let identifier = suggestion.sourceIdentifier,
              identifier.hasPrefix("apple:"),
              let trackID = Int(identifier.dropFirst("apple:".count))
        else {
            return false
        }
        return ConfirmedMetadataMatchStore.shared.isRejected(
            appName: appName,
            appleTrackID: trackID
        )
    }

    private func rememberConfirmedMatch(
        suggestion: CatalogSuggestion,
        appName: String
    ) {
        if let sourceURL = suggestion.sourceURL {
            ConfirmedMetadataMatchStore.shared.confirm(
                appName: appName,
                url: sourceURL
            )
        }
        guard let identifier = suggestion.sourceIdentifier,
              identifier.hasPrefix("apple:"),
              let trackID = Int(identifier.dropFirst("apple:".count))
        else {
            return
        }
        ConfirmedMetadataMatchStore.shared.confirm(
            appName: appName,
            appleTrackID: trackID
        )
    }

    private func rememberRejectedMatch(
        suggestion: CatalogSuggestion,
        appName: String
    ) {
        if let sourceURL = suggestion.sourceURL {
            ConfirmedMetadataMatchStore.shared.reject(
                appName: appName,
                url: sourceURL
            )
        }
        guard let identifier = suggestion.sourceIdentifier,
              identifier.hasPrefix("apple:"),
              let trackID = Int(identifier.dropFirst("apple:".count))
        else {
            return
        }
        ConfirmedMetadataMatchStore.shared.reject(
            appName: appName,
            appleTrackID: trackID
        )
    }

    private func matchLabel(
        _ source: String,
        match: MetadataMatchScore
    ) -> String {
        let percent = Int((match.value * 100).rounded())
        return "\(source) · \(percent) % Übereinstimmung"
    }

    private func recordDescription(
        _ description: String,
        source: String,
        sourceURL: URL? = nil,
        for appID: AppEntry.ID
    ) {
        guard let index = apps.firstIndex(where: { $0.id == appID }),
              !apps[index].customizations.description
        else {
            return
        }
        let language = DescriptionLanguageProcessor.detectedLanguage(
            for: description
        )
        let targetLanguage = targetLanguageProvider()
        if DescriptionLanguageProcessor.matches(
            language,
            targetLanguage: targetLanguage
        ) {
            apps[index].details = AppMetadataEnricher.expandedDescription(
                sourceText: description,
                category: apps[index].category,
                subcategory: apps[index].subcategory,
                keywords: apps[index].keywords
            )
            if AppMetadataEnricher.isPlaceholderSummary(apps[index].summary) {
                apps[index].summary = AppMetadataEnricher.summary(
                    from: description
                )
            }
            addSource(source, to: index)
        } else {
            addSuggestion(
                CatalogSuggestion(
                    kind: .description,
                    value: description,
                    sourceLabel: source,
                    sourceURL: sourceURL,
                    detectedLanguage: language,
                    needsTranslation: false
                ),
                to: index
            )
        }
    }

    private func removeSuggestion(
        _ suggestionID: CatalogSuggestion.ID,
        from index: Int
    ) {
        apps[index].reviewSuggestions = apps[index].suggestions.filter {
            $0.id != suggestionID
        }
        if !needsReview(apps[index]) {
            apps[index].reviewStatus = .confirmed
        }
    }

    private func addSource(_ source: String, to index: Int) {
        var sources = apps[index].metadataSources ?? []
        if !sources.contains(source) {
            sources.append(source)
        }
        apps[index].metadataSources = sources
    }

    private func queueNextTranslation() {
        guard pendingTranslation == nil else {
            return
        }
        let targetLanguage = targetLanguageProvider()
        for app in apps {
            if let suggestion = app.suggestions.first(where: {
                $0.needsTranslation
                    && !DescriptionLanguageProcessor.matches(
                        $0.detectedLanguage,
                        targetLanguage: targetLanguage
                    )
            }),
               let language = suggestion.detectedLanguage
            {
                pendingTranslation = PendingTranslation(
                    id: suggestion.id,
                    appID: app.id,
                    suggestionID: suggestion.id,
                    text: suggestion.value,
                    sourceLanguage: language,
                    targetLanguage: targetLanguage
                )
                if #unavailable(macOS 15.0) {
                    let pending = pendingTranslation
                    Task { @MainActor in
                        await Task.yield()
                        if let pending {
                            completeTranslation(nil, for: pending)
                        }
                    }
                }
                return
            }
        }
    }

    private func offerWebsitePromptIfNeeded() {
        summarizeWebsiteReview(foundCount: apps.count)
    }

    private func summarizeWebsiteReview(foundCount: Int) {
        let unresolvedCount = appsNeedingWebsiteReview.count
        guard unresolvedCount > 0 else {
            websiteReviewSummary = nil
            return
        }
        websiteReviewSummary = WebsiteReviewSummary(
            foundCount: foundCount,
            unresolvedCount: unresolvedCount
        )
    }

    private func updateWebsiteReviewSummaryAfterChange() {
        guard let summary = websiteReviewSummary else {
            return
        }
        summarizeWebsiteReview(foundCount: summary.foundCount)
    }

    private func migrateIcons(in entries: [AppEntry]) -> [AppEntry] {
        entries.map(migrateIcon)
    }

    private func migrateIcon(in app: AppEntry) -> AppEntry {
        var updated = app
        if let iconData = updated.iconData {
            if let fileName = try? IconStore.shared.save(
                iconData,
                for: updated.id
            ) {
                updated.iconFileName = fileName
            }
            updated.iconData = nil
        }
        updated.files = updated.files.map { $0.removingIconData() }
        return updated
    }

    private func iconData(for app: AppEntry) -> Data? {
        if let iconData = app.iconData {
            return iconData
        }
        guard let fileName = app.iconFileName else {
            return nil
        }
        return IconStore.shared.data(fileName: fileName, thumbnail: false)
    }

    private static func sortApps(_ lhs: AppEntry, _ rhs: AppEntry) -> Bool {
        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
}
