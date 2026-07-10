import Foundation

enum AIHelpService: String, CaseIterable, Identifiable {
    case chatGPT
    case gemini
    case claude

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chatGPT:
            "ChatGPT"
        case .gemini:
            "Gemini"
        case .claude:
            "Claude"
        }
    }

    var logoResource: (name: String, extension: String) {
        switch self {
        case .chatGPT:
            ("ai-chatgpt-logo", "jpg")
        case .gemini:
            ("ai-gemini-logo", "svg")
        case .claude:
            ("ai-claude-logo", "png")
        }
    }

    var url: URL {
        switch self {
        case .chatGPT:
            URL(string: "https://chatgpt.com/")!
        case .gemini:
            URL(string: "https://gemini.google.com/app")!
        case .claude:
            URL(string: "https://claude.ai/new")!
        }
    }
}

enum AppHelpLinks {
    static let guideURL = URL(
        string: "https://github.com/Schrotty74/AppAtlas/blob/main/guide.md"
    )!

    static let aiPrompt = """
    Ich habe AppAtlas gerade zum ersten Mal geöffnet und mein Katalog ist noch \
    leer. Erkläre mir AppAtlas freundlich und in einfacher Sprache. Führe mich \
    anschließend Schritt für Schritt durch meinen ersten Katalog:

    1. „Ordner scannen“ auswählen.
    2. Einen Ordner mit Apps oder Installationsdateien auswählen.
    3. Das Scan-Ergebnis prüfen und unerwünschte Vorschläge abwählen.
    4. Die ausgewählten Apps mit „Katalog mit … Apps abgleichen“ übernehmen.
    5. Erklären, wie ich Apps suche, kategorisiere und bearbeite.
    6. Erklären, wann „Online-Daten aktualisieren“ sinnvoll ist und dass diese \
    Funktion bewusst gestartet werden muss.
    7. Unsichere Treffer unter „Zu prüfen“ kontrollieren.
    8. Zum Abschluss einen sicheren Katalogexport ohne Lizenzdaten erstellen.

    Erkläre bei jedem Schritt genau, welche Schaltfläche ich anklicken muss, \
    was danach erscheint und worauf ich achten sollte. Weise besonders darauf \
    hin, dass ein erneuter vollständiger Scan nicht mehr vorhandene oder \
    abgewählte lokale Einträge aus dem Katalog entfernen kann. Verwende kurze \
    Abschnitte und frage mich am Ende, bei welchem Schritt ich Hilfe benötige.

    Verweise anschließend auf das offizielle Handbuch: \
    [https://github.com/Schrotty74/AppAtlas/blob/main/guide.md](https://github.com/Schrotty74/AppAtlas/blob/main/guide.md)
    """
}
