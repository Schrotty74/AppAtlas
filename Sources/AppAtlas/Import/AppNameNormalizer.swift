import Foundation

enum AppNameNormalizer {
    private static let versionDetectionRegexes: [NSRegularExpression] = [
        #"(?i)(?:^|[\s_-])v?(\d+\.\d+(?:\.\d+){0,2}(?:[-._][a-z0-9]+)?)"#,
        #"(?i)(?:^|[\s_-])(\d{4})(?:[\s_-]|$)"#
    ].compactMap { try? NSRegularExpression(pattern: $0) }

    private static let versionAndPackagingRegexes: [NSRegularExpression] = [
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
    ].compactMap { try? NSRegularExpression(pattern: $0) }

    private static let attachedYearRegex = try? NSRegularExpression(
        pattern: #"(?i)(?<=[a-z])(?:19|20)\d{2}$"#
    )

    private static let trailingAppSuffixRegex = try? NSRegularExpression(
        pattern: #"(?i)[\s._-]+app\s*$"#
    )

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

        for regex in versionDetectionRegexes {
            guard let match = regex.firstMatch(
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
        var regexes = versionAndPackagingRegexes
        if !preservingAttachedYear, let attachedYearRegex {
            regexes.append(attachedYearRegex)
        }

        let stripped = regexes.reduce(value) { result, regex in
            return regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }
        return stripTrailingAppSuffix(from: stripped)
    }

    private static func stripTrailingAppSuffix(from value: String) -> String {
        guard let trailingAppSuffixRegex else {
            return value
        }
        let stripped = trailingAppSuffixRegex.stringByReplacingMatches(
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
