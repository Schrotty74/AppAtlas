import Foundation

@MainActor
final class ScanSourceBookmark: ObservableObject {
    @Published private(set) var selectedURL: URL?

    private let defaults: UserDefaults
    private static let bookmarkKey = "AppAtlas.scanSourceBookmark"
    private static let displayPathKey = "AppAtlas.scanSourceDisplayPath"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedURL = Self.resolveBookmark(from: defaults)
    }

    var displayPath: String {
        selectedURL?.path
            ?? defaults.string(forKey: Self.displayPathKey)
            ?? "Kein Quellordner ausgewählt"
    }

    func save(_ url: URL) throws {
        let data = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        defaults.set(data, forKey: Self.bookmarkKey)
        defaults.set(url.path, forKey: Self.displayPathKey)
        selectedURL = url
    }

    func startAccessing(_ url: URL) -> Bool {
        url.startAccessingSecurityScopedResource()
    }

    func stopAccessing(_ url: URL, ifNeeded accessed: Bool) {
        if accessed {
            url.stopAccessingSecurityScopedResource()
        }
    }

    private static func resolveBookmark(from defaults: UserDefaults) -> URL? {
        guard let data = defaults.data(forKey: bookmarkKey) else {
            return nil
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                let refreshedData = try url.bookmarkData(
                    options: [.withSecurityScope],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                defaults.set(refreshedData, forKey: bookmarkKey)
            }
            return url
        } catch {
            return nil
        }
    }
}
