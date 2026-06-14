import Foundation

struct ErrorReport {
    static let emailAddress = "appatlas@mailbox.org"

    let title: String
    let description: String
    let steps: String
    let expectedBehavior: String
    let appVersion: String
    let buildNumber: String
    let systemVersion: String
    let architecture: String

    static func current(
        title: String,
        description: String,
        steps: String,
        expectedBehavior: String
    ) -> ErrorReport {
        let bundle = Bundle.main
        return ErrorReport(
            title: title,
            description: description,
            steps: steps,
            expectedBehavior: expectedBehavior,
            appVersion: bundle.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String ?? "Entwicklungsstand",
            buildNumber: bundle.object(
                forInfoDictionaryKey: "CFBundleVersion"
            ) as? String ?? "unbekannt",
            systemVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            architecture: currentArchitecture
        )
    }

    var subject: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty
            ? "AppAtlas Fehlerbericht"
            : "AppAtlas Fehlerbericht: \(trimmedTitle)"
    }

    var text: String {
        """
        # AppAtlas Fehlerbericht

        ## Problem
        \(valueOrPlaceholder(description))

        ## Schritte zum Nachstellen
        \(valueOrPlaceholder(steps))

        ## Erwartetes Verhalten
        \(valueOrPlaceholder(expectedBehavior))

        ## Technische Angaben
        - AppAtlas: \(appVersion) (Build \(buildNumber))
        - macOS: \(systemVersion)
        - Architektur: \(architecture)

        ## Datenschutz
        Der Bericht enthält keine Katalog-, Lizenz- oder lokalen Pfaddaten.
        """
    }

    private func valueOrPlaceholder(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Nicht angegeben" : trimmed
    }

    private static var currentArchitecture: String {
#if arch(arm64)
        "arm64"
#elseif arch(x86_64)
        "x86_64"
#else
        "unbekannt"
#endif
    }
}
