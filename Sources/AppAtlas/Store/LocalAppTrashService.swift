import Foundation

struct LocalAppTrashError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

@MainActor
struct LocalAppTrashService {
    private let sourceBookmark: ScanSourceBookmark
    private let fileManager: FileManager

    init(
        sourceBookmark: ScanSourceBookmark = ScanSourceBookmark(),
        fileManager: FileManager = .default
    ) {
        self.sourceBookmark = sourceBookmark
        self.fileManager = fileManager
    }

    func moveFilesToTrash(for app: AppEntry) throws {
        guard !app.files.isEmpty else {
            throw LocalAppTrashError(
                message: "Für diesen Katalogeintrag sind keine lokalen Dateien gespeichert."
            )
        }
        guard let rootURL = sourceBookmark.selectedURL else {
            throw LocalAppTrashError(
                message: "Der ursprüngliche Scan-Ordner ist nicht mehr verfügbar. Wähle ihn erneut über „Apps scannen“ aus."
            )
        }

        let accessed = sourceBookmark.startAccessing(rootURL)
        defer {
            sourceBookmark.stopAccessing(rootURL, ifNeeded: accessed)
        }

        let root = rootURL.standardizedFileURL
        let rootPath = root.path.hasSuffix("/") ? root.path : root.path + "/"
        let fileURLs = Set(app.files.map {
            root.appendingPathComponent($0.relativePath).standardizedFileURL
        })

        for fileURL in fileURLs {
            guard fileURL.path.hasPrefix(rootPath) else {
                throw LocalAppTrashError(
                    message: "Eine zugeordnete Datei liegt außerhalb des ausgewählten Scan-Ordners und wurde nicht verändert."
                )
            }
            guard fileManager.fileExists(atPath: fileURL.path) else {
                throw LocalAppTrashError(
                    message: "Die Datei „\(fileURL.lastPathComponent)“ wurde nicht gefunden. Der Katalogeintrag bleibt erhalten."
                )
            }
        }

        for fileURL in fileURLs {
            do {
                try fileManager.trashItem(at: fileURL, resultingItemURL: nil)
            } catch {
                throw LocalAppTrashError(
                    message: "„\(fileURL.lastPathComponent)“ konnte nicht in den Papierkorb gelegt werden: \(error.localizedDescription)"
                )
            }
        }
    }
}
