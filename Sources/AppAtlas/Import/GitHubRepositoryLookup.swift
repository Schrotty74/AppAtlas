import Foundation

actor GitHubRepositoryLookup {
    static let shared = GitHubRepositoryLookup()

    struct Metadata: Sendable {
        let description: String?
        let iconData: Data?
        let projectURL: URL
        let homepageURL: URL?
        let downloadURL: URL
    }

    private var searchCache: [String: URL] = [:]
    private var searchMisses: Set<String> = []
    private var searchUnavailableUntil: Date?

    func metadata(
        forAppNamed appName: String,
        category: String = "",
        subcategory: String = "",
        needsIcon: Bool
    ) async -> Metadata? {
        let key = [
            AppNameMatcher.normalized(appName),
            category.lowercased(),
            subcategory.lowercased()
        ].joined(separator: "|")
        guard !key.isEmpty else {
            return nil
        }
        if let cachedURL = searchCache[key] {
            return await metadata(
                for: cachedURL,
                category: category,
                subcategory: subcategory,
                needsIcon: needsIcon
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
                value: "\(AppNameMatcher.searchName(appName)) in:name"
            ),
            URLQueryItem(name: "per_page", value: "5")
        ]
        guard let url = components.url,
              let searchData = await data(from: url),
              let response = try? JSONDecoder().decode(
                SearchResponse.self,
                from: searchData
              ),
              let match = bestMatch(
                for: appName,
                category: category,
                subcategory: subcategory,
                in: response.items
              ),
              let repositoryURL = URL(string: match.htmlURL)
        else {
            searchMisses.insert(key)
            return nil
        }
        searchCache[key] = repositoryURL
        return await metadata(
            for: repositoryURL,
            category: category,
            subcategory: subcategory,
            needsIcon: needsIcon
        )
    }

    func metadata(
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

        var iconData: Data?
        if needsIcon {
            let treeURL = apiRoot
                .appendingPathComponent("git/trees")
                .appendingPathComponent(info.defaultBranch)
                .appending(queryItems: [
                    URLQueryItem(name: "recursive", value: "1")
                ])
            if let treeData = await data(from: treeURL),
               let tree = try? JSONDecoder().decode(TreeResponse.self, from: treeData),
               let path = bestIconPath(in: tree.tree)
            {
                let rawURL = URL(
                    string: "https://raw.githubusercontent.com/\(repository.owner)/\(repository.name)/\(info.defaultBranch)/\(path)"
                )!
                iconData = await OnlineIconLoader.shared.iconData(from: rawURL)
            }
        }

        return Metadata(
            description: info.description,
            iconData: iconData,
            projectURL: projectURL,
            homepageURL: officialHomepage(from: info.homepage),
            downloadURL: releasesURL
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

    private func bestIconPath(in entries: [TreeEntry]) -> String? {
        entries
            .filter {
                $0.type == "blob"
                    && ["png", "ico", "icns"].contains(
                        URL(fileURLWithPath: $0.path)
                            .pathExtension
                            .lowercased()
                    )
            }
            .map { ($0.path, iconScore($0.path)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .first?
            .0
    }

    private func bestMatch(
        for appName: String,
        category: String,
        subcategory: String,
        in repositories: [SearchRepository]
    ) -> SearchRepository? {
        repositories
            .filter {
                !$0.archived
                    && !$0.fork
                    && AppContextMatcher.isPlausible(
                        category: category,
                        subcategory: subcategory,
                        candidateText: [
                            $0.description ?? "",
                            $0.language ?? "",
                            $0.topics?.joined(separator: " ") ?? ""
                        ].joined(separator: " ")
                    )
            }
            .map {
                (
                    repository: $0,
                    similarity: AppNameMatcher.similarity(appName, $0.name)
                )
            }
            .filter { $0.similarity >= 0.8 }
            .sorted {
                if $0.similarity != $1.similarity {
                    return $0.similarity > $1.similarity
                }
                return $0.repository.stargazersCount
                    > $1.repository.stargazersCount
            }
            .first?
            .repository
    }

    private func iconScore(_ path: String) -> Int {
        let value = path.lowercased()
        var score = 0
        if value.contains("appicon") { score += 120 }
        if value.contains("icon512@2x") { score += 115 }
        if value.contains("icon512") { score += 110 }
        if value.contains("icon256@2x") { score += 100 }
        if value.contains("icon256") { score += 95 }
        if value.contains("icon_round") { score += 90 }
        if value.contains("/art/") || value.contains("/resources/") {
            score += 20
        }
        if value.contains("logo") { score += 15 }
        if value.contains("screenshot") || value.contains("thumbnail") {
            score -= 100
        }
        return score
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
        request.timeoutInterval = 20
        request.setValue("AppAtlas/0.1", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let html = String(data: data, encoding: .utf8)
            else {
                return nil
            }
            let description = Self.metaDescription(in: html)
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
                    ? await conventionalIconData(for: projectURL)
                    : nil,
                projectURL: projectURL,
                homepageURL: Self.externalHomepage(
                    in: html,
                    repositoryName: repositoryName
                ),
                downloadURL: projectURL.appendingPathComponent(
                    "releases/latest"
                )
            )
        } catch {
            return nil
        }
    }

    private func conventionalIconData(for projectURL: URL) async -> Data? {
        guard let repository = repositoryPath(from: projectURL) else {
            return nil
        }
        let paths = [
            "build/appicon.png",
            "AppIcon.png",
            "appicon.png",
            "icon512.png",
            "icon.png",
            "assets/icon.png"
        ]
        let urls = ["main", "master"].flatMap { branch in
            paths.compactMap { path in
                URL(
                    string: "https://raw.githubusercontent.com/"
                        + "\(repository.owner)/\(repository.name)/"
                        + "\(branch)/\(path)"
                )
            }
        }
        return await withTaskGroup(of: Data?.self) { group in
            for url in urls {
                group.addTask {
                    await OnlineIconLoader.shared.iconData(from: url)
                }
            }
            for await data in group {
                if let data {
                    group.cancelAll()
                    return data
                }
            }
            return nil
        }
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
        request.timeoutInterval = 20
        request.setValue("AppAtlas/0.1", forHTTPHeaderField: "User-Agent")
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

    private struct TreeResponse: Decodable {
        let tree: [TreeEntry]
    }

    private struct TreeEntry: Decodable {
        let path: String
        let type: String
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

        enum CodingKeys: String, CodingKey {
            case name
            case htmlURL = "html_url"
            case archived
            case fork
            case stargazersCount = "stargazers_count"
            case description
            case language
            case topics
        }
    }
}
