import Foundation

actor AppleArtworkLookup {
    static let shared = AppleArtworkLookup()

    struct Metadata: Sendable {
        let description: String?
        let homepage: URL?
        let downloadURL: URL?
        let artworkURL: URL?
    }

    private var cache: [String: Metadata] = [:]
    private var misses: Set<String> = []

    func metadata(
        for appName: String,
        category: String = "",
        subcategory: String = ""
    ) async -> Metadata? {
        let key = [
            AppNameMatcher.normalized(appName),
            category.lowercased(),
            subcategory.lowercased()
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
            URLQueryItem(name: "term", value: AppNameMatcher.searchName(appName)),
            URLQueryItem(name: "entity", value: "macSoftware"),
            URLQueryItem(name: "limit", value: "10")
        ]
        guard let url = components.url else {
            misses.insert(key)
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  http.statusCode == 200
            else {
                misses.insert(key)
                return nil
            }
            let result = try JSONDecoder().decode(SearchResult.self, from: data)
            let candidates = result.results
                .filter {
                    AppContextMatcher.isPlausible(
                        category: category,
                        subcategory: subcategory,
                        candidateText: [
                            $0.primaryGenreName ?? "",
                            $0.genres?.joined(separator: " ") ?? "",
                            $0.description ?? ""
                        ].joined(separator: " ")
                    )
                }
                .map { ($0, AppNameMatcher.similarity(appName, $0.trackName)) }
                .sorted { $0.1 > $1.1 }
            guard let match = candidates.first,
                  match.1 >= 0.8
            else {
                misses.insert(key)
                return nil
            }
            let metadata = Metadata(
                description: match.0.description.map {
                    String($0.prefix(500))
                },
                homepage: match.0.sellerUrl.flatMap(URL.init(string:)),
                downloadURL: URL(string: match.0.trackViewUrl),
                artworkURL: URL(
                    string: match.0.artworkUrl512 ?? match.0.artworkUrl100
                )
            )
            cache[key] = metadata
            return metadata
        } catch {
            misses.insert(key)
            return nil
        }
    }

    func artworkURL(for appName: String) async -> URL? {
        await metadata(for: appName)?.artworkURL
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
    }
}
