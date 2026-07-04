import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var store: CatalogStore
    @EnvironmentObject private var updateChecker: AppUpdateChecker
    @AppStorage("selectedLayout") private var selectedLayout = AppLayout.classic.rawValue
    @AppStorage("appAtlasTheme") private var selectedThemeID = AppAtlasTheme.system.rawValue
    @AppStorage("appAtlasCustomThemes") private var customThemesRaw = "[]"
    @AppStorage(AppLanguageChoice.storageKey)
    private var languageChoice = AppLanguageChoice.automatic.rawValue
    @StateObject private var presentation = ContentPresentationState()
    @StateObject private var systemAppearance = SystemAppearanceObserver()
    @State private var backupReminderDismissed = false
    @State private var updateBannerDismissed = false

    private var customThemes: [AppAtlasThemeDefinition] {
        AppAtlasThemeDefinition.decodeList(customThemesRaw)
    }

    var body: some View {
        let theme = ThemeStyle.resolve(
            id: selectedThemeID,
            customThemes: customThemes,
            systemColorScheme: systemAppearance.colorScheme
        )

        Group {
            if store.apps.isEmpty {
                EmptyCatalogStartView(
                    showScanner: { presentation.sheet = .scanner },
                    showCatalogImporter: showCatalogImporter
                )
            } else {
                switch layout {
                case .classic:
                    ClassicLibraryLayout()
                case .focus:
                    FocusLibraryLayout()
                case .compact:
                    CompactLibraryLayout()
                case .dashboard:
                    DashboardLibraryLayout()
                case .shelves:
                    ShelvesLibraryLayout()
                }
            }
        }
        .id(
            selectedThemeID == AppAtlasTheme.system.rawValue
                ? systemAppearance.colorScheme
                : nil
        )
        .environment(\.appAtlasTheme, theme)
        .preferredColorScheme(theme.preferredScheme)
        .tint(theme.accent)
        .foregroundStyle(theme.text)
        .background(
            AppAtlasBackground()
                .environment(\.appAtlasTheme, theme)
        )
        .toolbar {
            ContentToolbar(
                selectedLayout: $selectedLayout,
                selectedThemeID: $selectedThemeID,
                customThemes: customThemes,
                importTheme: showThemeImporter,
                exportTheme: exportSelectedTheme,
                deleteTheme: prepareDeleteSelectedTheme,
                showScanner: { presentation.sheet = .scanner },
                showAssistant: { presentation.sheet = .assistant },
                showAddApp: { presentation.sheet = .addApp },
                showErrorReport: { presentation.sheet = .errorReport },
                showStatistics: { presentation.sheet = .statistics },
                showWebsitePromptExclusions: {
                    presentation.sheet = .websiteExclusions
                },
                showCatalogExporter: {
                    presentation.sheet = .catalogExporter
                },
                showCatalogImporter: showCatalogImporter,
                showLicenseImporter: { presentation.importer = .licenses },
                editSelectedApp: {
                    if let app = store.selectedApp {
                        presentation.sheet = .editApp(app)
                    }
                },
                deleteSelectedApp: {
                    if let app = store.selectedApp {
                        presentation.alert = .deleteApp(app)
                    }
                },
                deleteAllApps: { presentation.alert = .deleteAll }
            )
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 0) {
                updateBanner
                backupReminderBanner
            }
        }
        .task {
            await updateChecker.checkAutomaticallyAfterLaunch()
        }
        .modifier(
            ContentSheetsModifier(
                presentation: presentation,
                performPendingCatalogExport: performPendingCatalogExport,
                importEncryptedCatalog: importEncryptedCatalog,
                applyLicenseImport: applyLicenseImport
            )
        )
        .modifier(
            ContentFileImportersModifier(
                presentation: presentation,
                importCatalog: prepareCatalogImport,
                importLicenses: importLicenseData
            )
        )
        .modifier(
            ContentAlertsModifier(
                presentation: presentation,
                deleteTheme: deleteCustomTheme
            )
        )
    }

    private var layout: AppLayout {
        AppLayout(rawValue: selectedLayout) ?? .classic
    }

    @ViewBuilder
    private var updateBanner: some View {
        if !updateBannerDismissed,
           case .updateAvailable(let info) = updateChecker.status {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle")
                Text("AppAtlas \(info.latestVersion) ist verfügbar.")
                    .font(.headline)
                Text("Du kannst die neue Version auf GitHub laden.")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Release öffnen") {
                    updateChecker.openReleasePage()
                }
                Button("Später") {
                    updateBannerDismissed = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial)
        }
    }

    @ViewBuilder
    private var backupReminderBanner: some View {
        if !backupReminderDismissed,
           !store.apps.isEmpty,
           BackupReminderService.isReminderDue()
        {
            HStack(spacing: 12) {
                Image(systemName: "externaldrive.badge.timemachine")
                Text("Zeit für ein Katalog-Backup.")
                    .font(.headline)
                Text(
                    "Exportiere deinen Katalog, damit deine lokalen Daten "
                        + "gesichert sind."
                )
                .foregroundStyle(.secondary)
                Spacer()
                Button("Jetzt exportieren") {
                    presentation.sheet = .catalogExporter
                }
                Button("Später") {
                    backupReminderDismissed = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial)
        }
    }

    private func importCustomTheme(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let theme = try ThemeTransferService().importTheme(from: url)
            let themes = (
                customThemes.filter { $0.id != theme.id } + [theme]
            )
            .sorted { $0.id < $1.id }
            customThemesRaw = AppAtlasThemeDefinition.encodeList(themes)
            selectedThemeID = theme.id
        } catch {
            showError("Theme importieren", error)
        }
    }

    private func showThemeImporter() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                return
            }
            importCustomTheme(.success(url))
        }
    }

    private func showCatalogImporter() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                return
            }
            prepareCatalogImport(.success(url))
        }
    }

    private func prepareCatalogImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            switch try CatalogTransferService().prepareImport(from: url) {
            case .ready(let result):
                try applyCatalogImport(result)
            case .passwordRequired(let data):
                presentation.encryptedCatalogData = data
                presentation.sheet = .catalogPassword
            }
        } catch {
            showError("Katalog importieren", error)
        }
    }

    private func importLicenseData(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let plan = try LicenseImportService().prepare(
                from: url,
                apps: store.apps
            )
            presentation.sheet = .licensePreview(plan)
        } catch {
            showError("Lizenzdaten importieren", error)
        }
    }

    private func applyLicenseImport(
        _ plan: LicenseImportPlan,
        createMissingEntries: Bool
    ) {
        let outcome = LicenseImportService().apply(
            plan,
            createMissingEntries: createMissingEntries
        )
        store.add(outcome.createdApps)
        if outcome.saveResult.savedCount > 0 {
            NotificationCenter.default.post(
                name: .appAtlasLicenseDataDidChange,
                object: nil
            )
        }
        presentation.alert = .message(
            title: "Lizenzimport",
            message: outcome.saveResult.summary
        )
    }

    private func exportCatalog(_ protection: CatalogExportProtection) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "AppAtlas-Katalog.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                return
            }
            do {
                let data = try CatalogTransferService().exportData(
                    apps: store.exportApps(),
                    protection: protection
                )
                try SecurityScopedFileAccess.write(data, to: url)
                CatalogTransferService().recordSuccessfulExport()
                backupReminderDismissed = false
            } catch {
                showError("Katalog exportieren", error)
            }
        }
    }

    private func performPendingCatalogExport() {
        guard let protection = presentation.pendingCatalogExport else {
            return
        }
        presentation.pendingCatalogExport = nil
        DispatchQueue.main.async {
            exportCatalog(protection)
        }
    }

    private func importEncryptedCatalog(password: String) -> Bool {
        guard let data = presentation.encryptedCatalogData else {
            return false
        }
        do {
            try applyCatalogImport(
                CatalogTransferService().decodeEncrypted(
                    data,
                    password: password
                )
            )
            presentation.encryptedCatalogData = nil
            return true
        } catch {
            showError("Katalog importieren", error)
            return false
        }
    }

    private func applyCatalogImport(_ result: CatalogImportResult) throws {
        try store.replaceCatalog(
            with: result.apps,
            licenses: result.licenses
        )
    }

    private func exportSelectedTheme() {
        let theme: AppAtlasThemeDefinition
        if let custom = customThemes.first(
            where: { $0.id == selectedThemeID }
        ) {
            theme = custom
        } else if let builtIn = AppAtlasTheme(rawValue: selectedThemeID) {
            do {
                theme = try builtIn.exportCopy(
                    existingIDs: Set(customThemes.map(\.id))
                )
            } catch {
                showError("Theme exportieren", error)
                return
            }
        } else {
            return
        }

        do {
            let text = try ThemeTransferService().exportText(for: theme)
            saveTheme(
                text: text,
                defaultName: "appatlas-theme-\(theme.id).json"
            )
        } catch {
            showError("Theme exportieren", error)
        }
    }

    private func prepareDeleteSelectedTheme() {
        guard let theme = customThemes.first(where: {
            $0.id == selectedThemeID
        }) else {
            return
        }
        presentation.alert = .deleteTheme(theme)
    }

    private func deleteCustomTheme(_ theme: AppAtlasThemeDefinition) {
        customThemesRaw = AppAtlasThemeDefinition.encodeList(
            customThemes.filter { $0.id != theme.id }
        )
        if selectedThemeID == theme.id {
            selectedThemeID = AppAtlasTheme.system.rawValue
        }
        presentation.alert = nil
    }

    private func saveTheme(text: String, defaultName: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = [.json]
        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                return
            }
            do {
                try SecurityScopedFileAccess.write(text, to: url)
            } catch {
                showError("Theme exportieren", error)
            }
        }
    }

    private func showError(_ title: String, _ error: Error) {
        presentation.alert = .message(
            title: title,
            message: error.localizedDescription
        )
    }
}

