import Testing
@testable import AppAtlas

struct ErrorReportTests {
    @Test
    func reportContainsUsefulSystemDataWithoutPrivateCatalogData() {
        let report = ErrorReport(
            title: "Fenster bleibt leer",
            description: "Nach dem Start erscheint kein Inhalt.",
            steps: "App starten",
            expectedBehavior: "Katalogansicht erscheint",
            appVersion: "1.0.0-test",
            buildNumber: "42",
            systemVersion: "macOS Test",
            architecture: "arm64"
        )

        #expect(report.subject == "AppAtlas Fehlerbericht: Fenster bleibt leer")
        #expect(report.text.contains("1.0.0-test (Build 42)"))
        #expect(report.text.contains("macOS Test"))
        #expect(report.text.contains("arm64"))
        #expect(!report.text.contains("/" + "Users/"))
        #expect(!report.text.contains("/" + "Volumes/"))
        #expect(!report.text.contains("Seriennummer"))
    }
}
