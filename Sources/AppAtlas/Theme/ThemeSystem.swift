import Foundation
import SwiftUI

enum AppAtlasTheme: String, CaseIterable, Identifiable {
    case system
    case classicLight = "classic-light"
    case classicDark = "classic-dark"
    case violetNight = "violet-night"
    case highContrast = "high-contrast"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .classicLight: "Classic Hell"
        case .classicDark: "Classic Dunkel"
        case .violetNight: "Violet Night"
        case .highContrast: "High Contrast"
        }
    }

    var definition: AppAtlasThemeDefinition {
        switch self {
        case .system, .classicLight:
            Self.definition(
                id: rawValue,
                mode: "light",
                text: "#172024",
                mutedText: "#60706D",
                background: "#F6FBFA",
                backgroundAlt: "#EAF5F2",
                panel: "#FFFFFF",
                panelSoft: "#F2F8F6",
                border: "#C8D8D5",
                accent: "#4D79E6",
                accentText: "#FFFFFF"
            )
        case .classicDark:
            Self.definition(
                id: rawValue,
                mode: "dark",
                text: "#F6FBFA",
                mutedText: "#C9D4D2",
                background: "#0E171A",
                backgroundAlt: "#172326",
                panel: "#142024",
                panelSoft: "#1B292C",
                border: "#3E5E59",
                accent: "#6F92FF",
                accentText: "#FFFFFF"
            )
        case .violetNight:
            Self.definition(
                id: rawValue,
                mode: "dark",
                text: "#FFF7FF",
                mutedText: "#D8CBE3",
                background: "#1C1B29",
                backgroundAlt: "#2E2945",
                panel: "#292638",
                panelSoft: "#3B344F",
                border: "#70588A",
                accent: "#B58CFF",
                accentText: "#181020"
            )
        case .highContrast:
            Self.definition(
                id: rawValue,
                mode: "dark",
                text: "#FFFFFF",
                mutedText: "#FFFFFF",
                background: "#000000",
                backgroundAlt: "#000000",
                panel: "#000000",
                panelSoft: "#111111",
                border: "#FFFFFF",
                accent: "#FFFF00",
                accentText: "#000000"
            )
        }
    }

    var style: ThemeStyle {
        if self == .system {
            return ThemeStyle(
                id: rawValue,
                preferredScheme: nil,
                isHighContrast: false,
                text: Color(nsColor: .labelColor),
                mutedText: Color(nsColor: .secondaryLabelColor),
                background: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor),
                    Color.accentColor.opacity(0.07)
                ],
                panel: Color(nsColor: .controlBackgroundColor).opacity(0.92),
                panelSoft: Color(nsColor: .controlBackgroundColor).opacity(0.66),
                border: Color(nsColor: .separatorColor),
                accent: .accentColor,
                accentText: Color(nsColor: .selectedMenuItemTextColor),
                glassBorderOpacity: 0.24,
                shadowOpacity: 0.14
            )
        }
        return definition.makeStyle(isHighContrast: self == .highContrast)
    }

    func exportCopy(
        existingIDs: Set<String>
    ) throws -> AppAtlasThemeDefinition {
        let baseID = "\(rawValue)-custom"
        var id = baseID
        var index = 2
        while AppAtlasThemeDefinition.builtInIDs.contains(id)
            || existingIDs.contains(id)
        {
            id = "\(baseID)-\(index)"
            index += 1
        }

        var copy = definition
        copy.id = id
        copy.name = .init(de: "\(title) Kopie", en: "\(title) Copy")
        return try copy.validated()
    }

    private static func definition(
        id: String,
        mode: String,
        text: String,
        mutedText: String,
        background: String,
        backgroundAlt: String,
        panel: String,
        panelSoft: String,
        border: String,
        accent: String,
        accentText: String
    ) -> AppAtlasThemeDefinition {
        AppAtlasThemeDefinition(
            format: "appatlas-theme",
            version: 1,
            id: id,
            name: .init(de: id, en: id),
            mode: mode,
            colors: .init(
                text: text,
                mutedText: mutedText,
                background: background,
                backgroundAlt: backgroundAlt,
                panel: panel,
                panelSoft: panelSoft,
                border: border,
                accent: accent,
                accentText: accentText
            ),
            effects: .init(
                glassOpacity: 0.84,
                glassBorderOpacity: 0.28,
                shadowOpacity: mode == "dark" ? 0.28 : 0.14
            )
        )
    }
}

struct ThemeStyle {
    let id: String
    let preferredScheme: ColorScheme?
    let isHighContrast: Bool
    let text: Color
    let mutedText: Color
    let background: [Color]
    let panel: Color
    let panelSoft: Color
    let border: Color
    let accent: Color
    let accentText: Color
    let glassBorderOpacity: Double
    let shadowOpacity: Double

