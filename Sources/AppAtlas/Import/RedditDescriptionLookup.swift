import Foundation

actor RedditDescriptionLookup {
    static let shared = RedditDescriptionLookup()

    struct Result: Sendable {
        let description: String
        let sourceURL: URL
    }

    func description(for app: AppEntry) async -> Result? {
        guard var components = URLComponents(
            string: "https://www.reddit.com/r/macapps/search.json"
        ) else {
            return nil
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: AppNameMatcher.searchName(app.name)),
            URLQueryItem(name: "restrict_sr", value: "1"),
            URLQueryItem(name: "sort", value: "relevance"),
            URLQueryItem(name: "limit", value: "5")
        ]
        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue(
            "AppAtlas/0.1 (manual private catalog update)",
            forHTTPHeaderField: "User-Agent"
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  http.statusCode == 200,
                  let listing = try? JSONDecoder().decode(Listing.self, from: data)
            else {
                return nil
            }
            let candidates = listing.data.children
                .map(\.data)
                .filter {
                    !$0.selftext.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                }
            let ranked = MetadataMatchScorer.ranked(
                app: app,
                candidates: candidates
            ) { post in
                MetadataMatchCandidate(
                    name: post.title,
                    contextText: "\(post.title) \(post.selftext)",
                    developer: nil,
                    url: URL(
                        string: "https://www.reddit.com\(post.permalink)"
                    ),
                    bundleIdentifier: nil,
                    sourceReliability: 0.55
                )
            }
            guard let selection = MetadataMatchScorer.result(
                app: app,
                ranked: ranked
            ),
                  selection.match.decision != .reject,
                  let sourceURL = URL(
                    string: "https://www.reddit.com"
                        + selection.candidate.permalink
                  )
            else {
                return nil
            }
            return Result(
                description: String(
                    selection.candidate.selftext.prefix(500)
                ),
                sourceURL: sourceURL
            )
        } catch {
            return nil
        }
    }

    private struct Listing: Decodable {
        let data: ListingData
    }

    private struct ListingData: Decodable {
        let children: [Child]
    }

    private struct Child: Decodable {
        let data: Post
    }

    private struct Post: Decodable {
        let title: String
        let selftext: String
        let permalink: String
    }
}
