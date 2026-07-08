import Foundation

public actor WebMetadataLookup {
    public static let shared = WebMetadataLookup()

    public struct Metadata: Sendable {
        let description: String?
        let iconData: Data?
    }

    public func metadata(for homepage: URL, needsIcon: Bool) async -> Metadata? {
        guard let scheme = homepage.scheme?.lowercased(),
              ["http", "https"].contains(scheme)
        else {
            return nil
        }

        var request = URLRequest(url: homepage)
        request.timeoutInterval = 30
        request.setValue("AppMetadataKit/0.1", forHTTPHeaderField: "User-Agent")
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
            ).map { String($0.prefix(1500)) }
            let ogImage = metaContent(in: html, names: ["og:image"])
            let previewURL = needsIcon
                ? ogImage
                    .flatMap {
                        URL(string: $0, relativeTo: homepage)?.absoluteURL
                    }
                    .map(OnlineIconLoader.imageSourceURL)
                    .flatMap {
                        Self.isLikelyIconURL($0) ? $0 : nil
                    }
                : nil
            let previewIcon: Data? = if let previewURL {
                await OnlineIconLoader.shared.iconData(from: previewURL)
            } else {
                nil
            }
            let linkedIcon: Data? = if needsIcon,
                                       previewIcon == nil
            {
                await firstLinkedIcon(in: html, baseURL: homepage)
            } else {
                nil
            }
            let bodyIcon: Data? = if needsIcon,
                                     previewIcon == nil,
                                     linkedIcon == nil
            {
                await firstBodyLogoIcon(in: html, baseURL: homepage)
            } else {
                nil
            }
            let iconData: Data? = if let previewIcon {
                previewIcon
            } else if let linkedIcon {
                linkedIcon
            } else if let bodyIcon {
                bodyIcon
            } else if needsIcon
                && OfficialWebsiteLookup.allowsGenericWebsiteIcon(homepage)
            {
                await OnlineIconLoader.shared.iconData(for: homepage)
            } else {
                nil
            }
            return Metadata(
                description: description,
                iconData: iconData
            )
        } catch {
            return nil
        }
    }

    private func firstLinkedIcon(
        in html: String,
        baseURL: URL
    ) async -> Data? {
        for url in linkedIconURLs(in: html, baseURL: baseURL) {
            if let iconData = await OnlineIconLoader.shared.iconData(from: url) {
                return iconData
            }
        }
        return nil
    }

    private func firstBodyLogoIcon(
        in html: String,
        baseURL: URL
    ) async -> Data? {
        for url in bodyLogoIconURLs(in: html, baseURL: baseURL) {
            if let iconData = await OnlineIconLoader.shared.iconData(from: url) {
                return iconData
            }
        }
        return nil
    }

    private func linkedIconURLs(in html: String, baseURL: URL) -> [URL] {
        let pattern = #"<link\b[^>]*>"#
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return []
        }
        return regex.matches(
            in: html,
            range: NSRange(html.startIndex..., in: html)
        )
        .compactMap { match -> URL? in
            guard let range = Range(match.range, in: html) else {
                return nil
            }
            let tag = String(html[range])
            let rel = attribute("rel", in: tag)?.lowercased() ?? ""
            guard rel.contains("icon") else {
                return nil
            }
            guard let href = attribute("href", in: tag) else {
                return nil
            }
            return URL(string: href, relativeTo: baseURL)
                .map(\.absoluteURL)
                .map(OnlineIconLoader.imageSourceURL)
        }
        .filter(Self.isLikelyIconURL)
    }

    private func bodyLogoIconURLs(in html: String, baseURL: URL) -> [URL] {
        let pattern = #"<img\b[^>]*>"#
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return []
        }
        return regex.matches(
            in: html,
            range: NSRange(html.startIndex..., in: html)
        )
        .compactMap { match -> URL? in
            guard let range = Range(match.range, in: html) else {
                return nil
            }
            let tag = String(html[range])
            guard let src = attribute("src", in: tag),
                  let url = URL(string: src, relativeTo: baseURL)?.absoluteURL
            else {
                return nil
            }
            let imageURL = OnlineIconLoader.imageSourceURL(from: url)
            return Self.isLikelyBodyLogoIconURL(imageURL) ? imageURL : nil
        }
    }

    private func attribute(_ name: String, in tag: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: name)
        let pattern = #"\b\#(escaped)\s*=\s*["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ),
        let match = regex.firstMatch(
            in: tag,
            range: NSRange(tag.startIndex..., in: tag)
        ),
        let range = Range(match.range(at: 1), in: tag)
        else {
            return nil
        }
        return decodeHTMLEntities(String(tag[range]))
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
            "product-icon",
            "product-icons",
            "apple-touch-icon",
            "favicon",
            "/icon"
        ].contains { value.contains($0) }
            && !value.contains("screenshot")
            && !value.contains("preview")
            && !value.contains("banner")
    }

    nonisolated private static func isLikelyBodyLogoIconURL(_ url: URL) -> Bool {
        let fileName = url.lastPathComponent.lowercased()
        let fileExtension = url.pathExtension.lowercased()
        return (fileName.contains("logo") || fileName.contains("icon"))
            && ["png", "svg"].contains(fileExtension)
    }
}
