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

struct WebsiteReviewSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CatalogStore
    let summary: WebsiteReviewSummary
    @State private var editingApp: AppEntry?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(summary.foundCount) Apps wurden gescannt.")
                    .font(.headline)
                Text(
                    "\(summary.unresolvedCount) Apps konnten nicht eindeutig mit einer Website verknüpft werden. Sie liegen jetzt in der Nachbearbeitungsliste."
                )
                .foregroundStyle(.secondary)

                List(store.appsNeedingWebsiteReview) { app in
                    HStack(spacing: 12) {
                        AppIconView(app: app, size: 38, cornerRadius: 9)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                                .fontWeight(.medium)
                            Text("\(app.category) · \(app.subcategory)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("URL ergänzen") {
                            editingApp = app
                        }
                        Button("Nicht mehr fragen") {
                            store.suppressWebsitePrompt(for: app.id)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Websites ergänzen")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schließen") {
                        store.websiteReviewSummary = nil
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 720, minHeight: 520)
        .sheet(item: $editingApp) { app in
            AppEditorView(existingApp: app) { updatedApp in
                store.update(updatedApp)
                if updatedApp.homepage != nil {
                    store.confirmWebsite(
                        updatedApp.homepage!.absoluteString,
                        for: updatedApp.id
                    )
                }
            }
        }
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
                if store.websitePromptExclusions.isEmpty
                    && store.appsNeedingWebsiteReview.isEmpty {
                    ContentUnavailableView(
                        "Keine offenen Websites",
                        systemImage: "checkmark.circle",
                        description: Text(
                            "Aktuell sind keine Apps für eine Website-Nachbearbeitung vorgemerkt."
                        )
                    )
                } else {
                    List(store.appsNeedingWebsiteReview + store.websitePromptExclusions) { app in
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
                            if app.suppressesWebsitePrompt {
                                Button("Wieder fragen") {
                                    store.allowWebsitePrompt(for: app.id)
                                }
                            } else {
                                Button("Nicht mehr fragen") {
                                    store.suppressWebsitePrompt(for: app.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Websites ergänzen")
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
