import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class InstalledAppIconCatalog {
    static let shared = InstalledAppIconCatalog()

    private lazy var appURLs: [String: URL] = {
        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true)
        ]
        var result: [String: URL] = [:]
        for root in roots {
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }
            while let url = enumerator.nextObject() as? URL {
                guard url.pathExtension.lowercased() == "app" else {
                    continue
                }
                enumerator.skipDescendants()
                let name = url.deletingPathExtension().lastPathComponent
                result[Self.normalized(name)] = url
            }
        }
        return result
    }()

    func icon(for appName: String) -> NSImage? {
        guard let url = appURL(for: appName) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    func compactIconData(for appName: String) -> Data? {
        guard let url = appURL(for: appName) else {
            return nil
        }
        if let data = LocalAppIconExtractor().iconData(for: url) {
            return data
        }
        return compactPNG(from: NSWorkspace.shared.icon(forFile: url.path))
    }

    private func appURL(for appName: String) -> URL? {
        let keys = Self.matchingKeys(for: appName)
        if let exact = keys.compactMap({ appURLs[$0] }).first {
            return exact
        }

        let candidates = appURLs.filter { installedKey, _ in
            keys.contains {
                $0.count >= 5
                    && installedKey.count >= 5
                    && ($0.hasPrefix(installedKey)
                    || installedKey.hasPrefix($0))
            }
        }
        return candidates.count == 1 ? candidates.first?.value : nil
    }

    private static func matchingKeys(for value: String) -> [String] {
        let normalizedValue = normalized(value)
        let displayName = AppNameNormalizer.displayName(for: value)
        let normalizedDisplayName = normalized(displayName)
        let withoutTrailingNumber = normalizedValue.replacingOccurrences(
            of: #"\d+$"#,
            with: "",
            options: .regularExpression
        )
        return Array(Set([
            normalizedValue,
            normalizedDisplayName,
            withoutTrailingNumber
        ].filter { !$0.isEmpty }))
    }

    private static func normalized(_ value: String) -> String {
        let folded = value
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .lowercased()
        return folded.filter { $0.isLetter || $0.isNumber }
    }

    private func compactPNG(from image: NSImage) -> Data? {
        let targetSize = NSSize(
            width: IconImageConverter.preferredPixelSize,
            height: IconImageConverter.preferredPixelSize
        )
        let rendered = NSImage(size: targetSize)
        rendered.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        rendered.unlockFocus()

        guard let tiff = rendered.tiffRepresentation,
              let source = CGImageSourceCreateWithData(tiff as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            return nil
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return IconImageConverter.compactPNG(from: data as Data)
    }
}
