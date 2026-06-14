import AppKit
import SwiftUI

struct AppAtlasMark: View {
    let size: CGFloat

    var body: some View {
        Image(nsImage: appIcon)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("AppAtlas")
    }

    private var appIcon: NSImage {
        guard let url = AppResources.bundle.url(
            forResource: "AppIcon",
            withExtension: "png"
        ) else {
            return NSImage()
        }
        return NSImage(contentsOf: url) ?? NSImage()
    }
}

struct GitHubMark: View {
    @Environment(\.colorScheme) private var colorScheme
    let size: CGFloat

    var body: some View {
        Button {
            NSWorkspace.shared.open(
                URL(string: "https://github.com/Schrotty74/AppAtlas")!
            )
        } label: {
            ZStack {
                RoundedRectangle(
                    cornerRadius: size * 0.22,
                    style: .continuous
                )
                .fill(markBackground)
                .overlay {
                    RoundedRectangle(
                        cornerRadius: size * 0.22,
                        style: .continuous
                    )
                    .strokeBorder(markBorder, lineWidth: 1)
                }

                Image(nsImage: githubImage)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.12)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .help("AppAtlas auf GitHub")
        .accessibilityLabel("AppAtlas auf GitHub")
    }

    private var githubImage: NSImage {
        let fileName = colorScheme == .dark
            ? "github-invertocat-black"
            : "github-invertocat-white"
        guard let url = AppResources.bundle.url(
            forResource: fileName,
            withExtension: "svg"
        ) else {
            return NSImage()
        }
        return NSImage(contentsOf: url) ?? NSImage()
    }

    private var markBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.96)
            : Color.black.opacity(0.88)
    }

    private var markBorder: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.72)
            : Color.black.opacity(0.42)
    }
}

struct ThemeMenu: View {
    @Environment(\.appAtlasTheme) private var theme
    @Binding var selectedThemeID: String
    let customThemes: [AppAtlasThemeDefinition]
    let importTheme: () -> Void
    let exportTheme: () -> Void
    let deleteTheme: () -> Void

    private var selectedTitle: String {
        if let builtIn = AppAtlasTheme(rawValue: selectedThemeID) {
            return builtIn.title
        }
        if let custom = customThemes.first(where: { $0.id == selectedThemeID }) {
            return custom.title()
        }
        return AppAtlasTheme.system.title
    }

    var body: some View {
        Menu {
            ForEach(AppAtlasTheme.allCases) { option in
                Button {
                    selectedThemeID = option.rawValue
                } label: {
                    optionLabel(
                        option.title,
                        isSelected: option.rawValue == selectedThemeID
                    )
                }
            }

            if !customThemes.isEmpty {
                Divider()
                ForEach(customThemes) { option in
                    Button {
                        selectedThemeID = option.id
                    } label: {
                        optionLabel(
                            option.title(),
                            isSelected: option.id == selectedThemeID
                        )
                    }
                }
            }

            Divider()

            Button("Theme importieren", systemImage: "square.and.arrow.down") {
                importTheme()
            }
            Button("Theme exportieren", systemImage: "square.and.arrow.up") {
                exportTheme()
            }
            Button("Theme löschen", systemImage: "trash", role: .destructive) {
                deleteTheme()
            }
            .disabled(
                customThemes.first(where: { $0.id == selectedThemeID }) == nil
            )
        } label: {
            HStack(spacing: 7) {
                Circle()
                    .fill(theme.accent)
                    .frame(width: 10, height: 10)
                Text(selectedTitle)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2.bold())
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(theme.text)
            .padding(.horizontal, 10)
            .frame(height: 32)
            .appAtlasGlassSurface(
                in: RoundedRectangle(cornerRadius: 9, style: .continuous),
                fallbackColor: theme.panel,
                tint: theme.accent.opacity(0.10),
                interactive: true
            )
        }
        .buttonStyle(.plain)
        .menuStyle(.borderlessButton)
        .help("Theme auswählen oder verwalten")
    }

    @ViewBuilder
    private func optionLabel(_ title: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }
}
