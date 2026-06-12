import Foundation

@MainActor
final class CatalogStore: ObservableObject {
    @Published private(set) var apps: [AppEntry] = []
    @Published private(set) var importError: String?
    @Published private(set) var persistenceError: String?
    @Published private(set) var isEnriching = false
    @Published private(set) var enrichmentProgress = ""
    @Published private(set) var pendingTranslation: PendingTranslation?
    @Published private(set) var catalogRevision = 0
    @Published var pendingWebsitePrompt: PendingWebsitePrompt?
    @Published var searchText = ""
    @Published var selectedCategory: String?
    @Published var selectedAppID: AppEntry.ID?

    private let persistence: CatalogPersistence
    private let targetLanguageProvider: @Sendable () -> String
    private var promptedWebsiteAppIDs: Set<AppEntry.ID> = []
    static let needsReviewFilter = "__needs_review__"
    static let subcategoryFilterPrefix = "__subcategory__:"

    struct FolderNode: Identifiable, Hashable {
        let name: String
        let path: String
        let count: Int
        let children: [FolderNode]

        var id: String { path }
    }

    init(
        persistence: CatalogPersistence = CatalogPersistence(),
        targetLanguageProvider: @escaping @Sendable () -> String = {
            AppLanguageChoice.current.resolvedLanguage()
        }
    ) {
        self.persistence = persistence
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
        apps.filter(\.suppressesWebsitePrompt)
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
        return app.category == selectedCategory
    }

