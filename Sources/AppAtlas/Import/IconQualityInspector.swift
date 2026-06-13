import Foundation
import ImageIO

enum IconQualityInspector {
    static func isLikelyAppIcon(_ data: Data) -> Bool {
        dimensions(in: data).map {
            $0.width >= 32
                && $0.height >= 32
                && (0.82...1.22).contains($0.width / $0.height)
        } ?? false
    }

    static func isLikelyOnlineAppIcon(_ data: Data) -> Bool {
        dimensions(in: data).map {
            $0.width >= 128
                && $0.height >= 128
                && (0.9...1.1).contains($0.width / $0.height)
        } ?? false
    }

    private static func dimensions(
        in data: Data
    ) -> (width: CGFloat, height: CGFloat)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(
                source,
                0,
                nil
              ) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat,
              width > 0,
              height > 0
        else {
            return nil
        }
        return (width, height)
    }
}