private struct EmptyCatalogStartView: View {
    @Environment(\.appAtlasTheme) private var theme
    let showScanner: () -> Void
    let showCatalogImporter: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            AppAtlasMark(size: 82)

            Text("AppAtlas ist bereit")
                .font(.largeTitle.bold())

            Text(
                "Wähle einen lokalen Ordner zum Einlesen oder importiere einen vorhandenen AppAtlas-Katalog."
            )
            .font(.title3)
            .foregroundStyle(theme.mutedText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 560)

            HStack(spacing: 12) {
                Button(action: showScanner) {
                    Label("Ordner scannen", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderedProminent)

                Button(action: showCatalogImporter) {
                    Label("Katalog importieren", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label(
                    "Der lokale Scan verändert den ausgewählten Ordner nicht.",
                    systemImage: "checkmark.shield"
                )
                Label(
                    "Online-Daten werden nur manuell über „Online-Daten aktualisieren“ geladen.",
                    systemImage: "network"
                )
                Label(
                    "Die erweiterte Online-Suche kann bei großen Sammlungen lange dauern.",
                    systemImage: "clock"
                )
            }
            .font(.callout)
            .foregroundStyle(theme.mutedText)
            .padding(.top, 6)
        }
        .padding(34)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppAtlasBackground())
    }
}