    private func folderPaths(for app: AppEntry) -> Set<String> {
        var paths = Set<String>()
        for file in app.files {
            let components = file.relativePath.split(separator: "/").map(String.init)
            guard components.first == app.category, components.count > 2 else {
                continue
            }
            let folders = Array(components.dropFirst().dropLast())
            for depth in 1...folders.count {
                paths.insert(folders.prefix(depth).joined(separator: "/"))
            }
        }
        if paths.isEmpty, !app.subcategory.isEmpty, app.subcategory != app.category {
            let folders = app.subcategory.split(separator: "/").map(String.init)
            for depth in 1...folders.count {
                paths.insert(folders.prefix(depth).joined(separator: "/"))
            }
        }
        return paths
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
                let enrichedApps = AppMetadataEnricher().enrich(
                    savedApps.filter(CatalogEntryFilter().shouldInclude)
                )
                apps = migrateIcons(in: enrichedApps)
                    .sorted(by: Self.sortApps)
                importError = nil
                refreshDescriptionTranslations()
                if apps != savedApps {
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
        let enrichedApp = migrateIcon(
            in: AppMetadataEnricher().enrich(app)
        )
        apps.append(enrichedApp)
        apps.sort(by: Self.sortApps)
        selectedAppID = enrichedApp.id
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
        if !apps[index].customizations.links {
            if let homepage = metadata.homepage {
                apps[index].homepage = homepage
            }
            if let downloadURL = metadata.downloadURL {
                apps[index].downloadURL = downloadURL
            }
        }
        if !apps[index].hasIcon,
           !apps[index].customizations.icon,
           let iconData
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
        guard !isEnriching else {
            return
        }
        isEnriching = true
        let measurement = ProcessUsageMeasurement()
        var measuredAppCount = 0
        let concurrency = OnlineUpdateSettings.currentConcurrency
        defer {
            measurement.result(
                concurrency: concurrency,
                appCount: measuredAppCount
            ).save()
            isEnriching = false
            enrichmentProgress = ""
        }

        for index in apps.indices {
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
        persist()

        let candidates = apps.filter {
            !$0.hasIcon
                || $0.homepage == nil
                || $0.downloadURL == nil
                || ($0.githubURL != nil && !$0.customizations.links)
                || AppMetadataEnricher.needsDescriptionExpansion($0.details)
        }
        measuredAppCount = candidates.count
        for start in stride(from: 0, to: candidates.count, by: concurrency) {
            let end = min(start + concurrency, candidates.count)
            let batch = Array(candidates[start..<end])
            enrichmentProgress =
                "Schnelle Online-Quellen \(start + 1)–\(end) von \(candidates.count)"
            let results = await OnlineEnrichmentLookup.fastResults(for: batch)
            for result in results {
                applyFastResult(result)
            }
            persist()
        }

        if OnlineUpdateSettings.extendedSearchEnabled {
            let candidateIDs = Set(candidates.map(\.id))
            let remaining = apps.filter {
                candidateIDs.contains($0.id) && !hasCompleteOnlineMetadata($0)
            }
            for start in stride(from: 0, to: remaining.count, by: concurrency) {
                let end = min(start + concurrency, remaining.count)
                let batch = Array(remaining[start..<end])
                enrichmentProgress =
                    "Erweiterte Online-Quellen \(start + 1)–\(end) von \(remaining.count)"
                let results = await OnlineEnrichmentLookup.slowResults(for: batch)
                for result in results {
                    applySlowResult(result)
                }
                persist()
            }
        }

        for index in apps.indices where needsReview(apps[index]) {
            apps[index].reviewStatus = .needsReview
        }
        persist()
        offerWebsitePromptIfNeeded()
    }

    private func hasCompleteOnlineMetadata(_ app: AppEntry) -> Bool {
        app.hasIcon
            && app.homepage != nil
            && app.downloadURL != nil
            && !AppMetadataEnricher.needsDescriptionExpansion(app.details)
    }

    private func applyFastResult(_ result: FastOnlineResult) {
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
            return
        }
        if let iconData = metadata.iconData {
            applyIconData(iconData, to: result.appID)
            addSource("Herstellerseite", to: index)
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
    }

    private func applySlowResult(_ result: SlowOnlineResult) {
        guard let index = apps.firstIndex(where: { $0.id == result.appID }) else {
            return
        }
        if let homepage = result.homepage, apps[index].homepage == nil {
            addSuggestion(
                CatalogSuggestion(
                    kind: .homepage,
                    value: homepage.absoluteString,
                    sourceLabel: "DuckDuckGo · mögliche Herstellerseite",
                    sourceURL: homepage
                ),
                to: index
            )
        }
        if let metadata = result.github {
            if !apps[index].customizations.links {
                apps[index].githubURL = metadata.projectURL
                apps[index].homepage = metadata.homepageURL ?? apps[index].homepage
                apps[index].downloadURL = metadata.downloadURL
            }
            if let iconData = metadata.iconData,
               shouldReplaceIcon(in: apps[index])
            {
                apps[index].iconData = iconData
                apps[index].iconOrigin = .github
                apps[index] = migrateIcon(in: apps[index])
            }
            if let description = metadata.description {
                recordDescription(
                    description,
                    source: "GitHub-Repository",
                    sourceURL: metadata.projectURL,
                    for: result.appID
                )
            }
            addSource("GitHub-Repository", to: index)
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
            forAppNamed: app.name,
            category: app.category,
            subcategory: app.subcategory,
            needsIcon: shouldReplaceIcon(in: app)
        )
    }

    func applyIconData(_ iconData: Data, to appID: AppEntry.ID) {
        guard iconData.count <= IconImageConverter.maximumStoredBytes,
              let index = apps.firstIndex(where: { $0.id == appID }),
              shouldReplaceIcon(in: apps[index])
        else {
            return
        }
        apps[index].iconData = iconData
        apps[index].iconOrigin = .website
        apps[index] = migrateIcon(in: apps[index])
        persist()
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
           apps[index].iconOrigin != .localBundle
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
        offerWebsitePromptIfNeeded()
    }

    func suppressWebsitePrompt(for appID: AppEntry.ID) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else {
            return
        }
        apps[index].websitePromptSuppressed = true
        promptedWebsiteAppIDs.insert(appID)
        pendingWebsitePrompt = nil
        persist()
        offerWebsitePromptIfNeeded()
    }

    func allowWebsitePrompt(for appID: AppEntry.ID) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else {
            return
        }
        apps[index].websitePromptSuppressed = false
        promptedWebsiteAppIDs.remove(appID)
        persist()
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
        LicenseKeychainStore.shared.delete(for: app.id)
        if selectedAppID == app.id {
            selectedAppID = nil
        }
        persist()
    }

