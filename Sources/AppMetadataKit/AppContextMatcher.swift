import Foundation

public enum AppContextMatcher {
    public static func isPlausible(
        category: String,
        subcategory: String,
        candidateText: String
    ) -> Bool {
        compatibilityScore(
            category: category,
            subcategory: subcategory,
            candidateText: candidateText
        ) >= 0.5
    }

    public static func compatibilityScore(
        category: String,
        subcategory: String,
        candidateText: String
    ) -> Double {
        let context = normalized("\(category) \(subcategory)")
        let candidate = normalized(candidateText)
        guard !candidate.isEmpty else {
            return 0.6
        }

        let matchingRules = rules.filter {
            $0.contextTerms.contains(where: context.contains)
        }
        guard !matchingRules.isEmpty else {
            return 0.7
        }
        var best = 0.6
        for rule in matchingRules {
            let supports = rule.supportingTerms.filter(candidate.contains).count
            let conflicts = rule.conflictingTerms.filter(candidate.contains).count
            if conflicts > 0 && supports == 0 {
                return 0
            }
            if supports >= 2 {
                best = max(best, 1)
            } else if supports == 1 {
                best = max(best, 0.85)
            }
        }
        return best
    }

    public static func searchHint(category: String, subcategory: String) -> String {
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
        ),
        Rule(
            contextTerms: ["benchmark"],
            supportingTerms: [
                "benchmark", "performance", "cpu", "gpu", "speed",
                "measure", "stress test"
            ],
            conflictingTerms: [
                "accounting", "calendar", "photo editor", "messaging"
            ],
            searchHint: "benchmark performance"
        ),
        Rule(
            contextTerms: ["screenshot", "screen capture"],
            supportingTerms: [
                "screenshot", "screen capture", "annotation", "record screen",
                "snipping"
            ],
            conflictingTerms: [
                "database", "java library", "audio player", "game"
            ],
            searchHint: "screenshot screen capture"
        ),
        Rule(
            contextTerms: ["browser"],
            supportingTerms: [
                "browser", "web", "internet", "privacy", "tabs"
            ],
            conflictingTerms: [
                "developer library", "photo editor", "audio plugin"
            ],
            searchHint: "web browser"
        ),
        Rule(
            contextTerms: ["kommunikation", "mail", "chat"],
            supportingTerms: [
                "email", "mail", "chat", "message", "communication",
                "telegram", "social"
            ],
            conflictingTerms: [
                "benchmark", "photo editor", "developer library"
            ],
            searchHint: "communication messaging"
        ),
        Rule(
            contextTerms: ["gaming", "spiel"],
            supportingTerms: [
                "game", "gaming", "emulator", "controller", "steam"
            ],
            conflictingTerms: [
                "office", "database", "photo editor", "mail client"
            ],
            searchHint: "game gaming"
        ),
        Rule(
            contextTerms: ["netzwerk", "network", "download"],
            supportingTerms: [
                "network", "download", "transfer", "server", "ftp",
                "cloud", "wifi"
            ],
            conflictingTerms: ["photo editor", "game", "audio plugin"],
            searchHint: "network download"
        ),
        Rule(
            contextTerms: ["system", "hardware"],
            supportingTerms: [
                "system", "hardware", "utility", "monitor", "disk",
                "battery", "display", "maintenance"
            ],
            conflictingTerms: ["game", "photo editor", "mail client"],
            searchHint: "mac system utility"
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
