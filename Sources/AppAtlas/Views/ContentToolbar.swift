import SwiftUI

struct ContentToolbar: ToolbarContent {
    @EnvironmentObject private var store: CatalogStore

    @Binding var selectedLayout: String
    @Binding var selectedThemeID: String

    let customThemes: [AppAtlasThemeDefinition]
    let importTheme: () -> Void
    let exportTheme: () -> Void
    let deleteTheme: () -> Void
    let showScanner: () -> Void
    let showAssistant: () -> Void
    let showAddApp: () -> Void
    let showWebsitePromptExclusions: () -> Void
    let showCatalogExporter: () -> Void
    let showCatalogImporter: () -> Void
    let showLicenseImporter: () -> Void
    let editSelectedApp: () -> Void
    let deleteSelectedApp: () -> Void
    let deleteAllApps: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            ContentNavigationToolbar(
                selectedLayout: $selectedLayout,
                showScanner: showScanner
            )
        }

        ToolbarItem(placement: .primaryAction) {
            ThemeMenu(
                selectedThemeID: $selectedThemeID,
                customThemes: customThemes,
                importTheme: importTheme,
                exportTheme: exportTheme,
                deleteTheme: deleteTheme
            )
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: showAssistant) {
                Label("App-Assistent", systemImage: "sparkles")
            }
            .help("Den lokalen Katalog befragen")

            Button(action: showAddApp) {
                Label("App hinzufügen", systemImage: "plus")
            }
            .help("Eine App manuell hinzufügen")

            actionsMenu
        }
    }

    private var actionsMenu: some View {
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

            Button(action: showWebsitePromptExclusions) {
                Label(
                    "Website-Ausschlussliste",
                    systemImage: "list.bullet.rectangle"
                )
            }

            Divider()

            Button("Katalog exportieren …", action: showCatalogExporter)
            Button(
                "Katalog importieren und ersetzen …",
                action: showCatalogImporter
            )
            Button("Lizenzdaten importieren …", action: showLicenseImporter)

            Divider()

            Button("Bearbeiten", action: editSelectedApp)
                .disabled(store.selectedApp == nil)

            Divider()

            Button(
                "Aus Katalog löschen",
                role: .destructive,
                action: deleteSelectedApp
            )
            .disabled(store.selectedApp == nil)

            Button(
                "Gesamten Katalog löschen …",
                role: .destructive,
                action: deleteAllApps
            )
            .disabled(store.apps.isEmpty)
        } label: {
            Label("App-Aktionen", systemImage: "ellipsis.circle")
        }
    }
}

private struct ContentNavigationToolbar: View {
    @EnvironmentObject private var store: CatalogStore
    @Binding var selectedLayout: String
    let showScanner: () -> Void

    private var layout: AppLayout {
        AppLayout(rawValue: selectedLayout) ?? .classic
    }

    var body: some View {
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

            Button(action: showScanner) {
                Label(
                    "Apps scannen",
                    systemImage: "magnifyingglass.circle.fill"
                )
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
}
