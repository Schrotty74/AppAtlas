import Foundation

final class IconStore: @unchecked Sendable {
    static let shared = IconStore()
    static let thumbnailPixelSize = 256

    private let rootURL: URL
    private let originalsURL: URL
    private let thumbnailsURL: URL
    private let cache = NSCache<NSString, NSData>()

    init(rootURL: URL? = nil) {
        let baseURL = rootURL ?? FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("AppAtlas", isDirectory: true)
        self.rootURL = baseURL
        self.originalsURL = baseURL
            .appendingPathComponent("Icons", isDirectory: true)
        self.thumbnailsURL = baseURL
            .appendingPathComponent("IconThumbnails", isDirectory: true)
        cache.totalCostLimit = 48_000_000
    }

    func save(_ data: Data, for appID: UUID) throws -> String {
        guard let original = IconImageConverter.compactPNG(from: data),
              let thumbnail = IconImageConverter.compactPNG(
                from: original,
                maximumPixelSize: Self.thumbnailPixelSize
              )
        else {
            throw IconStoreError.invalidImage
        }
        try createDirectories()
        let fileName = "\(appID.uuidString).png"
        try original.write(
            to: originalsURL.appendingPathComponent(fileName),
            options: .atomic
        )
        try thumbnail.write(
            to: thumbnailsURL.appendingPathComponent(fileName),
            options: .atomic
        )
        cache.setObject(
            thumbnail as NSData,
            forKey: thumbnailKey(fileName),
            cost: thumbnail.count
        )
        cache.setObject(
            original as NSData,
            forKey: originalKey(fileName),
            cost: original.count
        )
        return fileName
    }

    func data(fileName: String, thumbnail: Bool) -> Data? {
        let key = thumbnail ? thumbnailKey(fileName) : originalKey(fileName)
        if let cached = cache.object(forKey: key) {
            return cached as Data
        }
        let directory = thumbnail ? thumbnailsURL : originalsURL
        let url = directory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        cache.setObject(data as NSData, forKey: key, cost: data.count)
        return data
    }

    func delete(fileName: String?) {
        guard let fileName else {
            return
        }
        try? FileManager.default.removeItem(
            at: originalsURL.appendingPathComponent(fileName)
        )
        try? FileManager.default.removeItem(
            at: thumbnailsURL.appendingPathComponent(fileName)
        )
        cache.removeObject(forKey: thumbnailKey(fileName))
        cache.removeObject(forKey: originalKey(fileName))
    }

    private func createDirectories() throws {
        try FileManager.default.createDirectory(
            at: originalsURL,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: thumbnailsURL,
            withIntermediateDirectories: true
        )
    }

    private func thumbnailKey(_ fileName: String) -> NSString {
        "thumbnail:\(fileName)" as NSString
    }

    private func originalKey(_ fileName: String) -> NSString {
        "original:\(fileName)" as NSString
    }
}

enum IconStoreError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        "Das Bild konnte nicht als App-Icon gespeichert werden."
    }
}
