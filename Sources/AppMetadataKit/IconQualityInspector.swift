import Foundation
import CoreGraphics
import ImageIO

public enum IconQualityInspector {
    public static func isLikelyAppIcon(_ data: Data) -> Bool {
        isLikelyAppIcon(data, minimumPixelSize: 32)
    }

    public static func isLikelyAppIcon(
        _ data: Data,
        minimumPixelSize: CGFloat
    ) -> Bool {
        dimensions(in: data).map { dimensions in
            dimensions.width >= minimumPixelSize
                && dimensions.height >= minimumPixelSize
                && (0.82...1.22).contains(dimensions.width / dimensions.height)
                && !isNearWhitePlaceholder(data)
        } ?? false
    }

    public static func isLikelyOnlineAppIcon(_ data: Data) -> Bool {
        isLikelyAppIcon(data, minimumPixelSize: 128)
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

    private static func isNearWhitePlaceholder(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            return false
        }

        let sampleSize = 32
        var pixels = [UInt8](repeating: 0, count: sampleSize * sampleSize * 4)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: &pixels,
                width: sampleSize,
                height: sampleSize,
                bitsPerComponent: 8,
                bytesPerRow: sampleSize * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else {
            return false
        }

        context.interpolationQuality = .medium
        context.draw(
            image,
            in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize)
        )

        var weightedBrightness = 0.0
        var totalAlpha = 0.0
        let visibleAlphaThreshold = 0.10
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = Double(pixels[index + 3]) / 255
            guard alpha >= visibleAlphaThreshold else {
                continue
            }
            let red = Double(pixels[index]) / 255
            let green = Double(pixels[index + 1]) / 255
            let blue = Double(pixels[index + 2]) / 255
            let brightness = (red * 0.2126) + (green * 0.7152) + (blue * 0.0722)
            weightedBrightness += brightness * alpha
            totalAlpha += alpha
        }
        guard totalAlpha > 0 else {
            return false
        }
        return weightedBrightness / totalAlpha > 0.90
    }
}
