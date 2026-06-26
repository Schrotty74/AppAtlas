import Foundation

enum AppNameNormalizer {
    static func displayName(for fileName: String) -> String {
        displayName(for: fileName, preservingAttachedYear: false)
    }

    static func localCatalogDisplayName(for fileName: String) -> String {
        displayName(for: fileName, preservingAttachedYear: true)
    }

    private static func displayName(
        for fileName: String,
        preservingAttachedYear: Bool
    ) -> String {
        let stem = stripKnownFileExtensions(from: fileName)
            .replacingOccurrences(of: "_", with: " ")
        let stripped = stripVersionAndPackagingTerms(
            from: stem,
            preservingAttachedYear: preservingAttachedYear
        )
        return stripped
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

    static func localCatalogGroupingKey(for fileName: String) -> String {
        localCatalogDisplayName(for: fileName)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }
    }

    static func catalogIdentityKey(
        name: String,
        category: String,
        subcategory: String,
        preservesAttachedYear: Bool = false
    ) -> String {
        [
            preservesAttachedYear
                ? localCatalogGroupingKey(for: name)
                : groupingKey(for: name),
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

    private static func stripVersionAndPackagingTerms(
        from value: String,
        preservingAttachedYear: Bool = false
    ) -> String {
        var patterns = [
            #"(?i)^\s*\d{1,3}[\s._-]+(?=[a-z])"#,
            #"(?i)\s*\([^)]*(?:mac|macos|arm64|x64|intel|apple\s*silicon)[^)]*\)\s*$"#,
            #"(?i)\s*\[[^]]*(?:mac|macos|arm64|x64|intel|apple\s*silicon)[^]]*\]\s*$"#,
            #"(?i)(^|[\s._-]+)latest(?=$|[\s._-]+)"#,
            #"(?i)[\s._-]+v$"#,
            #"(?i)[\s._-]+versions?$"#,
            #"(?i)[\s_-]+v?\d+\.\d+(?:\.\d+){0,2}.*$"#,
            #"(?i)[\s_-]+\d{4}(?:[\s_-].*)?$"#,
            #"(?i)[\s._-]+\d{6,}.*$"#,
            #"(?i)[\s._-]+(?:aarch64|arm64|x86[\s._-]*64|x86|x64).*$"#,
            #"(?i)(?<=[a-z])\d+(?:[\s._-]+[a-z]*\d+[a-z0-9]*)+$"#,
            #"(?i)[\s._-]+[a-z]*\d+[a-z0-9]*(?:[\s._-]+[a-z]*\d+[a-z0-9]*)*$"#,
            #"(?i)[\s._-]+(?:aio|setup|installer|install|release|macos|mac|osx|darwin|universal|aarch64|arm64|x86[\s._-]*64|x86|x64|apple[\s._-]*silicon).*$"#
        ]
        if !preservingAttachedYear {
            patterns.append(#"(?i)(?<=[a-z])(?:19|20)\d{2}$"#)
        }

        let stripped = patterns.reduce(value) { result, pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                return result
            }
            return regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }
        return stripTrailingAppSuffix(from: stripped)
    }

    private static func stripTrailingAppSuffix(from value: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: #"(?i)[\s._-]+app\s*$"#
        ) else {
            return value
        }
        let stripped = regex.stringByReplacingMatches(
            in: value,
            range: NSRange(value.startIndex..., in: value),
            withTemplate: ""
        )
        let meaningfulCharacters = stripped.filter {
            $0.isLetter || $0.isNumber
        }
        return meaningfulCharacters.count >= 3 ? stripped : value
    }

    private static func stripKnownFileExtensions(from value: String) -> String {
        var result = value
        let extensions = ["app", "dmg", "zip", "pkg", "iso", "apk", "exe"]
        while !((result as NSString).pathExtension.isEmpty) {
            let fileExtension = (result as NSString)
                .pathExtension
                .lowercased()
            guard extensions.contains(fileExtension) else {
                break
            }
            result = (result as NSString).deletingPathExtension
        }
        return result
    }
}
