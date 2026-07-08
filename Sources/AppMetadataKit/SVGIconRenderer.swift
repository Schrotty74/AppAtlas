import AppKit

@MainActor
public enum SVGIconRenderer {
    public static func compactPNG(
        from svgData: Data,
        pointSize: CGFloat = 512
    ) async -> Data? {
        guard let sourceImage = NSImage(data: svgData) else {
            return nil
        }
        let size = NSSize(width: pointSize, height: pointSize)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()
        sourceImage.draw(
            in: NSRect(origin: .zero, size: size),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation else {
            return nil
        }
        return IconImageConverter.compactPNG(
            from: tiff,
            maximumPixelSize: Int(pointSize)
        )
    }
}