    func deleteAll() {
        for app in apps {
            IconStore.shared.delete(fileName: app.iconFileName)
            LicenseKeychainStore.shared.delete(for: app.id)
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
        let scannedPaths = Set(
            scannedApps.flatMap(\.files).map(\.relativePath)
        )
        let originalPathOwners = Dictionary(
            uniqueKeysWithValues: apps.map {
                ($0.id, Set($0.files.map(\.relativePath)))
            }
        )
        for index in apps.indices {
            apps[index].files.removeAll {
                scannedPaths.contains($0.relativePath)
            }
        }
        var claimedExistingIDs = Set<AppEntry.ID>()

        for scannedApp in scannedApps {
            let scannedKey = AppNameNormalizer.catalogIdentityKey(
                name: scannedApp.name,
                category: scannedApp.category,
                subcategory: scannedApp.subcategory
            )
            let scannedPaths = Set(scannedApp.files.map(\.relativePath))
            let identityIndex = apps.firstIndex(where: {
                !claimedExistingIDs.contains($0.id)
                    && AppNameNormalizer.catalogIdentityKey(
                        name: $0.name,
                        category: $0.category,
                        subcategory: $0.subcategory
                    ) == scannedKey
            })
            let pathOwnerIndex = apps.firstIndex {
                !claimedExistingIDs.contains($0.id)
                    && !(originalPathOwners[$0.id] ?? [])
                        .isDisjoint(with: scannedPaths)
            }
            if let index = identityIndex ?? pathOwnerIndex {
                let matchedByPath = pathOwnerIndex == index
                claimedExistingIDs.insert(apps[index].id)
                let existingPaths = Set(apps[index].files.map(\.relativePath))
                let newFiles = scannedApp.files.filter { !existingPaths.contains($0.relativePath) }
                apps[index].files.append(contentsOf: newFiles)
                if matchedByPath {
                    apps[index].name = scannedApp.name
                    apps[index].category = scannedApp.category
                    apps[index].subcategory = scannedApp.subcategory
                }
                if !apps[index].hasIcon {
                    apps[index].iconData = scannedApp.iconData
                    apps[index].iconOrigin = .localBundle
                    apps[index] = migrateIcon(in: apps[index])
                }
                apps[index] = AppMetadataEnricher().enrich(apps[index])
            } else {
                apps.append(
                    migrateIcon(
                        in: AppMetadataEnricher().enrich(scannedApp)
                    )
                )
            }
        }
        let scannedOriginalIDs = Set(originalPathOwners.compactMap {
            $0.value.isDisjoint(with: scannedPaths) ? nil : $0.key
        })
        apps.removeAll {
            scannedOriginalIDs.contains($0.id)
                && !claimedExistingIDs.contains($0.id)
                && $0.files.isEmpty
        }
        apps.sort(by: Self.sortApps)
        persist()
    }

    func replaceCatalog(
        with importedApps: [AppEntry],
        licenses: [UUID: AppLicenseRecord] = [:]
    ) throws {
        let includedApps = importedApps
            .filter(CatalogEntryFilter().shouldInclude)
            .sorted(by: Self.sortApps)
        let includedIDs = Set(includedApps.map(\.id))
        try LicenseKeychainStore.shared.save(
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

    private func shouldReplaceIcon(in app: AppEntry) -> Bool {
        guard !app.customizations.icon, app.iconOrigin != .manual else {
            return false
        }
        return !app.hasIcon || app.iconOrigin == .iTunes
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
            addDescriptionSuggestion(
                description,
                source: source,
                sourceURL: sourceURL,
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
        guard pendingWebsitePrompt == nil,
              let app = apps.first(where: {
                  $0.homepage == nil
                      && !$0.suppressesWebsitePrompt
                      && !$0.suggestions.contains(where: {
                          $0.kind == .homepage
                      })
                      && !promptedWebsiteAppIDs.contains($0.id)
              })
        else {
            return
        }
        pendingWebsitePrompt = PendingWebsitePrompt(
            appID: app.id,
            appName: app.name
        )
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
