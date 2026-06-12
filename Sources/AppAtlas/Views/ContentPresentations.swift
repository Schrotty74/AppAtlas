import SwiftUI
import UniformTypeIdentifiers

struct ContentSheetsModifier: ViewModifier {
    @EnvironmentObject private var store: CatalogStore

    @Binding var showAddApp: Bool
    @Binding var editingApp: AppEntry?
    @Binding var showAssistant: Bool
    @Binding var showScanner: Bool
    @Binding var showWebsitePromptExclusions: Bool
    @Binding var showCatalogExporter: Bool
    @Binding var encryptedCatalogData: Data?
    @Binding var pendingCatalogExport: CatalogExportProtection?

    let performPendingCatalogExport: () -> Void
    let importEncryptedCatalog: (String) -> Bool

    func body(content: Content) -> some View {
        content
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
                CatalogImportPasswordView(
                    importCatalog: importEncryptedCatalog
                )
            }
    }
}

struct ContentFileImportersModifier: ViewModifier {
    @Binding var showThemeImporter: Bool
    @Binding var showCatalogImporter: Bool
    @Binding var showLicenseImporter: Bool

    let importTheme: (Result<URL, Error>) -> Void
    let importCatalog: (Result<URL, Error>) -> Void
    let importLicenses: (Result<URL, Error>) -> Void

    func body(content: Content) -> some View {
        content
            .fileImporter(
                isPresented: $showThemeImporter,
                allowedContentTypes: [.json],
                onCompletion: importTheme
            )
            .fileImporter(
                isPresented: $showCatalogImporter,
                allowedContentTypes: [.json],
                onCompletion: importCatalog
            )
            .fileImporter(
                isPresented: $showLicenseImporter,
                allowedContentTypes: [.json, .commaSeparatedText],
                onCompletion: importLicenses
            )
    }
}

struct ContentAlertsModifier: ViewModifier {
    @EnvironmentObject private var store: CatalogStore

    @Binding var themeErrorMessage: String?
    @Binding var catalogMessage: String?
    @Binding var themePendingDeletion: AppAtlasThemeDefinition?
    @Binding var appPendingDeletion: AppEntry?
    @Binding var showDeleteAllConfirmation: Bool

    let deleteTheme: (AppAtlasThemeDefinition?) -> Void

    func body(content: Content) -> some View {
        content
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
                    get: { catalogMessage != nil },
                    set: { if !$0 { catalogMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(catalogMessage ?? "")
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
                    deleteTheme(themePendingDeletion)
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
                deleteButtons(for: app)
            } message: { app in
                Text(
                    "Du kannst „\(app.name)“ nur aus AppAtlas entfernen oder "
                        + "alle zugeordneten lokalen Dateien in den "
                        + "macOS-Papierkorb legen."
                )
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

    @ViewBuilder
    private func deleteButtons(for app: AppEntry) -> some View {
        Button("Abbrechen", role: .cancel) {}
        Button("Nur aus Katalog löschen", role: .destructive) {
            store.delete(app)
            appPendingDeletion = nil
        }
        if !app.files.isEmpty {
            Button(
                "Lokale Dateien in Papierkorb legen",
                role: .destructive
            ) {
                deleteLocalFiles(for: app)
            }
        }
    }

    private func deleteLocalFiles(for app: AppEntry) {
        do {
            try LocalAppTrashService().moveFilesToTrash(for: app)
            store.delete(app)
            appPendingDeletion = nil
        } catch {
            appPendingDeletion = nil
            catalogMessage = error.localizedDescription
        }
    }
}

struct DeleteAllCatalogConfirmation: ViewModifier {
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
