import SwiftUI
import UniformTypeIdentifiers

struct ContentSheetsModifier: ViewModifier {
    @EnvironmentObject private var store: CatalogStore
    @ObservedObject var presentation: ContentPresentationState

    let performPendingCatalogExport: () -> Void
    let importEncryptedCatalog: (String) -> Bool
    let applyLicenseImport: (LicenseImportPlan, Bool) -> Void

    func body(content: Content) -> some View {
        content
            .sheet(
                item: $presentation.sheet,
                onDismiss: performPendingCatalogExport
            ) { sheet in
                sheetContent(for: sheet)
            }
            .sheet(item: $store.pendingWebsitePrompt) { prompt in
                WebsitePromptView(prompt: prompt)
                    .environmentObject(store)
            }
    }

    @ViewBuilder
    private func sheetContent(for sheet: ContentSheet) -> some View {
        switch sheet {
        case .addApp:
            AppEditorView(existingApp: nil) { app in
                store.add(app)
            }
        case .editApp(let app):
            AppEditorView(existingApp: app) { updatedApp in
                store.update(updatedApp)
            }
        case .assistant:
            AssistantView()
                .environmentObject(store)
        case .scanner:
            ScanImportView()
                .environmentObject(store)
        case .errorReport:
            ErrorReportView()
        case .websiteExclusions:
            WebsitePromptExclusionsView()
                .environmentObject(store)
        case .catalogExporter:
            CatalogExportOptionsView { protection in
                presentation.pendingCatalogExport = protection
            }
        case .catalogPassword:
            CatalogImportPasswordView(
                importCatalog: importEncryptedCatalog
            )
        case .licensePreview(let plan):
            LicenseImportPreviewView(plan: plan) { createMissingEntries in
                applyLicenseImport(plan, createMissingEntries)
            }
        }
    }
}

struct ContentFileImportersModifier: ViewModifier {
    @ObservedObject var presentation: ContentPresentationState

    let importCatalog: (Result<URL, Error>) -> Void
    let importLicenses: (Result<URL, Error>) -> Void

    func body(content: Content) -> some View {
        content
            .fileImporter(
                isPresented: importerBinding(for: .catalog),
                allowedContentTypes: [.json],
                onCompletion: importCatalog
            )
            .fileImporter(
                isPresented: importerBinding(for: .licenses),
                allowedContentTypes: [.json, .commaSeparatedText],
                onCompletion: importLicenses
            )
    }

    private func importerBinding(for importer: ContentImporter) -> Binding<Bool> {
        Binding(
            get: { presentation.importer == importer },
            set: { isPresented in
                if isPresented {
                    presentation.importer = importer
                } else if presentation.importer == importer {
                    presentation.importer = nil
                }
            }
        )
    }
}

struct ContentAlertsModifier: ViewModifier {
    @EnvironmentObject private var store: CatalogStore
    @ObservedObject var presentation: ContentPresentationState

    let deleteTheme: (AppAtlasThemeDefinition) -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                alertTitle,
                isPresented: centralAlertBinding,
                presenting: presentation.alert
            ) { alert in
                alertButtons(for: alert)
            } message: { alert in
                Text(alertMessage(for: alert))
            }
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

    private var centralAlertBinding: Binding<Bool> {
        Binding(
            get: { presentation.alert != nil },
            set: { isPresented in
                if !isPresented {
                    presentation.dismissAlert()
                }
            }
        )
    }

    private var alertTitle: String {
        switch presentation.alert {
        case .message(let title, _):
            return title
        case .deleteTheme:
            return "Theme löschen?"
        case .deleteApp:
            return "App aus dem Katalog löschen?"
        case .deleteAll:
            return "Gesamten Katalog löschen?"
        case nil:
            return "AppAtlas"
        }
    }

    private func alertMessage(for alert: ContentAlert) -> String {
        switch alert {
        case .message(_, let message):
            return message
        case .deleteTheme:
            return "Das importierte Theme wird aus AppAtlas entfernt."
        case .deleteApp(let app):
            return "Du kannst „\(app.name)“ nur aus AppAtlas entfernen oder "
                + "alle zugeordneten lokalen Dateien in den "
                + "macOS-Papierkorb legen."
        case .deleteAll:
            return "Alle Katalogeinträge, gespeicherten App-Icons und privaten "
                + "Lizenzdaten werden aus AppAtlas entfernt. Dateien in "
                + "deinen ausgewählten Ordnern bleiben unverändert."
        }
    }

    @ViewBuilder
    private func alertButtons(for alert: ContentAlert) -> some View {
        switch alert {
        case .message:
            Button("OK", role: .cancel) {
                presentation.dismissAlert()
            }
        case .deleteTheme(let theme):
            Button("Abbrechen", role: .cancel) {
                presentation.dismissAlert()
            }
            Button("Theme löschen", role: .destructive) {
                deleteTheme(theme)
            }
        case .deleteApp(let app):
            Button("Abbrechen", role: .cancel) {
                presentation.dismissAlert()
            }
            Button("Nur aus Katalog löschen", role: .destructive) {
                store.delete(app)
                presentation.dismissAlert()
            }
            if !app.files.isEmpty {
                Button(
                    "Lokale Dateien in Papierkorb legen",
                    role: .destructive
                ) {
                    deleteLocalFiles(for: app)
                }
            }
        case .deleteAll:
            Button("Abbrechen", role: .cancel) {
                presentation.dismissAlert()
            }
            Button("Gesamten Katalog löschen", role: .destructive) {
                store.deleteAll()
                presentation.dismissAlert()
            }
        }
    }

    private func deleteLocalFiles(for app: AppEntry) {
        do {
            try LocalAppTrashService().moveFilesToTrash(for: app)
            store.delete(app)
            presentation.dismissAlert()
        } catch {
            presentation.alert = .message(
                title: "App konnte nicht gelöscht werden",
                message: error.localizedDescription
            )
        }
    }
}
