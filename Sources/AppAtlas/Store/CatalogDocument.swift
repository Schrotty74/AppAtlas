import Foundation

struct CatalogDocument: Codable, Sendable {
    let format: String
    let version: Int
    let exportedAt: Date
    let apps: [AppEntry]

    init(apps: [AppEntry]) {
        self.format = "appatlas-catalog"
        self.version = 1
        self.exportedAt = Date()
        self.apps = apps
    }

    static func decode(_ data: Data) throws -> CatalogDocument {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let document = try decoder.decode(CatalogDocument.self, from: data)
        guard document.format == "appatlas-catalog",
              document.version == 1
        else {
            throw CatalogDocumentError.unsupportedFormat
        }
        return document
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

enum CatalogDocumentError: LocalizedError {
    case unsupportedFormat

    var errorDescription: String? {
        "Die Datei ist kein unterstützter AppAtlas-Katalog."
    }
}
