import Foundation
import ImageIO

enum IconQualityInspector {
    static func isLikelyAppIcon(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(
                source,
                0,
                nil
              ) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat,
              width >= 32,
              height >= 32
        else {
            return false
        }
        return (0.82...1.22).contains(width / height)
    }
}
