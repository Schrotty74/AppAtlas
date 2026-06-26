import Foundation

struct HomebrewCaskMetadata: Sendable {
    let homepage: URL?
    let downloadURL: URL?
    let githubURL: URL?
    let description: String?
    let sourceName: String
}

final class HomebrewCaskMetadataCache: @unchecked Sendable {
    static let shared = HomebrewCaskMetadataCache()

    private let fileURL: URL
    private let sourceURL = URL(
        string: "https://formulae.brew.sh/api/cask.json"
    )!
    private let lock = NSLock()
    private var cachedIndex: [String: Cask]?

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            self.fileURL = AppLocalDataDirectory.url
                .appendingPathComponent("homebrew-cask-cache.json")
        }
    }

    func refresh() async throws {
        var request = URLRequest(url: sourceURL)
        request.timeoutInterval = 30
        request.setValue(
            "AppAtlas/0.1 (manual catalog metadata update)",
            forHTTPHeaderField: "User-Agent"
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              data.count <= 80_000_000
        else {
            throw HomebrewCaskMetadataCacheError.invalidResponse
        }
        _ = try JSONDecoder().decode([Cask].self, from: data)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
        lock.withLock {
            cachedIndex = nil
        }
    }

    func metadata(for app: AppEntry) -> HomebrewCaskMetadata? {
        guard let index = loadIndexIfNeeded() else {
            return nil
        }
        let keys = candidateKeys(for: app)
        guard let cask = keys.lazy.compactMap({ index[$0] }).first else {
            return nil
        }
        if !cask.lookupKeys.contains(where: { keys.contains($0) }),
           !isPlausible(cask, for: app) {
            return nil
        }
        return HomebrewCaskMetadata(
            homepage: cask.homepageURL,
            downloadURL: cask.urlURL,
            githubURL: cask.githubURL,
            description: cask.desc,
            sourceName: cask.token
        )
    }

    private func loadIndexIfNeeded() -> [String: Cask]? {
        if let cached = lock.withLock({ cachedIndex }) {
            return cached
        }
        guard let data = try? Data(contentsOf: fileURL),
              data.count <= 80_000_000,
              let casks = try? JSONDecoder().decode([Cask].self, from: data)
        else {
            return nil
        }
        var index: [String: Cask] = [:]
        for cask in casks {
            for key in cask.lookupKeys {
                index[key] = cask
            }
        }
        lock.withLock {
            cachedIndex = index
        }
        return index
    }

    private func candidateKeys(for app: AppEntry) -> [String] {
        let names = [app.name] + app.files.flatMap {
            [$0.fileName, AppNameNormalizer.displayName(for: $0.fileName)]
        }
        return Array(Set(names.flatMap {
            [
                AppNameMatcher.normalized($0),
                Self.homebrewLookupKey($0)
            ]
        })).filter { !$0.isEmpty }
    }

    private func isPlausible(_ cask: Cask, for app: AppEntry) -> Bool {
        let score = MetadataMatchScorer.score(
            app: app,
            candidate: MetadataMatchCandidate(
                name: cask.matchName,
                contextText: cask.matchContext,
                developer: nil,
                url: cask.homepageURL ?? cask.githubURL ?? cask.urlURL,
                bundleIdentifier: nil,
                sourceReliability: 0.95
            )
        )
        return score >= MetadataMatchScorer.automaticThreshold
    }

    struct Cask: Decodable, Sendable {
        let token: String
        let fullToken: String?
        let name: [String]
        let desc: String?
        let homepage: String?
        let url: String?

        enum CodingKeys: String, CodingKey {
            case token
            case fullToken = "full_token"
            case name
            case desc
            case homepage
            case url
        }

        var matchName: String {
            name.first ?? token
        }

        var matchContext: String {
            ([desc, homepage, url, fullToken, token].compactMap { $0 } + name)
                .joined(separator: " ")
        }

        var lookupKeys: [String] {
            let names = [token, fullToken].compactMap { $0 } + name
            return Array(Set(names.flatMap {
                [
                    AppNameMatcher.normalized($0),
                    HomebrewCaskMetadataCache.homebrewLookupKey($0)
                ]
            })).filter { !$0.isEmpty }
        }

        var homepageURL: URL? {
            homepage.flatMap(URL.init(string:))
        }

        var urlURL: URL? {
            url.flatMap(URL.init(string:))
        }

        var githubURL: URL? {
            [homepageURL, urlURL].compactMap { $0 }.first {
                guard let host = $0.host?.lowercased() else {
                    return false
                }
                return host == "github.com" || host.hasSuffix(".github.com")
            }
        }
    }

    private static func homebrewLookupKey(_ value: String) -> String {
        var result = (value as NSString).deletingPathExtension
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "+", with: " ")
            .replacingOccurrences(
                of: #"\b(?:versions?|installer|setup|webinstall)\b"#,
                with: " ",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"\b(?:macos|mac|darwin|universal|arm64|aarch64|x64|intel|apple\s*silicon)\b"#,
                with: " ",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"\b(?:v|build)?\d+[a-z0-9]*(?:\s+\d+[a-z0-9]*)*\b.*$"#,
                with: "",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
        result = result.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        return result.filter { $0.isLetter || $0.isNumber }
    }
}

enum HomebrewCaskMetadataCacheError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        "Der Homebrew-Cask-Katalog konnte nicht geladen werden."
    }
}
