import Foundation

struct SetappCatalogMetadata: Sendable {
    let catalogURL: URL
    let description: String?
}

final class SetappCatalogMetadataCache: @unchecked Sendable {
    static let shared = SetappCatalogMetadataCache()

    private let fileURL: URL
    private let sourceURL = URL(string: "https://setapp.com/apps")!
    private let lock = NSLock()
    private var cachedIndex: [String: CatalogEntry]?

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? AppLocalDataDirectory.url
            .appendingPathComponent("setapp-catalog-cache.json")
    }

    func refresh() async throws {
        var request = URLRequest(url: sourceURL)
        request.timeoutInterval = 30
        request.setValue(
            "AppAtlas (manual catalog metadata update)",
            forHTTPHeaderField: "User-Agent"
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              data.count <= 5_000_000,
              let html = String(data: data, encoding: .utf8)
        else {
            throw SetappCatalogMetadataCacheError.invalidResponse
        }

        let catalog = try Self.parseCatalog(from: html)
        guard !catalog.entries.isEmpty else {
            throw SetappCatalogMetadataCacheError.invalidResponse
        }
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONEncoder().encode(catalog).write(to: fileURL, options: .atomic)
        lock.withLock {
            cachedIndex = nil
        }
    }

    func metadata(for app: AppEntry) -> SetappCatalogMetadata? {
        guard let index = loadIndexIfNeeded() else {
            return nil
        }
        let keys = candidateKeys(for: app)
        guard let entry = keys.lazy.compactMap({ index[$0] }).first,
              isPlausible(entry, for: app),
              let catalogURL = entry.catalogURL
        else {
            return nil
        }
        return SetappCatalogMetadata(
            catalogURL: catalogURL,
            description: entry.description
        )
    }

    private func loadIndexIfNeeded() -> [String: CatalogEntry]? {
        if let cached = lock.withLock({ cachedIndex }) {
            return cached
        }
        guard let data = try? Data(contentsOf: fileURL),
              data.count <= 1_000_000,
              let catalog = try? JSONDecoder().decode(Catalog.self, from: data)
        else {
            return nil
        }
        var index: [String: CatalogEntry] = [:]
        for entry in catalog.entries where entry.isMacApp {
            for key in entry.lookupKeys {
                index[key] = entry
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
        return Array(Set(names.map(AppNameMatcher.normalized)))
            .filter { !$0.isEmpty }
    }

    private func isPlausible(_ entry: CatalogEntry, for app: AppEntry) -> Bool {
        MetadataMatchScorer.score(
            app: app,
            candidate: MetadataMatchCandidate(
                name: entry.name,
                contextText: [entry.description, entry.slug]
                    .compactMap { $0 }
                    .joined(separator: " "),
                developer: nil,
                url: entry.catalogURL,
                bundleIdentifier: nil,
                sourceReliability: 0.92
            )
        ) >= MetadataMatchScorer.automaticThreshold
    }

    static func parseCatalog(from html: String) throws -> Catalog {
        var searchStart = html.startIndex
        let marker = "self.__next_f.push([1,\""
        while let markerRange = html.range(
            of: marker,
            range: searchStart..<html.endIndex
        ) {
            guard let payload = jsonString(
                in: html,
                startingAt: markerRange.upperBound
            ) else {
                searchStart = markerRange.upperBound
                continue
            }
            searchStart = payload.nextIndex
            guard let decoded = try? JSONDecoder().decode(
                String.self,
                from: Data(("\"" + payload.value + "\"").utf8)
            ),
            let applicationsStart = decoded.range(of: "\"applications\":[")?.upperBound,
            let arrayData = jsonArray(in: decoded, startingAt: applicationsStart),
            let entries = try? JSONDecoder().decode(
                [CatalogEntry].self,
                from: Data(arrayData.utf8)
            )
            else {
                continue
            }
            return Catalog(entries: entries)
        }
        throw SetappCatalogMetadataCacheError.invalidResponse
    }

    private static func jsonString(
        in value: String,
        startingAt start: String.Index
    ) -> (value: String, nextIndex: String.Index)? {
        var index = start
        while index < value.endIndex {
            if value[index] == "\"" {
                var slashCount = 0
                var previous = index
                while previous > start {
                    let before = value.index(before: previous)
                    guard value[before] == "\\" else { break }
                    slashCount += 1
                    previous = before
                }
                if slashCount.isMultiple(of: 2) {
                    return (String(value[start..<index]), value.index(after: index))
                }
            }
            index = value.index(after: index)
        }
        return nil
    }

    private static func jsonArray(
        in value: String,
        startingAt start: String.Index
    ) -> String? {
        var index = start
        var depth = 1
        var inString = false
        var escaped = false
        while index < value.endIndex {
            let character = value[index]
            if inString {
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                }
            } else if character == "\"" {
                inString = true
            } else if character == "[" {
                depth += 1
            } else if character == "]" {
                depth -= 1
                if depth == 0 {
                    return "[" + String(value[start..<index]) + "]"
                }
            }
            index = value.index(after: index)
        }
        return nil
    }

    struct Catalog: Codable, Sendable {
        let entries: [CatalogEntry]
    }

    struct CatalogEntry: Codable, Sendable {
        let name: String
        let description: String?
        let platform: String?
        let platforms: [String]?
        let slug: String

        var isMacApp: Bool {
            platform?.lowercased() == "mac"
                || platforms?.contains { $0.lowercased() == "mac" } == true
        }

        var lookupKeys: [String] {
            [AppNameMatcher.normalized(name)].filter { !$0.isEmpty }
        }

        var catalogURL: URL? {
            URL(string: "https://setapp.com/apps/\(slug)")
        }
    }
}

enum SetappCatalogMetadataCacheError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        "Der Setapp-Katalog konnte nicht geladen werden."
    }
}
