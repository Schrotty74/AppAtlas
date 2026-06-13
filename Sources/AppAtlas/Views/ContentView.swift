import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var store: CatalogStore
    @AppStorage("selectedLayout") private var selectedLayout = AppLayout.classic.rawValue
    @AppStorage("appAtlasTheme") private var selectedThemeID = AppAtlasTheme.system.rawValue
    @AppStorage("appAtlasCustomThemes") private var customThemesRaw = "[]"
    @AppStorage(AppLanguageChoice.storageKey)
    private var languageChoice = AppLanguageChoice.automatic.rawValue
    @StateObject private var presentation = ContentPresentationState()

    private var customThemes: [AppAtlasThemeDefinition] {
        AppAtlasThemeDefinition.decodeList(customThemesRaw)
    }

    var body: some View {
        let theme = ThemeStyle.resolve(
            id: selectedThemeID,
            customThemes: customThemes
        )

        Group {
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
        .environment(\.appAtlasTheme, theme)
        .preferredColorScheme(theme.preferredScheme)
        .tint(theme.accent)
        .foregroundStyle(theme.text)
        .background(
            AppAtlasBackground()
                .environment(\.appAtlasTheme, theme)
        )
        .background {
            CatalogTranslationView()
                .environmentObject(store)
        }
        .searchable(text: $store.searchText, prompt: "Apps, Kategorien und Dateinamen")
        .onChange(of: languageChoice) { _, _ in
            store.refreshDescriptionTranslations()
        }
        .toolbar {
            ContentToolbar(
                selectedLayout: $selectedLayout,
                selectedThemeID: $selectedThemeID,
                customThemes: customThemes,
                importTheme: { presentation.importer = .theme },
                exportTheme: exportSelectedTheme,
                deleteTheme: prepareDeleteSelectedTheme,
                showScanner: { presentation.sheet = .scanner },
                showAssistant: { presentation.sheet = .assistant },
                showAddApp: { presentation.sheet = .addApp },
                showWebsitePromptExclusions: {
                    presentation.sheet = .websiteExclusions
                },
                showCatalogExporter: {
                    presentation.sheet = .catalogExporter
                },
                showCatalogImporter: { presentation.importer = .catalog },
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
                importTheme: importCustomTheme,
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
        do {
            let data = try CatalogTransferService().exportData(
                apps: store.exportApps(),
                protection: protection
            )
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
                    try SecurityScopedFileAccess.write(data, to: url)
                } catch {
                    showError("Katalog exportieren", error)
                }
            }
        } catch {
            showError("Katalog exportieren", error)
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
