import Foundation

final class ConfirmedMetadataMatchStore: @unchecked Sendable {
    static let shared = ConfirmedMetadataMatchStore()

    private struct Record: Codable {
        var domains: Set<String> = []
        var githubRepositories: Set<String> = []
        var appleTrackIDs: Set<Int> = []
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
        }
    }

    func domainScore(for appName: String, candidateURL: URL) -> Double {
        guard let host = Self.normalizedHost(candidateURL),
              let record = records()[Self.key(appName)]
        else {
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
}
