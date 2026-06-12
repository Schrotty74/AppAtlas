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
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 8) {
                    AppAtlasMark(size: 34)
                    GitHubMark(size: 34)

                    Button {
                        Task {
                            await store.enrichCatalog()
                        }
                    } label: {
                        Label(
                            store.isEnriching
                                ? "Online-Daten werden aktualisiert …"
                                : "Online-Daten aktualisieren",
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                    }
                    .help(
                        store.isEnriching
                            ? store.enrichmentProgress
                            : "Fehlende Icons, Beschreibungen und Links bewusst online ergänzen"
                    )
                    .disabled(store.isEnriching || store.apps.isEmpty)

                    Button {
                        showScanner = true
                    } label: {
                        Label("Apps scannen", systemImage: "magnifyingglass.circle.fill")
                    }
                    .help("Einen frei gewählten Quellordner rein lesend scannen")

                    Menu {
                        ForEach(AppLayout.allCases) { layout in
                            Button {
                                selectedLayout = layout.rawValue
                            } label: {
                                Label(layout.title, systemImage: layout.systemImage)
                            }
                        }
                    } label: {
                        Image(systemName: layout.systemImage)
                    }
                    .help("Ansicht auswählen")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                ThemeMenu(
                    selectedThemeID: $selectedThemeID,
                    customThemes: customThemes,
                    importTheme: { showThemeImporter = true },
                    exportTheme: exportSelectedTheme,
                    deleteTheme: prepareDeleteSelectedTheme
                )
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showAssistant = true
                } label: {
                    Label("App-Assistent", systemImage: "sparkles")
                }
                .help("Den lokalen Katalog befragen")

                Button {
                    showAddApp = true
                } label: {
                    Label("App hinzufügen", systemImage: "plus")
                }
                .help("Eine App manuell hinzufügen")

                Menu {
                    Button {
                        Task {
                            await store.enrichCatalog()
                        }
                    } label: {
                        Label(
                            store.isEnriching
                                ? "Online-Daten werden aktualisiert …"
                                : "Online-Daten aktualisieren",
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                    }
                    .disabled(store.isEnriching || store.apps.isEmpty)

                    if store.isEnriching {
                        Text(store.enrichmentProgress)
                    }

                    Divider()

                    SettingsLink {
                        Label("Einstellungen …", systemImage: "gearshape")
                    }

                    Divider()

                    Button {
                        showWebsitePromptExclusions = true
                    } label: {
                        Label(
                            "Website-Ausschlussliste",
                            systemImage: "list.bullet.rectangle"
                        )
                    }

                    Divider()

                    Button("Katalog exportieren …") {
                        showCatalogExporter = true
                    }
                    Button("Katalog importieren und ersetzen …") {
                        showCatalogImporter = true
                    }
                    Button("Lizenzdaten importieren …") {
                        showLicenseImporter = true
                    }

                    Divider()

                    Button("Bearbeiten") {
                        editingApp = store.selectedApp
                    }
                    .disabled(store.selectedApp == nil)

                    Divider()

                    Button("Aus Katalog löschen", role: .destructive) {
                        appPendingDeletion = store.selectedApp
                    }
                    .disabled(store.selectedApp == nil)

                    Button("Gesamten Katalog löschen …", role: .destructive) {
                        showDeleteAllConfirmation = true
                    }
                    .disabled(store.apps.isEmpty)
                } label: {
                    Label("App-Aktionen", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddApp) {
            AppEditorView(existingApp: nil) { app in
                store.add(app)
            }
        }
        .sheet(item: $editingApp) { app in
            AppEditorView(existingApp: app) { updatedApp in
                store.update(updatedApp)
            }
        }
        .sheet(isPresented: $showAssistant) {
            AssistantView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showScanner) {
            ScanImportView()
                .environmentObject(store)
        }
        .sheet(item: $store.pendingWebsitePrompt) { prompt in
            WebsitePromptView(prompt: prompt)
                .environmentObject(store)
        }
        .sheet(isPresented: $showWebsitePromptExclusions) {
            WebsitePromptExclusionsView()
                .environmentObject(store)
        }
        .sheet(
            isPresented: $showCatalogExporter,
            onDismiss: performPendingCatalogExport
        ) {
            CatalogExportOptionsView { protection in
                pendingCatalogExport = protection
            }
        }
        .sheet(
            isPresented: Binding(
                get: { encryptedCatalogData != nil },
                set: { if !$0 { encryptedCatalogData = nil } }
            )
        ) {
            CatalogImportPasswordView(importCatalog: importEncryptedCatalog)
        }
        .fileImporter(
            isPresented: $showThemeImporter,
            allowedContentTypes: [.json]
        ) { result in
            importCustomTheme(result)
        }
        .fileImporter(
            isPresented: $showCatalogImporter,
            allowedContentTypes: [.json]
        ) { result in
            prepareCatalogImport(result)
        }
        .fileImporter(
            isPresented: $showLicenseImporter,
            allowedContentTypes: [.json, .commaSeparatedText]
        ) { result in
            importLicenseData(result)
        }
        .alert(
            "Theme importieren",
            isPresented: Binding(
                get: { themeErrorMessage != nil },
                set: { if !$0 { themeErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                themeErrorMessage = nil
            }
        } message: {
            Text(themeErrorMessage ?? "")
        }
        .alert(
            "AppAtlas",
            isPresented: Binding(
                get: { catalogErrorMessage != nil },
                set: { if !$0 { catalogErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(catalogErrorMessage ?? "")
        }
        .alert(
            "Theme löschen?",
            isPresented: Binding(
                get: { themePendingDeletion != nil },
                set: { if !$0 { themePendingDeletion = nil } }
            )
        ) {
            Button("Abbrechen", role: .cancel) {
                themePendingDeletion = nil
            }
            Button("Theme löschen", role: .destructive) {
                deleteCustomTheme(themePendingDeletion)
            }
        } message: {
            Text("Das importierte Theme wird aus AppAtlas entfernt.")
        }
        .alert(
            "App aus dem Katalog löschen?",
            isPresented: Binding(
                get: { appPendingDeletion != nil },
                set: { if !$0 { appPendingDeletion = nil } }
            ),
            presenting: appPendingDeletion
        ) { app in
            Button("Abbrechen", role: .cancel) {}
            Button("Nur aus Katalog löschen", role: .destructive) {
                store.delete(app)
                appPendingDeletion = nil
            }
            if !app.files.isEmpty {
                Button("Lokale Dateien in Papierkorb legen", role: .destructive) {
                    do {
                        try LocalAppTrashService().moveFilesToTrash(for: app)
                        store.delete(app)
                        appPendingDeletion = nil
                    } catch {
                        appPendingDeletion = nil
                        catalogErrorMessage = error.localizedDescription
                    }
                }
            }
        } message: { app in
            Text("Du kannst „\(app.name)“ nur aus AppAtlas entfernen oder alle zugeordneten lokalen Dateien in den macOS-Papierkorb legen.")
        }
        .modifier(
            DeleteAllCatalogConfirmation(
                isPresented: $showDeleteAllConfirmation
            )
        )
        .alert(
            "Import fehlgeschlagen",
            isPresented: Binding(
                get: { store.importError != nil },
                set: { _ in }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(store.importError ?? "")
        }
        .alert(
            "Katalog konnte nicht gespeichert werden",
            isPresented: Binding(
                get: { store.persistenceError != nil },
                set: { if !$0 { store.clearPersistenceError() } }
            )
        ) {
            Button("OK") {
                store.clearPersistenceError()
            }
        } message: {
            Text(store.persistenceError ?? "")
        }
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

private struct DeleteAllCatalogConfirmation: ViewModifier {
    @EnvironmentObject private var store: CatalogStore
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content.alert(
            "Gesamten Katalog löschen?",
            isPresented: $isPresented
        ) {
            Button("Abbrechen", role: .cancel) {}
            Button("Gesamten Katalog löschen", role: .destructive) {
                store.deleteAll()
            }
        } message: {
            Text(
                "Alle Katalogeinträge, gespeicherten App-Icons und privaten "
                    + "Lizenzdaten werden aus AppAtlas entfernt. Dateien in "
                    + "deinen ausgewählten Ordnern bleiben unverändert."
            )
        }
    }
}
