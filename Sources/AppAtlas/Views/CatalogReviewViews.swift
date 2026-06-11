import SwiftUI

struct CatalogReviewSection: View {
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme
    let app: AppEntry
    let edit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Zu prüfen", systemImage: "checklist")
                    .font(.headline)
                Spacer()
                Button("Als geprüft markieren") {
                    store.resolveReview(for: app.id)
                }
            }

            if app.suggestions.isEmpty {
                Text("Für diesen Eintrag fehlen noch verlässliche Angaben oder ein passendes Icon.")
                    .foregroundStyle(theme.mutedText)
                Button("Manuell bearbeiten", action: edit)
            } else {
                ForEach(app.suggestions) { suggestion in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(suggestion.kind.title)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(suggestion.sourceLabel)
                                .font(.caption)
                                .foregroundStyle(theme.mutedText)
                        }

                        Text(suggestion.value)
                            .font(.callout)
                            .foregroundStyle(theme.mutedText)
                            .lineLimit(suggestion.kind == .description ? 8 : 2)
                            .textSelection(.enabled)

                        if suggestion.needsTranslation {
                            Label(
                                "Wird vor der Übernahme lokal übersetzt",
                                systemImage: "character.bubble"
                            )
                            .font(.caption)
                            .foregroundStyle(theme.mutedText)
                        }

                        HStack {
                            Button("Übernehmen") {
                                store.acceptSuggestion(
                                    suggestion.id,
                                    for: app.id
                                )
                            }

                            Button("Bearbeiten", action: edit)

                            Button("Verwerfen", role: .destructive) {
                                store.dismissSuggestion(
                                    suggestion.id,
                                    for: app.id
                                )
                            }

                            if let sourceURL = suggestion.sourceURL {
                                Link("Quelle öffnen", destination: sourceURL)
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        theme.panelSoft,
                        in: RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                    )
                }
            }
        }
    }
}

struct WebsitePromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CatalogStore
    let prompt: PendingWebsitePrompt
    @State private var website = ""

    var body: some View {
        NavigationStack {
            Form {
                Text("Keine verlässliche Icon- oder Beschreibungsquelle wurde für „\(prompt.appName)“ gefunden. Möchtest du eine Website-URL ergänzen?")
                TextField("https://…", text: $website)
            }
            .formStyle(.grouped)
            .navigationTitle("Website ergänzen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Menu {
                        Button("Diesmal überspringen") {
                            store.dismissWebsitePrompt(for: prompt.appID)
                            dismiss()
                        }
                        Button(
                            "Für diese App nicht mehr fragen",
                            role: .destructive
                        ) {
                            store.suppressWebsitePrompt(for: prompt.appID)
                            dismiss()
                        }
                    } label: {
                        Text("Überspringen")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Übernehmen") {
                        store.confirmWebsite(website, for: prompt.appID)
                        dismiss()
                    }
                    .disabled(
                        website.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
        }
        .frame(width: 520, height: 230)
    }
}

struct WebsitePromptExclusionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme
    @State private var editingApp: AppEntry?

    var body: some View {
        NavigationStack {
            Group {
                if store.websitePromptExclusions.isEmpty {
                    ContentUnavailableView(
                        "Keine ausgeschlossenen Apps",
                        systemImage: "checkmark.circle",
                        description: Text(
                            "Für alle Apps darf AppAtlas bei Bedarf nach einer Website fragen."
                        )
                    )
                } else {
                    List(store.websitePromptExclusions) { app in
                        HStack(spacing: 12) {
                            AppIconView(app: app, size: 38, cornerRadius: 9)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                    .fontWeight(.medium)
                                Text("\(app.category) · \(app.subcategory)")
                                    .font(.caption)
                                    .foregroundStyle(theme.mutedText)
                            }
                            Spacer()
                            Button("Bearbeiten") {
                                editingApp = app
                            }
                            Button("Wieder fragen") {
                                store.allowWebsitePrompt(for: app.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Website-Ausschlussliste")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 680, minHeight: 460)
        .sheet(item: $editingApp) { app in
            AppEditorView(existingApp: app) { updatedApp in
                store.update(updatedApp)
                if updatedApp.homepage != nil {
                    store.allowWebsitePrompt(for: app.id)
                }
            }
        }
    }
}