    var isDark: Bool { preferredScheme == .dark }

    static func resolve(
        id: String,
        customThemes: [AppAtlasThemeDefinition]
    ) -> ThemeStyle {
        if let builtIn = AppAtlasTheme(rawValue: id) {
            return builtIn.style
        }
        if let custom = customThemes.first(where: { $0.id == id }) {
            return custom.style
        }
        return AppAtlasTheme.system.style
    }
}

struct AppAtlasThemeDefinition: Codable, Identifiable, Equatable {
    struct ThemeName: Codable, Equatable {
        var de: String?
        var en: String?
    }

    struct ThemeColors: Codable, Equatable {
        var text: String
        var mutedText: String?
        var background: String
        var backgroundAlt: String?
        var panel: String
        var panelSoft: String?
        var border: String?
        var accent: String
        var accentText: String?
    }

    struct ThemeEffects: Codable, Equatable {
        var glassOpacity: Double?
        var glassBorderOpacity: Double?
        var shadowOpacity: Double?
    }

    var format: String
    var version: Int
    var id: String
    var name: ThemeName
    var mode: String
    var colors: ThemeColors
    var effects: ThemeEffects?

    static let builtInIDs = Set(AppAtlasTheme.allCases.map(\.rawValue))

    func title() -> String {
        name.de ?? name.en ?? id
    }

    var style: ThemeStyle {
        makeStyle()
    }

    func makeStyle(isHighContrast: Bool = false) -> ThemeStyle {
        let isDark = mode == "dark"
        let accent = Color(hex: colors.accent) ?? .blue
        let text = Color(hex: colors.text) ?? (isDark ? .white : .black)
        let background = Color(hex: colors.background)
            ?? (isDark ? .black : .white)
        let backgroundAlt = Color(hex: colors.backgroundAlt)
            ?? Color(hex: colors.panelSoft)
            ?? background
        let panel = Color(hex: colors.panel) ?? background
        let panelSoft = Color(hex: colors.panelSoft) ?? panel
        let glassOpacity = effects?.glassOpacity ?? 0.84

        return ThemeStyle(
            id: id,
            preferredScheme: isDark ? .dark : .light,
            isHighContrast: isHighContrast,
            text: text,
            mutedText: Color(hex: colors.mutedText) ?? text.opacity(0.68),
            background: [background, backgroundAlt, panelSoft.opacity(0.58)],
            panel: panel.opacity(glassOpacity),
            panelSoft: panelSoft.opacity(max(0.48, glassOpacity - 0.16)),
            border: Color(hex: colors.border)
                ?? accent.opacity(effects?.glassBorderOpacity ?? 0.28),
            accent: accent,
            accentText: Color(hex: colors.accentText)
                ?? (isDark ? .black : .white),
            glassBorderOpacity: effects?.glassBorderOpacity ?? 0.28,
            shadowOpacity: effects?.shadowOpacity ?? (isDark ? 0.28 : 0.14)
        )
    }

    func validated() throws -> AppAtlasThemeDefinition {
        guard format == "appatlas-theme" else {
            throw ThemeImportError.invalidFormat
        }
        try validateSharedFields()
        return self
    }

