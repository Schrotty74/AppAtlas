import Foundation

enum AppContextMatcher {
    static func isPlausible(
        category: String,
        subcategory: String,
        candidateText: String
    ) -> Bool {
        let context = normalized("\(category) \(subcategory)")
        let candidate = normalized(candidateText)
        guard !candidate.isEmpty else {
            return true
        }

        for rule in rules where rule.contextTerms.contains(where: context.contains) {
            if rule.conflictingTerms.contains(where: candidate.contains)
                && !rule.supportingTerms.contains(where: candidate.contains)
            {
                return false
            }
        }
        return true
    }

    static func searchHint(category: String, subcategory: String) -> String {
        let context = normalized("\(category) \(subcategory)")
        for rule in rules where rule.contextTerms.contains(where: context.contains) {
            return rule.searchHint
        }
        return ""
    }

    private static let rules: [Rule] = [
        Rule(
            contextTerms: ["grafik", "foto", "bild"],
            supportingTerms: [
                "graphic", "graphics", "design", "photo", "image", "editor",
                "creative", "illustration", "vector", "raw"
            ],
            conflictingTerms: [
                "java", "thread", "cpu", "processor", "concurrency",
                "developer library", "programming library", "framework"
            ],
            searchHint: "graphics design"
        ),
        Rule(
            contextTerms: ["multimedia", "video", "film"],
            supportingTerms: [
                "video", "movie", "media", "film", "editor", "player",
                "encode", "stream"
            ],
            conflictingTerms: [
                "java library", "developer library", "database", "server"
            ],
            searchHint: "video media"
        ),
        Rule(
            contextTerms: ["audio", "musik"],
            supportingTerms: [
                "audio", "music", "sound", "recording", "player", "podcast"
            ],
            conflictingTerms: ["java library", "database", "server"],
            searchHint: "audio music"
        ),
        Rule(
            contextTerms: ["office", "dokument", "pdf", "text"],
            supportingTerms: [
                "document", "office", "pdf", "text", "note", "writing"
            ],
            conflictingTerms: ["game", "java library", "server"],
            searchHint: "document office"
        ),
        Rule(
            contextTerms: ["entwicklung", "developer"],
            supportingTerms: [
                "developer", "code", "programming", "git", "terminal", "ide"
            ],
            conflictingTerms: [],
            searchHint: "developer"
        ),
        Rule(
            contextTerms: ["sicherheit"],
            supportingTerms: [
                "security", "privacy", "password", "firewall", "vpn"
            ],
            conflictingTerms: ["game", "photo editor"],
            searchHint: "security privacy"
        )
    ]

    private static func normalized(_ value: String) -> String {
        value
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .lowercased()
    }

    private struct Rule {
        let contextTerms: [String]
        let supportingTerms: [String]
        let conflictingTerms: [String]
        let searchHint: String
    }
}
