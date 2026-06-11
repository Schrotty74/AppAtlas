import Foundation
import ImageIO
import UniformTypeIdentifiers

enum IconImageConverter {
    static let maximumStoredBytes = 4_000_000
    static let preferredPixelSize = 1024

    static func compactPNG(
        from data: Data,
        maximumPixelSize: Int = preferredPixelSize
    ) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil)
        else {
            return nil
        }
        let properties = CGImageSourceCopyPropertiesAtIndex(
            source,
            0,
            nil
        ) as? [CFString: Any]
        let width = properties?[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties?[kCGImagePropertyPixelHeight] as? Int ?? 0
        let type = CGImageSourceGetType(source) as String?

        if type == UTType.png.identifier,
           max(width, height) <= maximumPixelSize,
           data.count <= maximumStoredBytes
        {
            return data
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else {
            return nil
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination),
              output.length <= maximumStoredBytes
        else {
            return nil
        }
        return output as Data
    }
}
