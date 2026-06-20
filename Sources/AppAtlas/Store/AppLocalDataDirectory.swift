import Foundation

enum AppLocalDataDirectory {
    static var url: URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent(directoryName, isDirectory: true)
    }

    static var directoryName: String {
        directoryName(
            bundleIdentifier: Bundle.main.bundleIdentifier
        )
    }

    static func directoryName(bundleIdentifier: String?) -> String {
        switch bundleIdentifier {
        case "at.schrotty.appatlas.dev":
            "AppAtlas-Dev"
        case "at.schrotty.appatlas.beta":
            "AppAtlas-Beta"
        default:
            "AppAtlas"
        }
    }
}
