import Foundation

actor AppleArtworkLookup {
    static let shared = AppleArtworkLookup()

    struct Metadata: Sendable {
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

    func metadata(
        for app: AppEntry
    ) async -> Metadata? {
        let key = [
            AppNameMatcher.normalized(app.name),
            app.category.lowercased(),
            app.subcategory.lowercased()
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
        components.queryItems = [
            URLQueryItem(name: "term", value: AppNameMatcher.searchName(app.name)),
            URLQueryItem(name: "entity", value: "macSoftware"),
            URLQueryItem(name: "limit", value: "10")
        ]
        guard let url = components.url else {
            misses.insert(key)
            return nil
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 8
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  http.statusCode == 200
            else {
                misses.insert(key)
                return nil
            }
            let result = try JSONDecoder().decode(SearchResult.self, from: data)
            if let confirmed = result.results.first(where: {
                ConfirmedMetadataMatchStore.shared.isConfirmed(
                    appName: app.name,
                    appleTrackID: $0.trackId
                )
                    && !ConfirmedMetadataMatchStore.shared.isRejected(
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
                    && !ConfirmedMetadataMatchStore.shared.isRejected(
                        appName: app.name,
                        appleTrackID: $0.trackId
                    )
            }
            let normalizedAppName = AppNameMatcher.normalized(app.name)
            let ranked = MetadataMatchScorer.ranked(
                app: app,
                candidates: candidates
            ) { result in
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
            .map { candidate, score in
                let normalizedTrackName = AppNameMatcher.normalized(
                    candidate.trackName
                )
                let boostedScore = normalizedTrackName.contains(normalizedAppName)
                    ? score + 0.15
                    : score
                return (candidate: candidate, score: boostedScore)
            }
            .sorted {
                if $0.score == $1.score {
                    return AppNameMatcher.similarity(
                        app.name,
                        $0.candidate.trackName
                    ) > AppNameMatcher.similarity(
                        app.name,
                        $1.candidate.trackName
                    )
                }
                return $0.score > $1.score
            }
            guard let selection = MetadataMatchScorer.result(
                app: app,
                ranked: ranked
            ),
                  selection.match.decision != .reject
            else {
                misses.insert(key)
                return nil
            }
            let match = selection.candidate
            let decision = ConfirmedMetadataMatchStore.shared.isConfirmed(
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

    func artworkURL(for appName: String) async -> URL? {
        await metadata(
            for: AppEntry(
                name: appName,
                category: "",
                subcategory: "",
                files: []
            )
        )?.artworkURL
    }

    private func makeMetadata(
        from result: Result,
        match: MetadataMatchScore
    ) -> Metadata {
        Metadata(
            description: result.description.map {
                String($0.prefix(500))
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
