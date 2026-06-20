import Foundation

@MainActor
final class OnlineEnrichmentAttemptCache {
    static let shared = OnlineEnrichmentAttemptCache()

    private let defaults = UserDefaults.standard
    private let key = "OnlineEnrichmentAttemptCache.misses"
    private let ttl: TimeInterval = 7 * 24 * 60 * 60

    private init() {}

    func shouldSkip(_ app: AppEntry) -> Bool {
        guard let date = misses[key(for: app)] else {
            return false
        }
        return Date().timeIntervalSince(date) < ttl
    }

    func recordMiss(_ app: AppEntry) {
        var values = misses
        values[key(for: app)] = Date()
        save(values)
    }

    func clear(_ app: AppEntry) {
        var values = misses
        values.removeValue(forKey: key(for: app))
        save(values)
    }

    private var misses: [String: Date] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: Date].self, from: data)
        else {
            return [:]
        }
        return decoded
    }

    private func save(_ values: [String: Date]) {
        guard let data = try? JSONEncoder().encode(values) else {
            return
        }
        defaults.set(data, forKey: key)
    }

    private func key(for app: AppEntry) -> String {
        [
            app.name.normalizedForCatalogSearch,
            app.category.normalizedForCatalogSearch,
            app.subcategory.normalizedForCatalogSearch
        ]
        .joined(separator: "|")
    }
}
