import Foundation

struct CatalogPersistence: Sendable {
    private let fileURL: URL
    private let maximumFileSize = 100_000_000

    private var recoveryURL: URL {
        fileURL
            .deletingPathExtension()
            .appendingPathExtension("recovery.json")
    }

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
                return try recoverIfAvailable()
            }
            do {
                let apps = try decode(from: fileURL)
                try validate(apps)
                return apps
            } catch {
                try quarantineCorruptCatalog()
                return try recoverIfAvailable()
            }
        }

        return try recoverIfAvailable()
    }

    private func decode(from url: URL) throws -> [AppEntry] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([AppEntry].self, from: data)
    }

    private func quarantineOversizedCatalogIfNeeded() throws {
        let values = try fileURL.resourceValues(forKeys: [.fileSizeKey])
        guard let size = values.fileSize, size > maximumFileSize else {
            return
        }

        let quarantineURL = fileURL
            .deletingPathExtension()
            .appendingPathExtension("oversized-\(UUID().uuidString).json")
        try FileManager.default.moveItem(at: fileURL, to: quarantineURL)
    }

    func save(_ apps: [AppEntry]) throws {
        try validate(apps)
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(apps)
        guard data.count <= maximumFileSize else {
            throw CatalogPersistenceError.catalogTooLarge
        }

        let candidateURL = directory.appendingPathComponent(
            ".catalog-\(UUID().uuidString).json"
        )
        defer {
            try? FileManager.default.removeItem(at: candidateURL)
        }
        try data.write(to: candidateURL, options: .atomic)
        let candidate = try decode(from: candidateURL)
        try validate(candidate)

        if FileManager.default.fileExists(atPath: fileURL.path),
           let current = try? decode(from: fileURL),
           (try? validate(current)) != nil
        {
            try? FileManager.default.removeItem(at: recoveryURL)
            try FileManager.default.copyItem(
                at: fileURL,
                to: recoveryURL
            )
        }
        try data.write(to: fileURL, options: .atomic)
        if !FileManager.default.fileExists(atPath: recoveryURL.path) {
            try data.write(to: recoveryURL, options: .atomic)
        }
    }

    private func recoverIfAvailable() throws -> [AppEntry]? {
        guard FileManager.default.fileExists(atPath: recoveryURL.path) else {
            return nil
        }
        let apps = try decode(from: recoveryURL)
        try validate(apps)
        let data = try Data(contentsOf: recoveryURL)
        try data.write(to: fileURL, options: .atomic)
        return apps
    }

    private func quarantineCorruptCatalog() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        let quarantineURL = fileURL
            .deletingPathExtension()
            .appendingPathExtension("corrupt-\(UUID().uuidString).json")
        try FileManager.default.moveItem(at: fileURL, to: quarantineURL)
    }

    private func validate(_ apps: [AppEntry]) throws {
        let ids = apps.map(\.id)
        guard Set(ids).count == ids.count else {
            throw CatalogPersistenceError.duplicateAppIDs
        }
        let paths = apps.flatMap(\.files).map(\.relativePath)
        guard Set(paths).count == paths.count else {
            throw CatalogPersistenceError.duplicateFilePaths
        }
    }
}

enum CatalogPersistenceError: LocalizedError {
    case catalogTooLarge
    case duplicateAppIDs
    case duplicateFilePaths

    var errorDescription: String? {
        switch self {
        case .catalogTooLarge:
            "Der Katalog überschreitet die zulässige Maximalgröße."
        case .duplicateAppIDs:
            "Der Katalog enthält doppelte App-Kennungen."
        case .duplicateFilePaths:
            "Der Katalog enthält mehrfach zugeordnete Dateipfade."
        }
    }
}
