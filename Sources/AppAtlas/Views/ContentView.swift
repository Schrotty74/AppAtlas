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
    @State private var showAddApp = false
    @State private var editingApp: AppEntry?
    @State private var appPendingDeletion: AppEntry?
    @State private var showAssistant = false
    @State private var showScanner = false
    @State private var showThemeImporter = false
    @State private var showCatalogImporter = false
    @State private var showLicenseImporter = false
    @State private var showCatalogExporter = false
    @State private var encryptedCatalogData: Data?
    @State private var pendingCatalogExport: CatalogExportProtection?
    @State private var themeErrorMessage: String?
    @State private var catalogErrorMessage: String?
    @State private var themePendingDeletion: AppAtlasThemeDefinition?
    @State private var showDeleteAllConfirmation = false
    @State private var showWebsitePromptExclusions = false

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
                importTheme: { showThemeImporter = true },
                exportTheme: exportSelectedTheme,
                deleteTheme: prepareDeleteSelectedTheme,
                showScanner: { showScanner = true },
                showAssistant: { showAssistant = true },
                showAddApp: { showAddApp = true },
                showWebsitePromptExclusions: {
                    showWebsitePromptExclusions = true
                },
                showCatalogExporter: { showCatalogExporter = true },
                showCatalogImporter: { showCatalogImporter = true },
                showLicenseImporter: { showLicenseImporter = true },
                editSelectedApp: { editingApp = store.selectedApp },
                deleteSelectedApp: {
                    appPendingDeletion = store.selectedApp
                },
                deleteAllApps: { showDeleteAllConfirmation = true }
            )
        }
        .modifier(
            ContentSheetsModifier(
                showAddApp: $showAddApp,
                editingApp: $editingApp,
                showAssistant: $showAssistant,
                showScanner: $showScanner,
                showWebsitePromptExclusions: $showWebsitePromptExclusions,
                showCatalogExporter: $showCatalogExporter,
                encryptedCatalogData: $encryptedCatalogData,
                pendingCatalogExport: $pendingCatalogExport,
                performPendingCatalogExport: performPendingCatalogExport,
                importEncryptedCatalog: importEncryptedCatalog
            )
        )
        .modifier(
            ContentFileImportersModifier(
                showThemeImporter: $showThemeImporter,
                showCatalogImporter: $showCatalogImporter,
                showLicenseImporter: $showLicenseImporter,
                importTheme: importCustomTheme,
                importCatalog: prepareCatalogImport,
                importLicenses: importLicenseData
            )
        )
        .modifier(
            ContentAlertsModifier(
                themeErrorMessage: $themeErrorMessage,
                catalogMessage: $catalogErrorMessage,
                themePendingDeletion: $themePendingDeletion,
                appPendingDeletion: $appPendingDeletion,
                showDeleteAllConfirmation: $showDeleteAllConfirmation,
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
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let theme = try ThemeDocumentDecoder.decode(data)
            let themes = (
                customThemes.filter { $0.id != theme.id } + [theme]
            )
            .sorted { $0.id < $1.id }
            customThemesRaw = AppAtlasThemeDefinition.encodeList(themes)
            selectedThemeID = theme.id
        } catch {
            themeErrorMessage = error.localizedDescription
        }
    }

    private func prepareCatalogImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let data = try Data(contentsOf: url)
            if CatalogTransferDocument.requiresPassword(data) {
                encryptedCatalogData = data
            } else {
                try applyCatalogImport(
                    CatalogTransferDocument.decode(data)
                )
            }
        } catch {
            catalogErrorMessage = error.localizedDescription
        }
    }

    private func importLicenseData(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let importer = LicenseDataImporter()
            let licenses = try importer.decode(
                data: Data(contentsOf: url),
                fileExtension: url.pathExtension
            )
            let plan = importer.plan(licenses: licenses, apps: store.apps)
            var savedCount = 0
            var failedCount = 0
            for match in plan.matches {
                do {
                    let existing = LicenseKeychainStore.shared.load(
                        for: match.appID
                    ) ?? AppLicenseRecord()
                    try LicenseKeychainStore.shared.save(
                        existing.mergingMissingValues(from: match.record),
                        for: match.appID
                    )
                    savedCount += 1
                } catch {
                    failedCount += 1
                }
            }
            let saveResult = LicenseImportSaveResult(
                savedCount: savedCount,
                failedCount: failedCount,
                unmatchedCount: plan.unmatchedNames.count,
                ambiguousCount: plan.ambiguousNames.count
            )
            if savedCount > 0 {
                NotificationCenter.default.post(
                    name: .appAtlasLicenseDataDidChange,
                    object: nil
                )
            }
            catalogErrorMessage = "Lizenzimport\n\n\(saveResult.summary)"
        } catch {
            catalogErrorMessage = error.localizedDescription
        }
    }

    private func exportCatalog(_ protection: CatalogExportProtection) {
        do {
            let data = try CatalogTransferDocument.encoded(
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
                    try data.write(to: url, options: .atomic)
                } catch {
                    catalogErrorMessage = error.localizedDescription
                }
            }
        } catch {
            catalogErrorMessage = error.localizedDescription
        }
    }

    private func performPendingCatalogExport() {
        guard let protection = pendingCatalogExport else {
            return
        }
        pendingCatalogExport = nil
        DispatchQueue.main.async {
            exportCatalog(protection)
        }
    }

    private func importEncryptedCatalog(password: String) -> Bool {
        guard let encryptedCatalogData else {
            return false
        }
        do {
            try applyCatalogImport(
                CatalogTransferDocument.decode(
                    encryptedCatalogData,
                    password: password
                )
            )
            self.encryptedCatalogData = nil
            return true
        } catch {
            catalogErrorMessage = error.localizedDescription
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
                themeErrorMessage = error.localizedDescription
                return
            }
        } else {
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(theme)
            guard var text = String(data: data, encoding: .utf8) else {
                throw CocoaError(.fileWriteInapplicableStringEncoding)
            }
            text += "\n"
            saveTheme(
                text: text,
                defaultName: "appatlas-theme-\(theme.id).json"
            )
        } catch {
            themeErrorMessage = error.localizedDescription
        }
    }

    private func prepareDeleteSelectedTheme() {
        themePendingDeletion = customThemes.first {
            $0.id == selectedThemeID
        }
    }

    private func deleteCustomTheme(_ theme: AppAtlasThemeDefinition?) {
        guard let theme else {
            return
        }
        customThemesRaw = AppAtlasThemeDefinition.encodeList(
            customThemes.filter { $0.id != theme.id }
        )
        if selectedThemeID == theme.id {
            selectedThemeID = AppAtlasTheme.system.rawValue
        }
        themePendingDeletion = nil
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
                try text.write(
                    to: url,
                    atomically: true,
                    encoding: .utf8
                )
            } catch {
                themeErrorMessage = error.localizedDescription
            }
        }
    }
}
