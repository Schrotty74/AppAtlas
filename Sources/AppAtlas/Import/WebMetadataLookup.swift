import Foundation

actor WebMetadataLookup {
    static let shared = WebMetadataLookup()

    struct Metadata: Sendable {
        let description: String?
        let iconData: Data?
    }

    func metadata(for homepage: URL, needsIcon: Bool) async -> Metadata? {
        guard let scheme = homepage.scheme?.lowercased(),
              ["http", "https"].contains(scheme)
        else {
            return nil
        }

        var request = URLRequest(url: homepage)
        request.timeoutInterval = 15
        request.setValue("AppAtlas/0.1", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  data.count <= 5_000_000,
                  let html = String(data: data, encoding: .utf8)
            else {
                return nil
            }

            let description = metaContent(
                in: html,
                names: ["description", "og:description"]
            ).map { String($0.prefix(500)) }
            let previewURL = needsIcon
                ? metaContent(in: html, names: ["og:image"])
                    .flatMap {
                        URL(string: $0, relativeTo: homepage)?.absoluteURL
                    }
                    .flatMap {
                        Self.isLikelyIconURL($0) ? $0 : nil
                    }
                : nil
            let previewIcon: Data? = if let previewURL {
                await OnlineIconLoader.shared.iconData(from: previewURL)
            } else {
                nil
            }
            let iconData: Data? = if let previewIcon {
                previewIcon
            } else if needsIcon
                && OfficialWebsiteLookup.allowsGenericWebsiteIcon(homepage)
            {
                await OnlineIconLoader.shared.iconData(for: homepage)
            } else {
                nil
            }
            return Metadata(description: description, iconData: iconData)
        } catch {
            return nil
        }
    }

    private func metaContent(in html: String, names: [String]) -> String? {
        for name in names {
            let escaped = NSRegularExpression.escapedPattern(for: name)
            let patterns = [
                #"<meta[^>]+(?:name|property)\s*=\s*["']\#(escaped)["'][^>]+content\s*=\s*["']([^"']+)["'][^>]*>"#,
                #"<meta[^>]+content\s*=\s*["']([^"']+)["'][^>]+(?:name|property)\s*=\s*["']\#(escaped)["'][^>]*>"#
            ]
            for pattern in patterns {
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
                    continue
                }
                return decodeHTMLEntities(String(html[range]))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    private func decodeHTMLEntities(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }

    nonisolated static func isLikelyIconURL(_ url: URL) -> Bool {
        let value = url.path.lowercased()
        return [
            "appicon",
            "app-icon",
            "apple-touch-icon",
            "favicon",
            "/icon",
            "logo"
        ].contains { value.contains($0) }
            && !value.contains("screenshot")
            && !value.contains("preview")
            && !value.contains("banner")
    }
}
