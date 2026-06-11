import Foundation

struct CatalogPersistence: Sendable {
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
            return
        }

        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        self.fileURL = applicationSupport
            .appendingPathComponent("AppAtlas", isDirectory: true)
            .appendingPathComponent("catalog.json")
    }

    func load() throws -> [AppEntry]? {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try quarantineOversizedCatalogIfNeeded()
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return nil
            }
            return try decode(from: fileURL)
        }

        return nil
    }

    private func decode(from url: URL) throws -> [AppEntry] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([AppEntry].self, from: data)
    }

    private func quarantineOversizedCatalogIfNeeded() throws {
        let values = try fileURL.resourceValues(forKeys: [.fileSizeKey])
        guard let size = values.fileSize, size > 100_000_000 else {
            return
        }

        let quarantineURL = fileURL
            .deletingPathExtension()
            .appendingPathExtension("oversized-\(Int(Date().timeIntervalSince1970)).json")
        try FileManager.default.moveItem(at: fileURL, to: quarantineURL)
    }

    func save(_ apps: [AppEntry]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(apps)
        try data.write(to: fileURL, options: .atomic)
    }
}
