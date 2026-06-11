import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct LocalAppIconExtractor: Sendable {
    func iconData(for appURL: URL) -> Data? {
        guard appURL.pathExtension.lowercased() == "app" else {
            return nil
        }
        if let iconURL = iconURL(for: appURL),
           let data = try? Data(contentsOf: iconURL),
           let png = IconImageConverter.compactPNG(from: data)
        {
            return png
        }
        let workspaceIcon = NSWorkspace.shared.icon(forFile: appURL.path)
        guard let data = workspaceIcon.tiffRepresentation else {
            return nil
        }
        return IconImageConverter.compactPNG(from: data)
    }

    private func iconURL(for appURL: URL) -> URL? {
        let contentsURL = appURL.appendingPathComponent(
            "Contents",
            isDirectory: true
        )
        let infoURL = contentsURL.appendingPathComponent("Info.plist")
        guard let info = NSDictionary(contentsOf: infoURL) as? [String: Any]
        else {
            return nil
        }

        let iconName = (info["CFBundleIconFile"] as? String)
            ?? (info["CFBundleIconName"] as? String)
        guard var iconName, !iconName.isEmpty else {
            return nil
        }
        if URL(fileURLWithPath: iconName).pathExtension.isEmpty {
            iconName += ".icns"
        }

        let iconURL = contentsURL
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent(iconName)
        return FileManager.default.fileExists(atPath: iconURL.path)
            ? iconURL
            : nil
    }
}
