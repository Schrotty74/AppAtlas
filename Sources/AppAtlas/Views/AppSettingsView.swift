import SwiftUI

enum OnlineUpdateSettings {
    static let concurrencyKey = "onlineUpdateConcurrency"
    static let performanceKey = "onlineUpdatePerformance"
    static let extendedSearchKey = "onlineUpdateExtendedSearch"
    static let defaultConcurrency = 3

    static var currentConcurrency: Int {
        let stored = UserDefaults.standard.integer(forKey: concurrencyKey)
        return sanitized(stored == 0 ? defaultConcurrency : stored)
    }

    static func sanitized(_ value: Int) -> Int {
        min(max(value, 1), 5)
    }

    static var extendedSearchEnabled: Bool {
        UserDefaults.standard.bool(forKey: extendedSearchKey)
    }
}

struct OnlineUpdatePerformance: Codable, Sendable {
    let measuredAt: Date
    let concurrency: Int
    let appCount: Int
    let duration: TimeInterval
    let averageCPUPercent: Double

    static var latest: OnlineUpdatePerformance? {
        guard let data = UserDefaults.standard.data(
            forKey: OnlineUpdateSettings.performanceKey
        ) else {
            return nil
        }
        return try? JSONDecoder().decode(Self.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else {
            return
        }
        UserDefaults.standard.set(data, forKey: OnlineUpdateSettings.performanceKey)
    }
}

struct AppSettingsView: View {
    @AppStorage(AppLanguageChoice.storageKey)
    private var languageChoice = AppLanguageChoice.automatic.rawValue
    @AppStorage(OnlineUpdateSettings.concurrencyKey)
    private var concurrency = OnlineUpdateSettings.defaultConcurrency
    @AppStorage(OnlineUpdateSettings.performanceKey)
    private var performanceData = Data()
    @AppStorage(OnlineUpdateSettings.extendedSearchKey)
    private var extendedSearch = false
    @State private var showExtendedSearchInfo = false

    var body: some View {
        Form {
            Section("Sprache") {
                Picker("App-Sprache", selection: $languageChoice) {
                    ForEach(AppLanguageChoice.allCases) { language in
                        Text(LocalizedStringKey(language.title))
                            .tag(language.rawValue)
                    }
                }
                Text(
                    "Automatisch verwendet Deutsch in Deutschland, Österreich, der Schweiz und Liechtenstein. In allen anderen Regionen wird Englisch verwendet."
                )
                .foregroundStyle(.secondary)
            }

            Section("Online-Daten aktualisieren") {
                Picker(
                    "Gleichzeitig bearbeitete Apps",
                    selection: $concurrency
                ) {
                    ForEach(1...5, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.segmented)

                Text(explanation)
                    .foregroundStyle(.secondary)

                if concurrency >= 4 {
                    Label(
                        "Vier oder fünf gleichzeitige Apps können mehr "
                            + "Bandbreite und Systemleistung. Onlinedienste "
                            + "können viele Anfragen außerdem zeitweise begrenzen.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .foregroundStyle(.orange)
                }

                HStack {
                    Toggle("Erweiterte Online-Suche", isOn: $extendedSearch)
                    Button {
                        showExtendedSearchInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .buttonStyle(.plain)
                    .help("Informationen zur erweiterten Online-Suche")
                }

                if extendedSearch {
                    Text(
                        "Die erweiterte Suche kann deutlich länger dauern, "
                            + "besonders bei großen Katalogen."
                    )
                    .foregroundStyle(.orange)
                }
            }

            if let performance {
                Section("Letzte Messung") {
                    LabeledContent(
                        "Einstellung",
                        value: "\(performance.concurrency) gleichzeitig"
                    )
                    LabeledContent(
                        "Bearbeitete Apps",
                        value: "\(performance.appCount)"
                    )
                    LabeledContent(
                        "Dauer",
                        value: durationText(performance.duration)
                    )
                    LabeledContent(
                        "CPU-Durchschnitt von AppAtlas",
                        value: performance.averageCPUPercent.formatted(
                            .number.precision(.fractionLength(1))
                        ) + " %"
                    )
                    Text(
                        "Die CPU-Messung betrifft nur AppAtlas. Bandbreite, "
                            + "Servergeschwindigkeit und andere laufende Apps "
                            + "beeinflussen die Dauer zusätzlich."
                    )
                    .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 500)
        .sheet(isPresented: $showExtendedSearchInfo) {
            ExtendedOnlineSearchInfoView()
        }
    }

    private var explanation: String {
        switch concurrency {
        case 1:
            "Geeignet für langsame oder instabile Internetverbindungen."
        case 2, 3:
            "Ausgewogene Einstellung für Geschwindigkeit und Bandbreite."
        default:
            "Schneller bei leistungsfähiger Verbindung, benötigt aber mehr Ressourcen."
        }
    }

    private var performance: OnlineUpdatePerformance? {
        try? JSONDecoder().decode(
            OnlineUpdatePerformance.self,
            from: performanceData
        )
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let seconds = max(Int(duration.rounded()), 0)
        let minutes = seconds / 60
        let remainder = seconds % 60
        return minutes > 0 ? "\(minutes) min \(remainder) s" : "\(remainder) s"
    }
}

private struct ExtendedOnlineSearchInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Erweiterte Online-Suche")
                .font(.title2.bold())
            Text(
                "Nach dem schnellen Durchlauf werden nur weiterhin "
                    + "unvollständige Apps zusätzlich geprüft."
            )
            Label(
                "GitHub wird nach Projektinformationen, Beschreibungen, "
                    + "Download-Seiten und möglichen App-Icons durchsucht.",
                systemImage: "chevron.left.forwardslash.chevron.right"
            )
            Label(
                "DuckDuckGo sucht nach einer möglichen offiziellen "
                    + "Herstellerseite.",
                systemImage: "globe"
            )
            Label(
                "Reddit r/macapps wird als subjektive Quelle für fehlende "
                    + "Beschreibungen geprüft.",
                systemImage: "text.bubble"
            )
            Text(
                "Diese zusätzlichen Netzabfragen können die Aktualisierung "
                    + "bei großen Katalogen erheblich verlängern. Vorschläge "
                    + "mit unsicherer Zuordnung müssen weiterhin bestätigt werden."
            )
            .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Schließen") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 540)
    }
}
