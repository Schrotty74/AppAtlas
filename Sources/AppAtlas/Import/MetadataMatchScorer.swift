import Foundation

enum MetadataMatchDecision: String, Sendable {
    case automatic
    case review
    case reject
}

struct MetadataMatchScore: Sendable {
    let value: Double
    let margin: Double
    let decision: MetadataMatchDecision
}

struct MetadataMatchCandidate: Sendable {
    let name: String
    let contextText: String
    let developer: String?
    let url: URL?
    let bundleIdentifier: String?
    let sourceReliability: Double
}

enum MetadataMatchScorer {
    static let automaticThreshold = 0.80
    static let reviewThreshold = 0.65
    static let minimumAutomaticMargin = 0.08

    static func ranked<C>(
        app: AppEntry,
        candidates: [C],
        candidate: (C) -> MetadataMatchCandidate
    ) -> [(candidate: C, score: Double)] {
        candidates
            .map { item in
                (item, score(app: app, candidate: candidate(item)))
            }
            .sorted { $0.1 > $1.1 }
    }

    static func result<C>(
        app: AppEntry,
        ranked: [(candidate: C, score: Double)]
    ) -> (candidate: C, match: MetadataMatchScore)? {
        guard let best = ranked.first else {
            return nil
        }
        let second = ranked.dropFirst().first?.score ?? 0
        let margin = best.score - second
        let decision: MetadataMatchDecision
        if best.score >= automaticThreshold,
           margin >= minimumAutomaticMargin
        {
            decision = .automatic
        } else if best.score >= reviewThreshold {
            decision = .review
        } else {
            decision = .reject
        }
        return (
            best.candidate,
            MetadataMatchScore(
                value: best.score,
                margin: margin,
                decision: decision
            )
        )
    }

    static func score(
        app: AppEntry,
        candidate: MetadataMatchCandidate
    ) -> Double {
        guard !hasConflictingProductQualifier(
            appName: app.name,
            candidateName: candidate.name
        ) else {
            return 0
        }

        var weightedScore = 0.0
        var totalWeight = 0.0

        add(
            AppNameMatcher.similarity(app.name, candidate.name),
            weight: 0.45,
            to: &weightedScore,
            totalWeight: &totalWeight
        )
        add(
            AppContextMatcher.compatibilityScore(
                category: app.category,
                subcategory: app.subcategory,
                candidateText: candidate.contextText
            ),
            weight: 0.20,
            to: &weightedScore,
            totalWeight: &totalWeight
        )

        if let appDeveloper = app.developer?.nonEmpty,
           let candidateDeveloper = candidate.developer?.nonEmpty
        {
            add(
                AppNameMatcher.similarity(
                    appDeveloper,
                    candidateDeveloper
                ),
                weight: 0.10,
                to: &weightedScore,
                totalWeight: &totalWeight
            )
        }

        if let url = candidate.url {
            var domainScore = ConfirmedMetadataMatchStore.shared
                .domainScore(for: app.name, candidateURL: url)
            let knownURLs = [app.homepage, app.githubURL].compactMap { $0 }
            if knownURLs.contains(where: {
                sameDomain($0, url)
            }) {
                domainScore = 1
            }
            if domainScore > 0 {
                add(
                    domainScore,
                    weight: 0.10,
                    to: &weightedScore,
                    totalWeight: &totalWeight
                )
            }
        }

        let localBundleIdentifiers = Set(
            app.files.compactMap(\.bundleIdentifier)
        )
        if let bundleIdentifier = candidate.bundleIdentifier?.nonEmpty,
           !localBundleIdentifiers.isEmpty
        {
            add(
                localBundleIdentifiers.contains(bundleIdentifier) ? 1 : 0,
                weight: 0.10,
                to: &weightedScore,
                totalWeight: &totalWeight
            )
        }

        add(
            min(max(candidate.sourceReliability, 0), 1),
            weight: 0.15,
            to: &weightedScore,
            totalWeight: &totalWeight
        )

        guard totalWeight > 0 else {
            return 0
        }
        var finalScore = weightedScore / totalWeight
        if bundleIdentifierMatches(app: app, candidate: candidate) {
            finalScore += 0.20
        }
        return min(finalScore, 1)
    }

    private static func bundleIdentifierMatches(
        app: AppEntry,
        candidate: MetadataMatchCandidate
    ) -> Bool {
        guard let candidateBundleIdentifier = candidate
            .bundleIdentifier?
            .nonEmpty?
            .lowercased()
        else {
            return false
        }
        return app.files
            .compactMap(\.bundleIdentifier)
            .map { $0.lowercased() }
            .contains(candidateBundleIdentifier)
    }

    private static func add(
        _ value: Double,
        weight: Double,
        to score: inout Double,
        totalWeight: inout Double
    ) {
        score += min(max(value, 0), 1) * weight
        totalWeight += weight
    }

    private static func sameDomain(_ lhs: URL, _ rhs: URL) -> Bool {
        func host(_ url: URL) -> String? {
            guard var value = url.host?.lowercased() else {
                return nil
            }
            if value.hasPrefix("www.") {
                value.removeFirst(4)
            }
            return value
        }
        guard let left = host(lhs), let right = host(rhs) else {
            return false
        }
        return left == right
            || left.hasSuffix(".\(right)")
            || right.hasSuffix(".\(left)")
    }

    static func hasConflictingProductQualifier(
        appName: String,
        candidateName: String
    ) -> Bool {
        let appTokens = Set(productTokens(appName))
        let candidateTokens = Set(productTokens(candidateName))
        guard !appTokens.isEmpty, !candidateTokens.isEmpty else {
            return false
        }

        let conflictingQualifiers = Set([
            "elements",
            "express",
            "reader",
            "classic",
            "lightroom",
            "premiere",
            "illustrator",
            "indesign",
            "acrobat",
            "after",
            "effects"
        ])
        let extraQualifiers = candidateTokens
            .subtracting(appTokens)
            .intersection(conflictingQualifiers)
        return !extraQualifiers.isEmpty
    }

    static func hasConflictingProductQualifier(
        appName: String,
        candidateURL: URL?
    ) -> Bool {
        guard let candidateURL else {
            return false
        }
        let candidateText = [
            candidateURL.host ?? "",
            candidateURL.path
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
        ]
        .joined(separator: " ")
        return hasConflictingProductQualifier(
            appName: appName,
            candidateName: candidateText
        )
    }

    private static func productTokens(_ value: String) -> [String] {
        AppNameNormalizer.displayName(for: value)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .lowercased()
            .replacingOccurrences(
                of: #"[^a-z0-9]+"#,
                with: " ",
                options: .regularExpression
            )
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .filter {
                ![
                    "app",
                    "apps",
                    "apple",
                    "com",
                    "de",
                    "html",
                    "mac",
                    "macos",
                    "ios",
                    "pro",
                    "lite",
                    "plus",
                    "hd",
                    "air",
                    "product",
                    "products",
                    "whats",
                    "new"
                ]
                    .contains($0)
                    && Int($0) == nil
            }
    }
}

private extension String {
    var nonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
