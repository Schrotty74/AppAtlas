import AppKit
import SwiftUI

@main
struct AppAtlasApp: App {
    @StateObject private var store = CatalogStore()
    @AppStorage(AppLanguageChoice.storageKey)
    private var languageChoice = AppLanguageChoice.automatic.rawValue

    init() {
        try? IconStore.shared.prepareDirectories()

        if let iconURL = AppResources.bundle.url(forResource: "AppIcon", withExtension: "png"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = icon
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.locale, selectedLanguage.locale)
                .frame(minWidth: 980, minHeight: 620)
        }
        .windowToolbarStyle(.unified)
        Settings {
            AppSettingsView()
                .environment(\.locale, selectedLanguage.locale)
        }
        .commands {
            CommandMenu("Katalog") {
                Button("Online-Daten aktualisieren") {
                    Task {
                        await store.enrichCatalog()
                    }
                }
                .disabled(store.isEnriching || store.apps.isEmpty)
            }
            CommandMenu("Sprache") {
                ForEach(AppLanguageChoice.allCases) { language in
                    Button {
                        languageChoice = language.rawValue
                    } label: {
                        if selectedLanguage == language {
                            Label {
                                Text(LocalizedStringKey(language.title))
                            } icon: {
                                Image(systemName: "checkmark")
                            }
                        } else {
                            Text(LocalizedStringKey(language.title))
                        }
                    }
                }
            }
        }
    }

    private var selectedLanguage: AppLanguageChoice {
        AppLanguageChoice(rawValue: languageChoice) ?? .automatic
    }
}