    fileprivate func validateSharedFields() throws {
        guard version == 1 else {
            throw ThemeImportError.invalidVersion
        }
        guard id.range(
            of: #"^[a-z0-9][a-z0-9-]*$"#,
            options: .regularExpression
        ) != nil else {
            throw ThemeImportError.invalidID
        }
        guard !Self.builtInIDs.contains(id) else {
            throw ThemeImportError.builtInID
        }
        guard mode == "light" || mode == "dark" else {
            throw ThemeImportError.invalidMode
        }
        guard !(name.de ?? name.en ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        else {
            throw ThemeImportError.missingName
        }

        let colors = [
            colors.text,
            colors.mutedText,
            colors.background,
            colors.backgroundAlt,
            colors.panel,
            colors.panelSoft,
            colors.border,
            colors.accent,
            colors.accentText
        ].compactMap { $0 }
        guard colors.allSatisfy(Color.isHexColor) else {
            throw ThemeImportError.invalidColor
        }

        let effects = [
            effects?.glassOpacity,
            effects?.glassBorderOpacity,
            effects?.shadowOpacity
        ].compactMap { $0 }
        guard effects.allSatisfy({ $0 >= 0 && $0 <= 1 }) else {
            throw ThemeImportError.invalidEffect
        }
    }

    static func decodeList(_ raw: String) -> [AppAtlasThemeDefinition] {
        guard let data = raw.data(using: .utf8) else {
            return []
        }

        if let themes = try? JSONDecoder().decode(
            [AppAtlasThemeDefinition].self,
            from: data
        ) {
            let validatedThemes = themes.compactMap { try? $0.validated() }
            if themes.isEmpty || !validatedThemes.isEmpty {
                return validatedThemes
            }
        }

        // One-time migration for themes stored by the earlier implementation.
        if let legacyThemes = try? JSONDecoder().decode(
            [LegacyUroBilanzTheme].self,
            from: data
        ) {
            return legacyThemes.compactMap { try? $0.appAtlasTheme() }
        }
        return []
    }

    static func encodeList(_ themes: [AppAtlasThemeDefinition]) -> String {
        guard let data = try? JSONEncoder().encode(themes),
              let raw = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return raw
    }
}

enum ThemeDocumentDecoder {
    static func decode(_ data: Data) throws -> AppAtlasThemeDefinition {
        let format = try JSONDecoder().decode(ThemeFormatProbe.self, from: data)
            .format

        switch format {
        case "appatlas-theme":
            return try JSONDecoder()
                .decode(AppAtlasThemeDefinition.self, from: data)
                .validated()
        case "urobilanz-theme":
            return try JSONDecoder()
                .decode(LegacyUroBilanzTheme.self, from: data)
                .appAtlasTheme()
        default:
            throw ThemeImportError.invalidFormat
        }
    }
}

private struct ThemeFormatProbe: Decodable {
    let format: String
}

private struct LegacyUroBilanzTheme: Decodable {
    let format: String
    let version: Int
    let id: String
    let name: AppAtlasThemeDefinition.ThemeName
    let mode: String
    let colors: AppAtlasThemeDefinition.ThemeColors
    let effects: AppAtlasThemeDefinition.ThemeEffects?

    func appAtlasTheme() throws -> AppAtlasThemeDefinition {
        guard format == "urobilanz-theme" else {
            throw ThemeImportError.invalidFormat
        }
        let converted = AppAtlasThemeDefinition(
            format: "appatlas-theme",
            version: version,
            id: id,
            name: name,
            mode: mode,
            colors: colors,
            effects: effects
        )
        try converted.validateSharedFields()
        return converted
    }
}

enum ThemeImportError: LocalizedError {
    case invalidFormat
    case invalidVersion
    case invalidID
    case builtInID
    case invalidMode
    case missingName
    case invalidColor
    case invalidEffect

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            "Theme-Format wird nicht erkannt."
        case .invalidVersion:
            "Theme-Version wird nicht unterstützt."
        case .invalidID:
            "Theme-ID darf nur Kleinbuchstaben, Zahlen und Bindestriche enthalten."
        case .builtInID:
            "Eingebaute Themes dürfen nicht überschrieben werden."
        case .invalidMode:
            "Theme-Modus muss light oder dark sein."
        case .missingName:
            "Theme-Name fehlt."
        case .invalidColor:
            "Eine Theme-Farbe fehlt oder ist ungültig."
        case .invalidEffect:
            "Theme-Effekte müssen zwischen 0 und 1 liegen."
        }
    }
}

extension Color {
    init?(hex: String?) {
        guard let hex else {
            return nil
        }
        let clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isHexColor(clean),
              let rgb = Int(clean.dropFirst(), radix: 16)
        else {
            return nil
        }
        self.init(
            red: Double((rgb >> 16) & 0xff) / 255,
            green: Double((rgb >> 8) & 0xff) / 255,
            blue: Double(rgb & 0xff) / 255
        )
    }

    static func isHexColor(_ value: String) -> Bool {
        value.range(
            of: #"^#[0-9A-Fa-f]{6}$"#,
            options: .regularExpression
        ) != nil
    }
}

private struct AppAtlasThemeKey: EnvironmentKey {
    static let defaultValue = AppAtlasTheme.system.style
}

extension EnvironmentValues {
    var appAtlasTheme: ThemeStyle {
        get { self[AppAtlasThemeKey.self] }
        set { self[AppAtlasThemeKey.self] = newValue }
    }
}

struct AppAtlasBackground: View {
    @Environment(\.appAtlasTheme) private var theme

    var body: some View {
        LinearGradient(
            colors: theme.background,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct ThemedPanelModifier: ViewModifier {
    @Environment(\.appAtlasTheme) private var theme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                theme.panel,
                in: RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
                .stroke(
                    theme.border.opacity(
                        theme.isHighContrast
                            ? 1
                            : theme.glassBorderOpacity + 0.35
                    ),
                    lineWidth: theme.isHighContrast ? 1.5 : 1
                )
            }
            .shadow(
                color: .black.opacity(theme.shadowOpacity),
                radius: 12,
                y: 5
            )
    }
}

extension View {
    func themedPanel(cornerRadius: CGFloat = 18) -> some View {
        modifier(ThemedPanelModifier(cornerRadius: cornerRadius))
    }
}
