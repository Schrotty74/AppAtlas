import Foundation

public actor AppleArtworkLookup {
    public static let shared = AppleArtworkLookup()
    private let confirmationProvider: any MetadataConfirmationProviding

    public init(
        confirmationProvider: any MetadataConfirmationProviding =
            EmptyMetadataConfirmationProvider()
    ) {
        self.confirmationProvider = confirmationProvider
    }

    public struct Metadata: Sendable {
        let description: String?
        let homepage: URL?
        let downloadURL: URL?
        let artworkURL: URL?
        let developer: String?
        let bundleIdentifier: String?
        let trackID: Int
        let match: MetadataMatchScore

        init(
            description: String?,
            homepage: URL?,
            downloadURL: URL?,
            artworkURL: URL?,
            developer: String? = nil,
            bundleIdentifier: String? = nil,
            trackID: Int = 0,
            match: MetadataMatchScore = MetadataMatchScore(
                value: 1,
                margin: 1,
                decision: .automatic
            )
        ) {
            self.description = description
            self.homepage = homepage
            self.downloadURL = downloadURL
            self.artworkURL = artworkURL
            self.developer = developer
            self.bundleIdentifier = bundleIdentifier
            self.trackID = trackID
            self.match = match
        }
    }

    private var cache: [String: Metadata] = [:]
    private var misses: Set<String> = []

    public func metadata(
        for app: any EnrichableApp
    ) async -> Metadata? {
        let key = [
            AppNameMatcher.normalized(app.name),
            app.category.lowercased(),
            ""
        ].joined(separator: "|")
        if let cached = cache[key] {
            return cached
        }
        if misses.contains(key) {
            return nil
        }

        guard var components = URLComponents(
            string: "https://itunes.apple.com/search"
        ) else {
            misses.insert(key)
            return nil
        }
        let searchTerm = AppNameMatcher.searchName(app.name)
        components.queryItems = [
            URLQueryItem(name: "term", value: searchTerm),
            URLQueryItem(name: "entity", value: "macSoftware"),
            URLQueryItem(name: "limit", value: "10")
        ]
        guard let url = components.url else {
            misses.insert(key)
            return nil
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  http.statusCode == 200
            else {
                misses.insert(key)
                return nil
            }
            let result = try JSONDecoder().decode(SearchResult.self, from: data)
            if let confirmed = result.results.first(where: {
                confirmationProvider.isConfirmed(
                    appName: app.name,
                    appleTrackID: $0.trackId
                )
                    && !confirmationProvider.isRejected(
                        appName: app.name,
                        appleTrackID: $0.trackId
                    )
            }) {
                let metadata = makeMetadata(
                    from: confirmed,
                    match: MetadataMatchScore(
                        value: 1,
                        margin: 1,
                        decision: .automatic
                    )
                )
                cache[key] = metadata
                return metadata
            }
            let candidates = result.results.filter {
                !MetadataMatchScorer.hasConflictingProductQualifier(
                    appName: app.name,
                    candidateName: $0.trackName
                )
                    && !confirmationProvider.isRejected(
                        appName: app.name,
                        appleTrackID: $0.trackId
                    )
            }
            let normalizedAppName = AppNameMatcher.normalized(app.name)
            let ranked = MetadataMatchScorer.ranked(
                app: app,
                candidates: Array(candidates.enumerated()),
                confirmationProvider: confirmationProvider
            ) { _, result in
                MetadataMatchCandidate(
                    name: result.trackName,
                    contextText: [
                        result.primaryGenreName ?? "",
                        result.genres?.joined(separator: " ") ?? "",
                        result.description ?? ""
                    ].joined(separator: " "),
                    developer: result.sellerName,
                    url: result.sellerUrl.flatMap(URL.init(string:)),
                    bundleIdentifier: result.bundleId,
                    sourceReliability: 0.95
                )
            }
            .map { indexedCandidate, score in
                let candidate = indexedCandidate.element
                let normalizedTrackName = AppNameMatcher.normalized(
                    candidate.trackName
                )
                let boostedScore = if normalizedTrackName == normalizedAppName {
                    score + 0.40
                } else if normalizedTrackName.contains(normalizedAppName) {
                    score + 0.30
                } else {
                    score
                }
                return (
                    candidate: candidate,
                    score: boostedScore,
                    originalIndex: indexedCandidate.offset,
                    exactTrackNameMatch: normalizedTrackName == normalizedAppName,
                    sourceReliability: 0.95
                )
            }
            .sorted {
                if $0.score == $1.score {
                    if $0.exactTrackNameMatch != $1.exactTrackNameMatch {
                        return $0.exactTrackNameMatch
                    }
                    if $0.sourceReliability != $1.sourceReliability {
                        return $0.sourceReliability > $1.sourceReliability
                    }
                    return $0.originalIndex < $1.originalIndex
                }
                return $0.score > $1.score
            }
            guard let selection = MetadataMatchScorer.result(
                app: app,
                ranked: ranked.map {
                    (candidate: $0.candidate, score: $0.score)
                }
            ),
                  selection.match.decision != .reject
            else {
                misses.insert(key)
                return nil
            }
            let match = selection.candidate
            let decision = confirmationProvider.isConfirmed(
                appName: app.name,
                appleTrackID: match.trackId
            )
                ? MetadataMatchScore(
                    value: 1,
                    margin: 1,
                    decision: .automatic
                )
                : selection.match
            let metadata = makeMetadata(from: match, match: decision)
            cache[key] = metadata
            return metadata
        } catch {
            misses.insert(key)
            return nil
        }
    }

    public func artworkURL(for appName: String) async -> URL? {
        await metadata(
            for: BasicEnrichableApp(
                name: appName,
                category: ""
            )
        )?.artworkURL
    }

    private func makeMetadata(
        from result: Result,
        match: MetadataMatchScore
    ) -> Metadata {
        Metadata(
            description: result.description.map {
                String($0.prefix(3000))
            },
            homepage: result.sellerUrl.flatMap(URL.init(string:))
                ?? fallbackHomepage(from: result.trackViewUrl),
            downloadURL: URL(string: result.trackViewUrl),
            artworkURL: URL(
                string: result.artworkUrl512 ?? result.artworkUrl100
            ),
            developer: result.sellerName,
            bundleIdentifier: result.bundleId,
            trackID: result.trackId,
            match: match
        )
    }

    private func fallbackHomepage(from trackViewUrl: String) -> URL? {
        guard var components = URLComponents(string: trackViewUrl) else {
            return nil
        }
        components.queryItems = nil
        components.fragment = nil
        return components.url
    }

    private struct SearchResult: Decodable {
        let results: [Result]
    }

    private struct Result: Decodable {
        let trackName: String
        let artworkUrl100: String
        let artworkUrl512: String?
        let description: String?
        let sellerUrl: String?
        let trackViewUrl: String
        let primaryGenreName: String?
        let genres: [String]?
        let sellerName: String?
        let bundleId: String?
        let trackId: Int
    }
}
