import Foundation

struct AppMetadataEnricher: Sendable {
    static func isPlaceholderDescription(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            || trimmed.contains("Metadaten und Beschreibung müssen")
            || trimmed.contains("wurde dem Bereich")
            || trimmed.contains("Herstellerangaben, offizielle Links")
            || trimmed.contains("genaue Produktfunktion wird noch")
            || trimmed.contains("Sie dient zum Anzeigen, Bearbeiten")
            || trimmed.contains(
                "Beschreibung und offizielle Links können lokal ergänzt"
            )
    }

    static func isPlaceholderSummary(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            || trimmed == "Aus einem lokalen App-Bestand importiert."
            || trimmed.contains("ist eine Anwendung für")
            || trimmed.contains("ist ein Werkzeug für")
    }

    static func needsDescriptionExpansion(_ text: String) -> Bool {
        isPlaceholderDescription(text)
            || (
                text.count < 220
                    && !text.contains("Typische Funktionen:")
            )
    }

    static func expandedDescription(
        sourceText: String,
        category: String,
        subcategory: String,
        keywords: [String]
    ) -> String {
        let cleaned = sourceText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            return cleaned
        }
        let hints = functionHints(
            category: category,
            subcategory: subcategory,
            keywords: keywords,
            sourceText: cleaned
        )
        guard !hints.isEmpty else {
            return String(cleaned.prefix(900))
        }
        return String(cleaned.prefix(900))
            + "\n\nTypische Funktionen:\n"
            + hints.prefix(4).map { "• \($0)" }.joined(separator: "\n")
    }

    static func summary(from sourceText: String) -> String {
        let cleaned = sourceText
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let firstSentence = cleaned.split(
            separator: ".",
            maxSplits: 1
        ).first.map(String.init) ?? cleaned
        return String(firstSentence.prefix(180))
    }

    func enrich(_ app: AppEntry) -> AppEntry {
        var result = app
        if result.summary.isEmpty
            || result.summary == "Aus einem lokalen App-Bestand importiert."
        {
            result.summary = summary(
                name: result.name,
                category: result.category,
                subcategory: result.subcategory,
                fileTypes: result.keywords
            )
        }
        if Self.isPlaceholderDescription(result.details) {
            result.details = details(
                name: result.name,
                category: result.category,
                subcategory: result.subcategory,
                fileTypes: result.keywords
            )
        }
        return result
    }

    func enrich(_ apps: [AppEntry]) -> [AppEntry] {
        apps.map(enrich)
    }

    func summary(
        name: String,
        category: String,
        subcategory: String,
        fileTypes: [String]
    ) -> String {
        "\(name) ist eine Anwendung aus \(categoryDescription(category, subcategory))."
    }

    func details(
        name: String,
        category: String,
        subcategory: String,
        fileTypes: [String]
    ) -> String {
        "\(summary(name: name, category: category, subcategory: subcategory, fileTypes: fileTypes)) Beschreibung und offizielle Links können lokal ergänzt oder online verifiziert werden."
    }

    private func categoryDescription(
        _ category: String,
        _ subcategory: String
    ) -> String {
        let value = [category, subcategory]
            .filter { !$0.isEmpty }
            .joined(separator: " / ")
        return value.isEmpty ? "dem lokalen Katalog" : "dem Bereich \(value)"
    }

    private static func functionHints(
        category: String,
        subcategory: String,
        keywords: [String],
        sourceText: String
    ) -> [String] {
        let value = ([category, subcategory] + keywords + [sourceText])
            .joined(separator: " ")
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .lowercased()
        let groups: [([String], [String])] = [
            (
                ["foto", "bild", "grafik", "image", "photo", "raw"],
                [
                    "Bilder anzeigen, organisieren oder bearbeiten",
                    "Visuelle Inhalte optimieren und exportieren"
                ]
            ),
            (
                ["video", "film"],
                [
                    "Videos anzeigen, bearbeiten oder konvertieren",
                    "Videodateien exportieren und weiterverarbeiten"
                ]
            ),
            (
                ["audio", "musik"],
                [
                    "Audioinhalte wiedergeben, bearbeiten oder verwalten",
                    "Audiodateien organisieren oder exportieren"
                ]
            ),
            (
                ["messenger", "kommunikation", "telegram", "chat"],
                [
                    "Nachrichten und Unterhaltungen verwalten",
                    "Dateien und Medien austauschen"
                ]
            ),
            (
                ["backup", "sicherung"],
                [
                    "Daten sichern und wiederherstellen",
                    "Sicherungsstände verwalten"
                ]
            ),
            (
                ["system", "hardware", "treiber", "utility", "werkzeug"],
                [
                    "macOS-Funktionen überwachen oder konfigurieren",
                    "Wiederkehrende Verwaltungsaufgaben vereinfachen"
                ]
            ),
            (
                ["entwicklung", "developer", "code", "programmierung"],
                [
                    "Softwareprojekte erstellen, bearbeiten oder prüfen",
                    "Entwicklungsabläufe und technische Aufgaben unterstützen"
                ]
            ),
            (
                ["office", "text", "dokument", "pdf", "notiz"],
                [
                    "Dokumente oder Notizen erstellen und bearbeiten",
                    "Inhalte organisieren, durchsuchen oder exportieren"
                ]
            ),
            (
                ["browser", "internet", "web"],
                [
                    "Webseiten und Onlineinhalte öffnen",
                    "Internetrecherche und webbasierte Arbeitsabläufe unterstützen"
                ]
            ),
            (
                ["netzwerk", "network", "cloud", "remote"],
                [
                    "Netzwerk- oder Cloudverbindungen verwalten",
                    "Daten zwischen Geräten oder Diensten übertragen"
                ]
            ),
            (
                ["sicherheit", "security", "passwort", "privacy"],
                [
                    "Daten, Konten oder Verbindungen schützen",
                    "Sicherheitseinstellungen kontrollieren und verwalten"
                ]
            ),
            (
                ["download", "transfer", "sync", "synchron"],
                [
                    "Dateien herunterladen, übertragen oder synchronisieren",
                    "Übertragungen organisieren und kontrollieren"
                ]
            )
        ]
        var result: [String] = []
        for (terms, hints) in groups where terms.contains(where: value.contains) {
            for hint in hints where !result.contains(hint) {
                result.append(hint)
            }
        }
        return result
    }
}
