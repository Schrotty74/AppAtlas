import Foundation

struct LicenseImportApplyResult: Sendable {
    let saveResult: LicenseImportSaveResult
    let createdApps: [AppEntry]
}

struct LicenseImportService: Sendable {
    private let importer = LicenseDataImporter()
    private let keychain = LicenseKeychainStore.shared

    func prepare(from url: URL, apps: [AppEntry]) throws -> LicenseImportPlan {
        let licenses = try importer.decode(
            data: SecurityScopedFileAccess.readData(from: url),
            fileExtension: url.pathExtension
        )
        return importer.plan(licenses: licenses, apps: apps)
    }

    func apply(
        _ plan: LicenseImportPlan,
        createMissingEntries: Bool
    ) -> LicenseImportApplyResult {
        var savedCount = 0
        var failedCount = 0
        var createdApps: [AppEntry] = []

        for match in plan.matches {
            do {
                let existing = keychain.load(for: match.appID)
                    ?? AppLicenseRecord()
                try keychain.save(
                    existing.mergingMissingValues(from: match.record),
                    for: match.appID
                )
                savedCount += 1
            } catch {
                failedCount += 1
            }
        }

        if createMissingEntries {
            for unmatched in plan.unmatchedLicenses {
                let app = AppEntry(
                    name: unmatched.appName,
                    summary: "Manueller Eintrag aus einem Lizenzimport.",
                    details: "Dieser Eintrag wurde aus privaten Lizenzdaten angelegt. Beschreibung, Links und Kategorie können manuell ergänzt werden.",
                    category: "Lizenzen",
                    subcategory: "",
                    files: [],
                    reviewStatus: .needsReview,
                    sourceStatus: .manual
                )
                do {
                    try keychain.save(unmatched.record, for: app.id)
                    createdApps.append(app)
                    savedCount += 1
                } catch {
                    failedCount += 1
                }
            }
        }

        return LicenseImportApplyResult(
            saveResult: LicenseImportSaveResult(
                savedCount: savedCount,
                failedCount: failedCount,
                unmatchedCount: createMissingEntries
                    ? 0
                    : plan.unmatchedNames.count,
                ambiguousCount: plan.ambiguousNames.count
            ),
            createdApps: createdApps
        )
    }
}
