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

        let candidates = appURLs.compactMap { installedKey, url -> (URL, Double)? in
            let score = keys.map {
                AppNameMatcher.similarity($0, installedKey)
            }.max() ?? 0
            return score >= 0.9 ? (url, score) : nil
        }
        .sorted { $0.1 > $1.1 }
        guard let best = candidates.first,
              candidates.count == 1
                || best.1 - candidates[1].1 >= 0.08
        else {
            return nil
        }
        return best.0
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
