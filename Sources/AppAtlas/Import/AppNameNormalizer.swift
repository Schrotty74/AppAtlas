import Foundation

enum AppNameNormalizer {
    static func displayName(for fileName: String) -> String {
        let stem = (fileName as NSString).deletingPathExtension
        let stripped = stripVersionAndPackagingTerms(from: stem)
        return stripped
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .joined(separator: " ")
    }

    static func groupingKey(for fileName: String) -> String {
        displayName(for: fileName)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }
    }

    static func catalogIdentityKey(
        name: String,
        category: String,
        subcategory: String
    ) -> String {
        [
            groupingKey(for: name),
            category.normalizedForCatalogSearch,
            subcategory.normalizedForCatalogSearch
        ]
        .joined(separator: "\u{1F}")
    }

    static func detectVersion(in fileName: String) -> String? {
        let stem = (fileName as NSString).deletingPathExtension
        let patterns = [
            #"(?i)(?:^|[\s_-])v?(\d+\.\d+(?:\.\d+){0,2}(?:[-._][a-z0-9]+)?)"#,
            #"(?i)(?:^|[\s_-])(\d{4})(?:[\s_-]|$)"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(
                    in: stem,
                    range: NSRange(stem.startIndex..., in: stem)
                  ),
                  let range = Range(match.range(at: 1), in: stem)
            else {
                continue
            }
            return String(stem[range])
        }
        return nil
    }

    private static func stripVersionAndPackagingTerms(from value: String) -> String {
        let patterns = [
            #"(?i)[\s_-]+v?\d+\.\d+(?:\.\d+){0,2}.*$"#,
            #"(?i)[\s_-]+\d{4}(?:[\s_-].*)?$"#,
            #"(?i)[\s_-]+(?:macos|mac|osx|darwin|installer|universal|arm64|x64|apple[\s_-]*silicon).*$"#
        ]

        return patterns.reduce(value) { result, pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                return result
            }
            return regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }
    }
}
