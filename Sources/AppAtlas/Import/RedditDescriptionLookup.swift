import Foundation

actor RedditDescriptionLookup {
    static let shared = RedditDescriptionLookup()

    struct Result: Sendable {
        let description: String
        let sourceURL: URL
    }

    func description(for appName: String) async -> Result? {
        guard var components = URLComponents(
            string: "https://www.reddit.com/r/macapps/search.json"
        ) else {
            return nil
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: AppNameMatcher.searchName(appName)),
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
            return listing.data.children
                .map(\.data)
                .filter {
                    !$0.selftext.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                        && AppNameMatcher.similarity(appName, $0.title) >= 0.8
                }
                .sorted {
                    AppNameMatcher.similarity(appName, $0.title)
                        > AppNameMatcher.similarity(appName, $1.title)
                }
                .first
                .flatMap { post in
                    guard let sourceURL = URL(
                        string: "https://www.reddit.com\(post.permalink)"
                    ) else {
                        return nil
                    }
                    return Result(
                        description: String(post.selftext.prefix(500)),
                        sourceURL: sourceURL
                    )
                }
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
