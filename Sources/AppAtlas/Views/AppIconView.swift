import AppKit
import SwiftUI

struct AppIconView: View {
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme
    @State private var storedImage: NSImage?

    let app: AppEntry
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let storedImage {
                Image(nsImage: storedImage)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.05)
                    .background(theme.panelSoft)
            } else {
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
        .clipShape(
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .stroke(theme.border.opacity(0.65), lineWidth: 1)
        }
        .shadow(
            color: .black.opacity(theme.shadowOpacity),
            radius: max(3, size * 0.08),
            y: max(1, size * 0.03)
        )
        .accessibilityLabel("Icon von \(app.name)")
        .task(id: "\(app.iconFileName ?? "")-\(app.iconData?.count ?? 0)-\(Int(size))-\(store.catalogRevision)") {
            if let iconData = app.iconData {
                storedImage = NSImage(data: iconData)
                return
            }
            guard let fileName = app.iconFileName else {
                storedImage = nil
                return
            }
            let useThumbnail = size <= 256
            let data = await Task.detached {
                IconStore.shared.data(
                    fileName: fileName,
                    thumbnail: useThumbnail
                )
            }.value
            storedImage = data.flatMap(NSImage.init(data:))
        }
    }

    private var fallbackIcon: some View {
        ZStack {
            LinearGradient(
                colors: [
                    theme.accent.opacity(0.92),
                    theme.accent.opacity(0.48),
                    theme.panelSoft
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: categorySymbol)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(theme.accentText)

            Text(initials)
                .font(.system(size: size * 0.17, weight: .black))
                .foregroundStyle(theme.accentText.opacity(0.88))
                .padding(size * 0.08)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    private var initials: String {
        let words = app.name
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        let initials = words.prefix(2).compactMap(\.first)
        return String(initials).uppercased()
    }

    private var categorySymbol: String {
        let value = "\(app.category) \(app.subcategory)".lowercased()
        let symbols: [(terms: [String], symbol: String)] = [
            (["video", "film"], "video.fill"),
            (["audio", "musik"], "waveform"),
            (["foto", "grafik", "bild"], "photo.fill"),
            (["screenshot"], "camera.viewfinder"),
            (["backup", "sicherung"], "externaldrive.fill.badge.timemachine"),
            (["browser"], "globe"),
            (["entwicklung", "developer"], "hammer.fill"),
            (["package-manager", "homebrew"], "shippingbox.fill"),
            (["ki", "chatbot"], "sparkles"),
            (["office", "pdf", "text"], "doc.text.fill"),
            (["sicherheit", "passwort"], "lock.shield.fill"),
            (["netzwerk", "cloud"], "network"),
            (["download"], "arrow.down.circle.fill"),
            (["gaming", "spiel"], "gamecontroller.fill"),
            (["emulation"], "arcade.stick.console.fill"),
            (["hardware", "treiber"], "cpu.fill"),
            (["system"], "gearshape.2.fill"),
            (["wallpaper"], "macwindow"),
            (["packer", "archiv"], "archivebox.fill"),
            (["mobile", "android", "ios"], "iphone")
        ]
        return symbols.first {
            $0.terms.contains { value.contains($0) }
        }?.symbol ?? "app.fill"
    }
}
