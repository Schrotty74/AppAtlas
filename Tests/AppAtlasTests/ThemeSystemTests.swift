import Foundation
import Testing
@testable import AppAtlas

struct ThemeSystemTests {
    @Test
    func importsAppAtlasTheme() throws {
        let data = try Data(contentsOf: themeFile("example-custom-theme.json"))
        let theme = try ThemeDocumentDecoder.decode(data)

        #expect(theme.format == "appatlas-theme")
        #expect(theme.id == "harbor-night")
        #expect(theme.title() == "Hafen Nacht")
        #expect(theme.style.preferredScheme == .dark)
    }

    @Test
    func exportsOnlyAppAtlasFields() throws {
        let copy = try AppAtlasTheme.classicDark.exportCopy(
            existingIDs: ["classic-dark-custom"]
        )
        let data = try JSONEncoder().encode(copy)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(copy.format == "appatlas-theme")
        #expect(copy.version == 1)
        #expect(copy.id == "classic-dark-custom-2")
        #expect(json.contains("\"text\""))
        #expect(json.contains("\"accent\""))
        #expect(!json.contains("\"row"))
        #expect(!json.contains("\"chart"))
    }

    @Test
    func convertsLegacyThemeToAppAtlasFormat() throws {
        let data = Data(
            """
            {
              "format": "urobilanz-theme",
              "version": 1,
              "id": "legacy-night",
              "name": {"de": "Altes Nacht-Theme"},
              "mode": "dark",
              "colors": {
                "text": "#F5F7FA",
                "background": "#101418",
                "panel": "#1E2930",
                "accent": "#6F92FF",
                "unusedLegacyColor": "#123456"
              }
            }
            """.utf8
        )

        let theme = try ThemeDocumentDecoder.decode(data)
        let exported = try JSONEncoder().encode(theme)
        let json = try #require(String(data: exported, encoding: .utf8))

        #expect(theme.format == "appatlas-theme")
        #expect(theme.id == "legacy-night")
        #expect(!json.contains("unusedLegacyColor"))
    }

    @Test
    func rejectsProtectedBuiltInID() throws {
        let data = try Data(contentsOf: themeFile("example-custom-theme.json"))
        var theme = try ThemeDocumentDecoder.decode(data)
        theme.id = AppAtlasTheme.classicLight.rawValue

        #expect(throws: ThemeImportError.self) {
            try theme.validated()
        }
    }

    @Test
    func customThemeListRoundTrips() throws {
        let data = try Data(contentsOf: themeFile("example-custom-theme.json"))
        let theme = try ThemeDocumentDecoder.decode(data)

        let raw = AppAtlasThemeDefinition.encodeList([theme])
        let decoded = AppAtlasThemeDefinition.decodeList(raw)

        #expect(decoded == [theme])
    }

    private func themeFile(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/themes")
            .appendingPathComponent(name)
    }
}
