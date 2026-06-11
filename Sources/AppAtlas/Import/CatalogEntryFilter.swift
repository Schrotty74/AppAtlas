import Foundation

struct CatalogEntryFilter: Sendable {
    func shouldInclude(_ file: LocalAppFile) -> Bool {
        guard file.fileType != "iso" else {
            return false
        }

        let name = file.fileName
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .lowercased()

        let technicalTerms = [
            "keygen",
            "license.zip",
            "uninstall ",
            "uninstaller",
            "privilegedhelpertools",
            "sanitizer",
            "pop-up fixer",
            "runtime_",
            "guest-tools"
        ]
        return !technicalTerms.contains { name.contains($0) }
    }

    func shouldInclude(_ app: AppEntry) -> Bool {
        if app.files.isEmpty {
            return app.sourceStatus == .manual
        }
        return app.files.contains(where: shouldInclude)
    }
}
