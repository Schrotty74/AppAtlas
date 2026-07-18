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
    let showErrorReport: () -> Void
    let showStatistics: () -> Void
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

        ToolbarItemGroup(placement: .primaryAction) {
            AppCountToolbarItem()

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

            CatalogSearchToolbarButton()
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
                Button {
                    if store.isEnrichmentPaused {
                        store.resumeEnrichment()
                    } else {
                        store.pauseEnrichment()
                    }
                } label: {
                    Label(
                        store.isEnrichmentPaused ? "Fortsetzen" : "Pausieren",
                        systemImage: store.isEnrichmentPaused
                            ? "play.fill"
                            : "pause.fill"
                    )
                }

                Button(role: .destructive) {
                    store.cancelEnrichment()
                } label: {
                    Label("Abbrechen", systemImage: "xmark.circle")
                }

                Text(store.enrichmentProgress)
            }

            Divider()

            SettingsLink {
                Label("Einstellungen …", systemImage: "gearshape")
            }

            Button(action: showErrorReport) {
                Label("Fehler melden", systemImage: "exclamationmark.bubble")
            }

            Button(action: showStatistics) {
                Label("Katalogstatistik", systemImage: "chart.bar.xaxis")
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

private struct CatalogSearchToolbarButton: View {
    @EnvironmentObject private var store: CatalogStore
    @State private var isPresented = false
    @FocusState private var isFocused: Bool

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label("Suchen", systemImage: "magnifyingglass")
        }
        .help("Apps, Kategorien und Dateinamen durchsuchen")
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            TextField(
                "Apps, Kategorien und Dateinamen",
                text: $store.searchText
            )
            .textFieldStyle(.roundedBorder)
            .focused($isFocused)
            .frame(width: 320)
            .padding()
            .onAppear {
                isFocused = true
            }
        }
    }
}

private struct AppCountToolbarItem: View {
    @EnvironmentObject private var store: CatalogStore

    var body: some View {
        Text("\(store.filteredApps.count) Apps")
            .foregroundStyle(.primary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: 110)
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
            DiscordMark(size: 34)
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

            if store.isEnriching {
                Button {
                    if store.isEnrichmentPaused {
                        store.resumeEnrichment()
                    } else {
                        store.pauseEnrichment()
                    }
                } label: {
                    Label(
                        store.isEnrichmentPaused ? "Fortsetzen" : "Pausieren",
                        systemImage: store.isEnrichmentPaused
                            ? "play.fill"
                            : "pause.fill"
                    )
                }
                .help(store.isEnrichmentPaused ? "Online-Aktualisierung fortsetzen" : "Online-Aktualisierung pausieren")

                Button(role: .destructive) {
                    store.cancelEnrichment()
                } label: {
                    Label("Abbrechen", systemImage: "xmark.circle")
                }
                .help("Online-Aktualisierung abbrechen")
            }

            Button(action: showScanner) {
                Label(
                    "Ordner scannen",
                    systemImage: "folder.badge.plus"
                )
            }
            .help("Einen lokalen Ordner auswählen und Apps einlesen")

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
