import Foundation

public actor GitHubRepositoryLookup {
    public static let shared = GitHubRepositoryLookup()
    private let confirmationProvider: any MetadataConfirmationProviding

    public init(
        confirmationProvider: any MetadataConfirmationProviding =
            EmptyMetadataConfirmationProvider()
    ) {
        self.confirmationProvider = confirmationProvider
    }

    public struct Metadata: Sendable {
        let description: String?
        let iconData: Data?
        let projectURL: URL
        let homepageURL: URL?
        let downloadURL: URL
        let match: MetadataMatchScore
    }

    private var searchCache: [String: CachedSearch] = [:]
    private var searchMisses: Set<String> = []
    private var searchUnavailableUntil: Date?

    public func metadata(
        for app: any EnrichableApp,
        needsIcon: Bool
    ) async -> Metadata? {
        let key = [
            AppNameMatcher.normalized(app.name),
            app.category.lowercased(),
            ""
        ].joined(separator: "|")
        guard !key.isEmpty else {
            return nil
        }
        if let cached = searchCache[key],
           let metadata = await metadata(
                for: cached.url,
                category: app.category,
                subcategory: "",
                needsIcon: needsIcon
           )
        {
            return Metadata(
                description: metadata.description,
                iconData: metadata.iconData,
                projectURL: metadata.projectURL,
                homepageURL: metadata.homepageURL,
                downloadURL: metadata.downloadURL,
                match: cached.match
            )
        }
        if searchMisses.contains(key)
            || searchUnavailableUntil.map({ $0 > Date() }) == true
        {
            return nil
        }

        guard var components = URLComponents(
            string: "https://api.github.com/search/repositories"
        ) else {
            return nil
        }
        components.queryItems = [
            URLQueryItem(
                name: "q",
                value: "\(AppNameMatcher.searchName(app.name)) in:name"
            ),
            URLQueryItem(name: "per_page", value: "5")
        ]
        guard let url = components.url,
              let searchData = await data(from: url),
              let response = try? JSONDecoder().decode(
                SearchResponse.self,
                from: searchData
              ),
              let selection = bestMatch(
                for: app,
                in: response.items
              ),
              selection.match.decision != .reject,
              let repositoryURL = URL(
                string: selection.repository.htmlURL
              )
        else {
            searchMisses.insert(key)
            return nil
        }
        searchCache[key] = CachedSearch(
            url: repositoryURL,
            match: selection.match
        )
        guard let metadata = await metadata(
            for: repositoryURL,
            category: app.category,
            subcategory: "",
            needsIcon: needsIcon
        ) else {
            return nil
        }
        return Metadata(
            description: metadata.description,
            iconData: metadata.iconData,
            projectURL: metadata.projectURL,
            homepageURL: metadata.homepageURL,
            downloadURL: metadata.downloadURL,
            match: selection.match
        )
    }

    public func metadata(
        for url: URL,
        category: String = "",
        subcategory: String = "",
        needsIcon: Bool
    ) async -> Metadata? {
        guard let repository = repositoryPath(from: url) else {
            return nil
        }
        let apiRoot = URL(
            string: "https://api.github.com/repos/\(repository.owner)/\(repository.name)"
        )!
        guard let repositoryData = await data(from: apiRoot),
              let info = try? JSONDecoder().decode(
                RepositoryInfo.self,
                from: repositoryData
              ),
              let projectURL = URL(string: info.htmlURL),
              AppContextMatcher.isPlausible(
                category: category,
                subcategory: subcategory,
                candidateText: [
                    info.description ?? "",
                    info.language ?? "",
                    info.topics?.joined(separator: " ") ?? ""
                ].joined(separator: " ")
              )
        else {
            return await webPageMetadata(
                for: url,
                repositoryName: repository.name,
                category: category,
                subcategory: subcategory,
                needsIcon: needsIcon
            )
        }
        let releasesURL = URL(
            string: info.htmlURL + "/releases/latest"
        )!

        let homepageURL = officialHomepage(from: info.homepage)
        let iconData = needsIcon
            ? await repositoryIconData(
                projectURL: projectURL,
                homepageURL: homepageURL
            )
            : nil

        return Metadata(
            description: info.description,
            iconData: iconData,
            projectURL: projectURL,
            homepageURL: homepageURL,
            downloadURL: releasesURL,
            match: MetadataMatchScore(
                value: 1,
                margin: 1,
                decision: .automatic
            )
        )
    }

    nonisolated func repositoryPath(
        from url: URL
    ) -> (owner: String, name: String)? {
        guard url.host?.lowercased() == "github.com" else {
            return nil
        }
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count >= 2 else {
            return nil
        }
        return (components[0], components[1])
    }

    private func bestMatch(
        for app: any EnrichableApp,
        in repositories: [SearchRepository]
    ) -> (repository: SearchRepository, match: MetadataMatchScore)? {
        let ranked = MetadataMatchScorer.ranked(
            app: app,
            candidates: repositories.filter {
                !$0.archived && !$0.fork
            },
            confirmationProvider: confirmationProvider
        ) { repository in
            MetadataMatchCandidate(
                name: repository.name,
                contextText: [
                    repository.description ?? "",
                    repository.language ?? "",
                    repository.topics?.joined(separator: " ") ?? ""
                ].joined(separator: " "),
                developer: repository.owner.login,
                url: URL(string: repository.htmlURL),
                bundleIdentifier: nil,
                sourceReliability: min(
                    0.55
                        + log10(Double(max(repository.stargazersCount, 1)))
                        / 20,
                    0.85
                )
            )
        }
        guard let selection = MetadataMatchScorer.result(
            app: app,
            ranked: ranked
        ) else {
            return nil
        }
        return (selection.candidate, selection.match)
    }

    private func officialHomepage(from value: String?) -> URL? {
        guard let value,
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              OfficialWebsiteLookup.isOfficialCandidate(url)
        else {
            return nil
        }
        return url
    }

    private func webPageMetadata(
        for projectURL: URL,
        repositoryName: String,
        category: String,
        subcategory: String,
        needsIcon: Bool
    ) async -> Metadata? {
        var request = URLRequest(url: projectURL)
        request.timeoutInterval = 30
        request.setValue("AppMetadataKit/0.1", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let html = String(data: data, encoding: .utf8)
            else {
                return nil
            }
            let description = Self.metaDescription(in: html)
            let homepageURL = Self.externalHomepage(
                in: html,
                repositoryName: repositoryName
            )
            guard AppContextMatcher.isPlausible(
                category: category,
                subcategory: subcategory,
                candidateText: "\(repositoryName) \(description ?? "")"
            ) else {
                return nil
            }
            return Metadata(
                description: description,
                iconData: needsIcon
                    ? await repositoryIconData(
                        projectURL: projectURL,
                        homepageURL: homepageURL
                    )
                    : nil,
                projectURL: projectURL,
                homepageURL: homepageURL,
                downloadURL: projectURL.appendingPathComponent(
                    "releases/latest"
                ),
                match: MetadataMatchScore(
                    value: 1,
                    margin: 1,
                    decision: .automatic
                )
            )
        } catch {
            return nil
        }
    }

    private func repositoryIconData(
        projectURL: URL,
        homepageURL: URL?
    ) async -> Data? {
        if let metadata = await WebMetadataLookup.shared.metadata(
            for: projectURL,
            needsIcon: true
        ),
           let iconData = metadata.iconData {
            return iconData
        }
        if let homepageURL,
           let metadata = await WebMetadataLookup.shared.metadata(
                for: homepageURL,
                needsIcon: true
           ),
           let iconData = metadata.iconData {
            return iconData
        }
        return nil
    }

    nonisolated static func externalHomepage(
        in html: String,
        repositoryName: String
    ) -> URL? {
        let pattern = #"https?://[A-Za-z0-9][A-Za-z0-9._~:/?#\[\]@!$&'()*+,;=%-]*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let repositoryKey = AppNameMatcher.normalized(repositoryName)
        return regex.matches(
            in: html,
            range: NSRange(html.startIndex..., in: html)
        )
        .compactMap { match -> URL? in
            guard let range = Range(match.range, in: html) else {
                return nil
            }
            let value = String(html[range])
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "\\", with: "")
            guard let url = URL(string: value),
                  let host = url.host?.lowercased(),
                  !host.contains("github"),
                  !host.contains("githubusercontent"),
                  !host.contains("google"),
                  !host.contains("schema.org"),
                  AppNameMatcher.normalized(host).contains(repositoryKey),
                  let scheme = url.scheme
            else {
                return nil
            }
            return URL(string: "\(scheme)://\(host)")
        }
        .first
    }

    nonisolated static func metaDescription(in html: String) -> String? {
        let pattern = #"<meta[^>]+(?:name|property)=["'](?:description|og:description)["'][^>]+content=["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ),
        let match = regex.firstMatch(
            in: html,
            range: NSRange(html.startIndex..., in: html)
        ),
        let range = Range(match.range(at: 1), in: html)
        else {
            return nil
        }
        return String(html[range])
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func data(from url: URL) async -> Data? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("AppMetadataKit/0.1", forHTTPHeaderField: "User-Agent")
        request.setValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode)
            else {
                if let http = response as? HTTPURLResponse,
                   http.statusCode == 403 || http.statusCode == 429
                {
                    searchUnavailableUntil = Date().addingTimeInterval(60)
                }
                return nil
            }
            return data
        } catch {
            return nil
        }
    }

    private struct RepositoryInfo: Decodable {
        let description: String?
        let htmlURL: String
        let homepage: String?
        let defaultBranch: String
        let language: String?
        let topics: [String]?

        enum CodingKeys: String, CodingKey {
            case description
            case htmlURL = "html_url"
            case homepage
            case defaultBranch = "default_branch"
            case language
            case topics
        }
    }

    private struct SearchResponse: Decodable {
        let items: [SearchRepository]
    }

    private struct SearchRepository: Decodable {
        let name: String
        let htmlURL: String
        let archived: Bool
        let fork: Bool
        let stargazersCount: Int
        let description: String?
        let language: String?
        let topics: [String]?
        let owner: Owner

        enum CodingKeys: String, CodingKey {
            case name
            case htmlURL = "html_url"
            case archived
            case fork
            case stargazersCount = "stargazers_count"
            case description
            case language
            case topics
            case owner
        }
    }

    private struct Owner: Decodable {
        let login: String
    }

    private struct CachedSearch {
        let url: URL
        let match: MetadataMatchScore
    }
}
