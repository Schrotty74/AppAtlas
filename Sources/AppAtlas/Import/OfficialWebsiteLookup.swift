import Foundation

actor OfficialWebsiteLookup {
    static let shared = OfficialWebsiteLookup()

    struct Result: Sendable {
        let url: URL
        let match: MetadataMatchScore
    }

    private static let excludedHosts = [
        "apps.apple.com",
        "alternativeto.net",
        "bundlehunt.com",
        "macupdate.com",
        "mightydeals.com",
        "osrepos.com",
        "reddit.com",
        "setapp.com",
        "softpedia.com",
        "stacksocial.com",
        "wikipedia.org"
    ]

    func homepage(for app: AppEntry) async -> Result? {
        guard var components = URLComponents(
            string: "https://html.duckduckgo.com/html/"
        ) else {
            return nil
        }
        components.queryItems = [
            URLQueryItem(
                name: "q",
                value: [
                    AppNameMatcher.searchName(app.name),
                    AppContextMatcher.searchHint(
                        category: app.category,
                        subcategory: app.subcategory
                    ),
                    "mac app official"
                ]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            )
        ]
        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("AppAtlas/0.1", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let html = String(data: data, encoding: .utf8)
            else {
                return nil
            }
            let ranked = MetadataMatchScorer.ranked(
                app: app,
                candidates: candidates(from: html).filter {
                    Self.isOfficialCandidate($0.url)
                }
            ) { candidate in
                MetadataMatchCandidate(
                    name: candidate.title,
                    contextText:
                        "\(candidate.title) \(candidate.url.absoluteString)",
                    developer: nil,
                    url: candidate.url,
                    bundleIdentifier: nil,
                    sourceReliability: 0.7
                )
            }
            guard let selection = MetadataMatchScorer.result(
                app: app,
                ranked: ranked
            ),
                  selection.match.decision != .reject
            else {
                return nil
            }
            return Result(
                url: selection.candidate.url,
                match: selection.match
            )
        } catch {
            return nil
        }
    }

    private func candidates(from html: String) -> [(title: String, url: URL)] {
        let pattern = #"result__a[^>]*href="([^"]+)"[^>]*>(.*?)</a>"#
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return []
        }
        return regex.matches(
            in: html,
            range: NSRange(html.startIndex..., in: html)
        )
        .compactMap { match in
            guard let linkRange = Range(match.range(at: 1), in: html),
                  let titleRange = Range(match.range(at: 2), in: html),
                  let url = resolvedURL(String(html[linkRange]))
            else {
                return nil
            }
            let title = String(html[titleRange])
                .replacingOccurrences(
                    of: #"<[^>]+>"#,
                    with: "",
                    options: .regularExpression
                )
                .replacingOccurrences(of: "&amp;", with: "&")
            return (title, url)
        }
    }

    private func resolvedURL(_ rawValue: String) -> URL? {
        let decoded = rawValue.replacingOccurrences(of: "&amp;", with: "&")
        guard let redirect = URL(
            string: decoded.hasPrefix("//") ? "https:\(decoded)" : decoded
        ) else {
            return nil
        }
        if redirect.host?.contains("duckduckgo.com") == true,
           let components = URLComponents(url: redirect, resolvingAgainstBaseURL: false),
           let target = components.queryItems?.first(where: { $0.name == "uddg" })?.value
        {
            return URL(string: target)
        }
        return redirect
    }

    nonisolated static func isOfficialCandidate(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else {
            return false
        }
        return !excludedHosts.contains {
            host == $0 || host.hasSuffix(".\($0)")
        }
    }

    nonisolated static func allowsGenericWebsiteIcon(_ url: URL) -> Bool {
        guard isOfficialCandidate(url),
              let host = url.host?.lowercased()
        else {
            return false
        }
        let repositoryHosts = ["github.com", "gitlab.com"]
        return !repositoryHosts.contains {
            host == $0 || host.hasSuffix(".\($0)")
        }
    }
}
