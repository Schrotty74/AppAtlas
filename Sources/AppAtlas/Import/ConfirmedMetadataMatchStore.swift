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
        var confirmedSuggestionValues: Set<String> = []
        var rejectedSuggestionValues: Set<String> = []

        init(
            domains: Set<String> = [],
            githubRepositories: Set<String> = [],
            appleTrackIDs: Set<Int> = [],
            urls: Set<String> = [],
            rejectedURLs: Set<String> = [],
            rejectedAppleTrackIDs: Set<Int> = [],
            confirmedSuggestionValues: Set<String> = [],
            rejectedSuggestionValues: Set<String> = []
        ) {
            self.domains = domains
            self.githubRepositories = githubRepositories
            self.appleTrackIDs = appleTrackIDs
            self.urls = urls
            self.rejectedURLs = rejectedURLs
            self.rejectedAppleTrackIDs = rejectedAppleTrackIDs
            self.confirmedSuggestionValues = confirmedSuggestionValues
            self.rejectedSuggestionValues = rejectedSuggestionValues
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
            confirmedSuggestionValues = try container.decodeIfPresent(
                Set<String>.self,
                forKey: .confirmedSuggestionValues
            ) ?? []
            rejectedSuggestionValues = try container.decodeIfPresent(
                Set<String>.self,
                forKey: .rejectedSuggestionValues
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

    func confirm(appName: String, suggestionKind: String, value: String) {
        guard let key = Self.suggestionValueKey(
            kind: suggestionKind,
            value: value
        ) else {
            return
        }
        update(appName: appName) {
            $0.confirmedSuggestionValues.insert(key)
            $0.rejectedSuggestionValues.remove(key)
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

    func reject(appName: String, suggestionKind: String, value: String) {
        guard let key = Self.suggestionValueKey(
            kind: suggestionKind,
            value: value
        ) else {
            return
        }
        update(appName: appName) {
            $0.rejectedSuggestionValues.insert(key)
        }
    }

    func domainScore(for appName: String, candidateURL: URL) -> Double {
        guard let host = Self.normalizedHost(candidateURL) else {
            return 0
        }
        let candidate = Self.normalizedURLString(candidateURL)
        let currentRecords = records()
        if currentRecords.values.contains(where: {
            $0.rejectedURLs.contains(candidate)
        }) {
            return 0
        }
        if currentRecords.values.contains(where: { record in
            record.urls.compactMap(URL.init(string:)).contains {
                Self.normalizedURLString($0) == candidate
            }
        }) {
            return 1
        }
        guard let record = currentRecords[Self.key(appName)] else {
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

    func isConfirmed(appName: String, url: URL) -> Bool {
        let candidate = Self.normalizedURLString(url)
        let currentRecords = records()
        return currentRecords[Self.key(appName)]?.urls
            .compactMap(URL.init(string:))
            .contains { Self.normalizedURLString($0) == candidate } == true
            || currentRecords.values.contains {
                $0.urls.compactMap(URL.init(string:)).contains {
                    Self.normalizedURLString($0) == candidate
                }
            }
    }

    func isConfirmed(
        appName: String,
        suggestionKind: String,
        value: String
    ) -> Bool {
        guard let key = Self.suggestionValueKey(
            kind: suggestionKind,
            value: value
        ) else {
            return false
        }
        let currentRecords = records()
        return currentRecords[Self.key(appName)]?
            .confirmedSuggestionValues
            .contains(key) == true
    }

    func isRejected(appName: String, url: URL) -> Bool {
        let candidate = Self.normalizedURLString(url)
        let currentRecords = records()
        return currentRecords[Self.key(appName)]?.rejectedURLs.contains(
            candidate
        ) == true
            || currentRecords.values.contains {
                $0.rejectedURLs.contains(candidate)
            }
    }

    func isRejected(appName: String, appleTrackID: Int) -> Bool {
        records()[Self.key(appName)]?.rejectedAppleTrackIDs
            .contains(appleTrackID) == true
    }

    func isRejected(
        appName: String,
        suggestionKind: String,
        value: String
    ) -> Bool {
        guard let key = Self.suggestionValueKey(
            kind: suggestionKind,
            value: value
        ) else {
            return false
        }
        let currentRecords = records()
        return currentRecords[Self.key(appName)]?
            .rejectedSuggestionValues
            .contains(key) == true
    }

    func confirmedURLs(for appName: String) -> [URL] {
        let currentRecords = records()
        var urls: Set<URL> = []
        if let record = currentRecords[Self.key(appName)] {
            urls.formUnion(Self.confirmedURLs(
                in: record,
                excludingRejectedURLsIn: currentRecords
            ))
        }
        return urls.sorted {
            $0.absoluteString.localizedStandardCompare($1.absoluteString)
                == .orderedAscending
        }
    }

    func confirmedURLs(matchingHomepage homepage: URL) -> [URL] {
        guard let homepageHost = Self.normalizedHost(homepage) else {
            return []
        }
        let homepageURL = Self.normalizedURLString(homepage)
        let matches = records().values.filter { record in
            record.domains.contains(homepageHost)
                || record.domains.contains {
                    homepageHost.hasSuffix(".\($0)")
                        || $0.hasSuffix(".\(homepageHost)")
                }
                || record.urls
                    .compactMap(URL.init(string:))
                    .contains {
                        Self.normalizedURLString($0) == homepageURL
                    }
        }
        return Array(
            Set(matches.flatMap {
                Self.confirmedURLs(
                    in: $0,
                    excludingRejectedURLsIn: records()
                )
            })
        )
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

    private static func suggestionValueKey(
        kind: String,
        value: String
    ) -> String? {
        let normalizedValue = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(
                of: #"\s+"#,
                with: " ",
                options: .regularExpression
            )
            .lowercased()
        guard !normalizedValue.isEmpty else {
            return nil
        }
        return [
            kind.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            normalizedValue
        ].joined(separator: "\u{1F}")
    }

    private static func confirmedURLs(
        in record: Record,
        excludingRejectedURLsIn records: [String: Record]
    ) -> [URL] {
        let rejectedURLs = Set(records.values.flatMap(\.rejectedURLs))
        return record.urls
            .compactMap(URL.init(string:))
            .filter {
                !rejectedURLs.contains(Self.normalizedURLString($0))
            }
            .sorted {
                $0.absoluteString.localizedStandardCompare($1.absoluteString)
                    == .orderedAscending
            }
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
