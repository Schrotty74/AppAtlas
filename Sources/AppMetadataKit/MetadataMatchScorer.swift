import Foundation

public enum MetadataMatchDecision: String, Sendable {
    case automatic
    case review
    case reject
}

public struct MetadataMatchScore: Sendable {
    public let value: Double
    public let margin: Double
    public let decision: MetadataMatchDecision

    public init(
        value: Double,
        margin: Double,
        decision: MetadataMatchDecision
    ) {
        self.value = value
        self.margin = margin
        self.decision = decision
    }
}

public struct MetadataMatchCandidate: Sendable {
    public let name: String
    public let contextText: String
    public let developer: String?
    public let url: URL?
    public let bundleIdentifier: String?
    public let sourceReliability: Double

    public init(
        name: String,
        contextText: String,
        developer: String?,
        url: URL?,
        bundleIdentifier: String?,
        sourceReliability: Double
    ) {
        self.name = name
        self.contextText = contextText
        self.developer = developer
        self.url = url
        self.bundleIdentifier = bundleIdentifier
        self.sourceReliability = sourceReliability
    }
}

public enum MetadataMatchScorer {
    public static let automaticThreshold = 0.80
    public static let reviewThreshold = 0.65
    public static let minimumAutomaticMargin = 0.08

    public static func ranked<C>(
        app: any EnrichableApp,
        candidates: [C],
        confirmationProvider: any MetadataConfirmationProviding = EmptyMetadataConfirmationProvider(),
        candidate: (C) -> MetadataMatchCandidate
    ) -> [(candidate: C, score: Double)] {
        candidates
            .map { item in
                (
                    item,
                    score(
                        app: app,
                        candidate: candidate(item),
                        confirmationProvider: confirmationProvider
                    )
                )
            }
            .sorted { $0.1 > $1.1 }
    }

    public static func result<C>(
        app: any EnrichableApp,
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

    public static func score(
        app: any EnrichableApp,
        candidate: MetadataMatchCandidate,
        confirmationProvider: any MetadataConfirmationProviding = EmptyMetadataConfirmationProvider()
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
                subcategory: "",
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
            var domainScore = confirmationProvider
                .domainScore(appName: app.name, candidateURL: url)
            let knownURLs = [app.homepage].compactMap { $0 }
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

        let localBundleIdentifiers = Set(app.bundleIdentifiers)
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
        app: any EnrichableApp,
        candidate: MetadataMatchCandidate
    ) -> Bool {
        guard let candidateBundleIdentifier = candidate
            .bundleIdentifier?
            .nonEmpty?
            .lowercased()
        else {
            return false
        }
        return app.bundleIdentifiers
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

    public static func hasConflictingProductQualifier(
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

    public static func hasConflictingProductQualifier(
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
