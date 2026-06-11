import Foundation

enum AppNameMatcher {
    static func normalized(_ value: String) -> String {
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

    static func searchName(_ value: String) -> String {
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

    static func similarity(_ lhs: String, _ rhs: String) -> Double {
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
}
