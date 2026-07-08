import Foundation

public enum AppNameMatcher {
    public static func normalized(_ value: String) -> String {
        let displayName = AppNameNormalizer.displayName(for: value)
        let base = displayName
            .components(separatedBy: CharacterSet(charactersIn: "–:"))
            .first ?? displayName
        return base
            .replacingOccurrences(
                of: #"\s+(?:pro|lite|plus|hd|air|\d+)\s*$"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    public static func searchName(_ value: String) -> String {
        AppNameNormalizer.displayName(for: value)
            .components(separatedBy: CharacterSet(charactersIn: "–:"))
            .first?
            .replacingOccurrences(
                of: #"\s+(?:pro|lite|plus|hd|air|\d+)\s*$"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? value
    }

    public static func similarity(_ lhs: String, _ rhs: String) -> Double {
        let left = Array(normalized(lhs))
        let right = Array(normalized(rhs))
        guard !left.isEmpty, !right.isEmpty else {
            return 0
        }
        if left == right {
            return 1
        }
        if min(left.count, right.count) >= 4 {
            let leftValue = String(left)
            let rightValue = String(right)
            if leftValue.localizedStandardContains(rightValue)
                || rightValue.localizedStandardContains(leftValue)
            {
                let shorter = min(left.count, right.count)
                let longer = max(left.count, right.count)
                return Double(shorter) / Double(longer)
            }
        }

        var previous = Array(0...right.count)
        for (leftIndex, leftCharacter) in left.enumerated() {
            var current = [leftIndex + 1]
            for (rightIndex, rightCharacter) in right.enumerated() {
                current.append(
                    min(
                        current[rightIndex] + 1,
                        previous[rightIndex + 1] + 1,
                        previous[rightIndex]
                            + (leftCharacter == rightCharacter ? 0 : 1)
                    )
                )
            }
            previous = current
        }
        let distance = previous[right.count]
        return 1 - Double(distance) / Double(max(left.count, right.count))
    }

    public static func licenseNormalized(_ value: String) -> String {
        var result = value
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .lowercased()
            .replacingOccurrences(
                of: #"\bfor\s+mac(?:os)?\b"#,
                with: " ",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"\b(?:latest|app|macos|mac|pro|plus|lite|hd|air)\b"#,
                with: " ",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"(?:app|latest)$"#,
                with: "",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(
                of: #"(?<=[a-z])v?\d+(?:[._-]\d+)*$"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"(?:^|[\s._-])v?\d+(?:[\s._-]+\d+)*$"#,
                with: "",
                options: .regularExpression
            )
        result = result.filter { $0.isLetter || $0.isNumber }
        return result
    }

    public static func licenseSimilarity(_ lhs: String, _ rhs: String) -> Double {
        similarityBetweenNormalized(
            licenseNormalized(lhs),
            licenseNormalized(rhs)
        )
    }

    private static func similarityBetweenNormalized(
        _ lhs: String,
        _ rhs: String
    ) -> Double {
        let left = Array(lhs)
        let right = Array(rhs)
        guard !left.isEmpty, !right.isEmpty else {
            return 0
        }
        if left == right {
            return 1
        }
        if min(left.count, right.count) >= 4,
           lhs.localizedStandardContains(rhs)
            || rhs.localizedStandardContains(lhs)
        {
            return Double(min(left.count, right.count))
                / Double(max(left.count, right.count))
        }
        var previous = Array(0...right.count)
        for (leftIndex, leftCharacter) in left.enumerated() {
            var current = [leftIndex + 1]
            for (rightIndex, rightCharacter) in right.enumerated() {
                current.append(
                    min(
                        current[rightIndex] + 1,
                        previous[rightIndex + 1] + 1,
                        previous[rightIndex]
                            + (leftCharacter == rightCharacter ? 0 : 1)
                    )
                )
            }
            previous = current
        }
        return 1 - Double(previous[right.count])
            / Double(max(left.count, right.count))
    }
}
