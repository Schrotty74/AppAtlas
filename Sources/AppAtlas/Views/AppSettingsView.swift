import AppKit
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
    @AppStorage(ScannerSettings.excludedDirectoriesKey)
    private var excludedDirectoriesRaw = ""
    @AppStorage(ScannerSettings.excludedFileExtensionsKey)
    private var excludedFileExtensionsRaw = ""
    @State private var showExtendedSearchInfo = false
    @State private var newExcludedDirectory = ""
    @State private var newExcludedFileExtension = ""
    @State private var excludedFolderPaths =
        ScannerSettings.excludedFolderDisplayPaths
    @State private var scannerErrorMessage: String?

    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("Allgemein", systemImage: "gearshape")
                }

            scannerSettings
                .tabItem {
                    Label("Scanner", systemImage: "folder.badge.gearshape")
                }
        }
        .padding(12)
        .frame(width: 580, height: 650)
        .sheet(isPresented: $showExtendedSearchInfo) {
            ExtendedOnlineSearchInfoView()
        }
        .alert(
            "Ordner konnte nicht übernommen werden",
            isPresented: Binding(
                get: { scannerErrorMessage != nil },
                set: { if !$0 { scannerErrorMessage = nil } }
            )
        ) {
            Button("OK") {
                scannerErrorMessage = nil
            }
        } message: {
            Text(scannerErrorMessage ?? "")
        }
    }

    private var generalSettings: some View {
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
    }

    private var scannerSettings: some View {
        Form {
            Section("Scanner-Ausschlussordner") {
                Button("Ordner auswählen …") {
                    chooseExcludedDirectories()
                }

                if excludedFolderPaths.isEmpty {
                    Text("Keine lokalen Ordner ausgewählt.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(excludedFolderPaths, id: \.self) { path in
                        HStack {
                            Image(systemName: "folder.badge.minus")
                            Text(path)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button {
                                removeSelectedExcludedFolder(path)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                            .help("Ausschlussordner entfernen")
                        }
                    }
                }

                Text(
                    "Die ausgewählten lokalen Ordner werden unabhängig von "
                        + "der Scanquelle ausgelassen. Die Auswahl bleibt "
                        + "ausschließlich lokal auf diesem Mac gespeichert."
                )
                .foregroundStyle(.secondary)

                Divider()

                HStack {
                    TextField(
                        "Ordnername oder relativer Pfad",
                        text: $newExcludedDirectory
                    )
                    Button("Hinzufügen") {
                        addExcludedDirectory()
                    }
                }

                if excludedDirectories.isEmpty {
                    Text("Keine zusätzlichen Ausschlussordner.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(excludedDirectories, id: \.self) { directory in
                        HStack {
                            Image(systemName: "folder.badge.minus")
                            Text(directory)
                            Spacer()
                            Button {
                                removeExcludedDirectory(directory)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                            .help("Ausschlussordner entfernen")
                        }
                    }
                }

                Text(
                    "Ein Ordnername gilt in jeder Ebene. Ein relativer Pfad "
                        + "wie „Kategorie/Archiv“ gilt nur für diesen Pfad. "
                        + "Die Änderung wird beim nächsten Scan angewendet."
                )
                .foregroundStyle(.secondary)
            }

            Section("Ausgeschlossene Dateiendungen") {
                HStack {
                    TextField(
                        "Dateiendung, zum Beispiel ISO",
                        text: $newExcludedFileExtension
                    )
                    Button("Hinzufügen") {
                        addExcludedFileExtension()
                    }
                }

                if excludedFileExtensions.isEmpty {
                    Text("Keine Dateiendungen ausgeschlossen.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(excludedFileExtensions, id: \.self) { fileExtension in
                        HStack {
                            Image(systemName: "doc.badge.minus")
                            Text(".\(fileExtension)")
                            Spacer()
                            Button {
                                removeExcludedFileExtension(fileExtension)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                            .help("Dateiendung wieder zulassen")
                        }
                    }
                }

                Text(
                    "Ausgeschlossene Dateitypen werden beim nächsten Scan "
                        + "nicht in den Katalog aufgenommen. Eingaben mit und "
                        + "ohne Punkt werden gleich behandelt."
                )
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
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

    private var excludedDirectories: [String] {
        ScannerSettings.parse(excludedDirectoriesRaw)
    }

    private var excludedFileExtensions: [String] {
        ScannerSettings.parseFileExtensions(excludedFileExtensionsRaw)
    }

    private var normalizedNewFileExtension: String? {
        ScannerSettings.parseFileExtensions(newExcludedFileExtension).first
    }

    private func addExcludedDirectory() {
        let value = newExcludedDirectory.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !value.isEmpty else {
            scannerErrorMessage =
                "Gib einen Ordnernamen ein oder wähle den Ordner aus."
            return
        }
        excludedDirectoriesRaw = ScannerSettings.encode(
            excludedDirectories + [value]
        )
        newExcludedDirectory = ""
    }

    private func removeExcludedDirectory(_ directory: String) {
        excludedDirectoriesRaw = ScannerSettings.encode(
            excludedDirectories.filter { $0 != directory }
        )
    }

    private func chooseExcludedDirectories() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Ausschließen"
        panel.message =
            "Wähle einen oder mehrere lokale Ordner, die nie gescannt werden sollen."

        guard panel.runModal() == .OK else {
            return
        }

        do {
            for url in panel.urls {
                try ScannerSettings.addExcludedFolder(url)
            }
            excludedFolderPaths =
                ScannerSettings.excludedFolderDisplayPaths
        } catch {
            scannerErrorMessage =
                "Der lokale Ausschlussordner konnte nicht gespeichert werden: "
                + error.localizedDescription
        }
    }

    private func removeSelectedExcludedFolder(_ path: String) {
        ScannerSettings.removeExcludedFolder(displayPath: path)
        excludedFolderPaths = ScannerSettings.excludedFolderDisplayPaths
    }

    private func addExcludedFileExtension() {
        guard let fileExtension = normalizedNewFileExtension else {
            scannerErrorMessage =
                "Gib eine gültige Dateiendung wie ISO oder .ISO ein."
            return
        }
        excludedFileExtensionsRaw = ScannerSettings.encodeFileExtensions(
            excludedFileExtensions + [fileExtension]
        )
        newExcludedFileExtension = ""
    }

    private func removeExcludedFileExtension(_ fileExtension: String) {
        excludedFileExtensionsRaw = ScannerSettings.encodeFileExtensions(
            excludedFileExtensions.filter { $0 != fileExtension }
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
