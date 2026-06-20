import Foundation

final class ConfirmedMetadataMatchStore: @unchecked Sendable {
    static let shared = ConfirmedMetadataMatchStore()

    private struct Record: Codable {
        var domains: Set<String> = []
        var githubRepositories: Set<String> = []
        var appleTrackIDs: Set<Int> = []
        var urls: Set<String> = []
        var rejectedURLs: Set<String> = []
        var rejectedAppleTrackIDs: Set<Int> = []

        init(
            domains: Set<String> = [],
            githubRepositories: Set<String> = [],
            appleTrackIDs: Set<Int> = [],
            urls: Set<String> = [],
            rejectedURLs: Set<String> = [],
            rejectedAppleTrackIDs: Set<Int> = []
        ) {
            self.domains = domains
            self.githubRepositories = githubRepositories
            self.appleTrackIDs = appleTrackIDs
            self.urls = urls
            self.rejectedURLs = rejectedURLs
            self.rejectedAppleTrackIDs = rejectedAppleTrackIDs
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            domains = try container.decodeIfPresent(
                Set<String>.self,
                forKey: .domains
            ) ?? []
            githubRepositories = try container.decodeIfPresent(
                Set<String>.self,
                forKey: .githubRepositories
            ) ?? []
            appleTrackIDs = try container.decodeIfPresent(
                Set<Int>.self,
                forKey: .appleTrackIDs
            ) ?? []
            urls = try container.decodeIfPresent(
                Set<String>.self,
                forKey: .urls
            ) ?? []
            rejectedURLs = try container.decodeIfPresent(
                Set<String>.self,
                forKey: .rejectedURLs
            ) ?? []
            rejectedAppleTrackIDs = try container.decodeIfPresent(
                Set<Int>.self,
                forKey: .rejectedAppleTrackIDs
            ) ?? []
        }
    }

    private let defaults: UserDefaults
    private let storageKey = "confirmedMetadataMatches"
    private let lock = NSLock()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func confirm(appName: String, url: URL) {
        guard let host = Self.normalizedHost(url) else {
            return
        }
        update(appName: appName) { record in
            record.domains.insert(host)
            record.urls.insert(url.absoluteString)
            record.rejectedURLs.remove(Self.normalizedURLString(url))
            if host == "github.com" {
                let components = url.pathComponents.filter { $0 != "/" }
                if components.count >= 2 {
                    record.githubRepositories.insert(
                        "\(components[0].lowercased())/"
                            + components[1].lowercased()
                    )
                }
            }
        }
    }

    func confirm(appName: String, appleTrackID: Int) {
        update(appName: appName) {
            $0.appleTrackIDs.insert(appleTrackID)
            $0.rejectedAppleTrackIDs.remove(appleTrackID)
        }
    }

    func reject(appName: String, url: URL) {
        update(appName: appName) {
            $0.rejectedURLs.insert(Self.normalizedURLString(url))
        }
    }

    func reject(appName: String, appleTrackID: Int) {
        update(appName: appName) {
            $0.rejectedAppleTrackIDs.insert(appleTrackID)
        }
    }

    func domainScore(for appName: String, candidateURL: URL) -> Double {
        guard let host = Self.normalizedHost(candidateURL),
              let record = records()[Self.key(appName)]
        else {
            return 0
        }
        if record.rejectedURLs.contains(Self.normalizedURLString(candidateURL)) {
            return 0
        }
        if host == "github.com" {
            guard let repository = Self.githubRepository(candidateURL) else {
                return 0
            }
            return record.githubRepositories.contains(repository) ? 1 : 0
        }
        if record.domains.contains(host) {
            return 1
        }
        return record.domains.contains {
            host.hasSuffix(".\($0)") || $0.hasSuffix(".\(host)")
        } ? 0.9 : 0
    }

    func isConfirmed(appName: String, appleTrackID: Int) -> Bool {
        records()[Self.key(appName)]?.appleTrackIDs.contains(appleTrackID)
            == true
    }

    func isRejected(appName: String, url: URL) -> Bool {
        records()[Self.key(appName)]?.rejectedURLs.contains(
            Self.normalizedURLString(url)
        ) == true
    }

    func isRejected(appName: String, appleTrackID: Int) -> Bool {
        records()[Self.key(appName)]?.rejectedAppleTrackIDs
            .contains(appleTrackID) == true
    }

    func confirmedURLs(for appName: String) -> [URL] {
        guard let record = records()[Self.key(appName)] else {
            return []
        }
        return record.urls
            .compactMap(URL.init(string:))
            .filter {
                !record.rejectedURLs.contains(Self.normalizedURLString($0))
            }
            .sorted {
                $0.absoluteString.localizedStandardCompare($1.absoluteString)
                    == .orderedAscending
            }
    }

    private func update(
        appName: String,
        mutation: (inout Record) -> Void
    ) {
        lock.lock()
        defer { lock.unlock() }
        var current = loadRecords()
        var record = current[Self.key(appName)] ?? Record()
        mutation(&record)
        current[Self.key(appName)] = record
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func records() -> [String: Record] {
        lock.lock()
        defer { lock.unlock() }
        return loadRecords()
    }

    private func loadRecords() -> [String: Record] {
        guard let data = defaults.data(forKey: storageKey) else {
            return [:]
        }
        return (try? JSONDecoder().decode(
            [String: Record].self,
            from: data
        )) ?? [:]
    }

    private static func key(_ appName: String) -> String {
        AppNameMatcher.normalized(appName)
    }

    private static func normalizedHost(_ url: URL) -> String? {
        guard var host = url.host?.lowercased() else {
            return nil
        }
        if host.hasPrefix("www.") {
            host.removeFirst(4)
        }
        return host
    }

    private static func githubRepository(_ url: URL) -> String? {
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count >= 2 else {
            return nil
        }
        return "\(components[0].lowercased())/"
            + components[1].lowercased()
    }

    private static func normalizedURLString(_ url: URL) -> String {
        guard var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            return url.absoluteString.lowercased()
        }
        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()
        components.fragment = nil
        if components.path.count > 1, components.path.hasSuffix("/") {
            components.path.removeLast()
        }
        return components.url?.absoluteString.lowercased()
            ?? url.absoluteString.lowercased()
    }
}
