import SwiftUI

struct AssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme

    @State private var query = ""
    @State private var includeInternet = false
    @State private var isWorking = false
    @State private var answer: AssistantAnswer?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Was möchtest du mit deinen Apps machen?")
                        .font(.title2.bold())
                    Text("Der Assistent prüft zuerst deinen lokalen Katalog. Internet und Reddit werden nur bei aktivierter Option abgefragt.")
                        .foregroundStyle(theme.mutedText)
                }

                HStack {
                    TextField(
                        "Zum Beispiel: Mit welcher App kann ich Videos erstellen?",
                        text: $query
                    )
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(run)

                    Button("Fragen", action: run)
                        .buttonStyle(.borderedProminent)
                        .disabled(trimmedQuery.isEmpty || isWorking)
                }

                Toggle("Internet und Reddit r/macapps sowie r/macos einbeziehen", isOn: $includeInternet)

                if isWorking {
                    ProgressView("Katalog wird geprüft …")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let answer {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Label(answer.engine, systemImage: "brain")
                                .font(.caption)
                                .foregroundStyle(theme.mutedText)

                            Text(answer.text)
                                .font(.title3)
                                .textSelection(.enabled)

                            if !answer.recommendations.isEmpty {
                                Divider()
                                Text("Passende Apps")
                                    .font(.headline)
                                ForEach(answer.recommendations) { recommendation in
                                    Button {
                                        store.selectedAppID = recommendation.appID
                                        dismiss()
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(recommendation.appName)
                                                    .fontWeight(.semibold)
                                                Text(recommendation.reason)
                                                    .font(.caption)
                                                    .foregroundStyle(theme.mutedText)
                                            }
                                            Spacer()
                                            Image(systemName: "arrow.right")
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .padding(12)
                                    .themedPanel(cornerRadius: 12)
                                }
                            }

                            if !answer.sources.isEmpty {
                                Divider()
                                Text("Externe Meinungen")
                                    .font(.headline)
                                Text("Reddit-Beiträge können subjektiv, veraltet oder ungenau sein.")
                                    .font(.caption)
                                    .foregroundStyle(theme.mutedText)
                                ForEach(answer.sources) { source in
                                    Link(destination: source.url) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(source.title)
                                            Text(source.origin)
                                                .font(.caption)
                                                .foregroundStyle(theme.mutedText)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ContentUnavailableView(
                        "Noch keine Frage",
                        systemImage: "sparkles",
                        description: Text("Frage nach Aufgaben wie Videoschnitt, Screenshots, Audio oder Backups.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(24)
            .background(AppAtlasBackground())
            .foregroundStyle(theme.text)
            .navigationTitle("App-Assistent")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 720, minHeight: 620)
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func run() {
        guard !trimmedQuery.isEmpty, !isWorking else {
            return
        }
        isWorking = true
        answer = nil

        Task {
            let result = await CatalogAssistant().answer(
                query: trimmedQuery,
                apps: store.apps,
                includeInternet: includeInternet
            )
            answer = result
            isWorking = false
        }
    }
}
