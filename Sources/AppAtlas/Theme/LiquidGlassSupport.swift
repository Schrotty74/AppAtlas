import SwiftUI

struct AppAtlasGlassSurfaceModifier<S: Shape>: ViewModifier {
    @Environment(\.appAtlasTheme) private var theme

    let shape: S
    let fallbackColor: Color
    let tint: Color?
    let interactive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *), !theme.isHighContrast {
            content.glassEffect(
                .regular
                    .tint(tint)
                    .interactive(interactive),
                in: shape
            )
        } else {
            content.background(fallbackColor, in: shape)
        }
    }
}

struct AppAtlasSidebarSurfaceModifier: ViewModifier {
    @Environment(\.appAtlasTheme) private var theme

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *), !theme.isHighContrast {
            content.background(.clear)
        } else {
            content.background(theme.panelSoft)
        }
    }
}

struct AppAtlasSidebarSelectionModifier: ViewModifier {
    @Environment(\.appAtlasTheme) private var theme
    let isSelected: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *), !theme.isHighContrast {
            content
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .glassEffect(
                    isSelected
                        ? .regular.tint(theme.accent.opacity(0.42)).interactive()
                        : .identity,
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
        } else {
            content
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    isSelected ? theme.accent.opacity(0.18) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
        }
    }
}

extension View {
    func appAtlasGlassSurface<S: Shape>(
        in shape: S,
        fallbackColor: Color,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        modifier(
            AppAtlasGlassSurfaceModifier(
                shape: shape,
                fallbackColor: fallbackColor,
                tint: tint,
                interactive: interactive
            )
        )
    }

    func appAtlasSidebarSurface() -> some View {
        modifier(AppAtlasSidebarSurfaceModifier())
    }

    func appAtlasSidebarSelection(_ isSelected: Bool) -> some View {
        modifier(AppAtlasSidebarSelectionModifier(isSelected: isSelected))
    }
}
