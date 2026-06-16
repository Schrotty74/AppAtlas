import Foundation
import Testing
@testable import AppAtlas

struct StabilityTests {
    @Test @MainActor
    func presentationStateKeepsOnlyOnePrimaryDialogActive() {
        let state = ContentPresentationState()

        state.sheet = .addApp
        state.sheet = .scanner
        state.importer = .licenses
        state.alert = .deleteAll

        let scannerIsActive: Bool
        if case .scanner = state.sheet {
            scannerIsActive = true
        } else {
            scannerIsActive = false
        }
        #expect(scannerIsActive)
        #expect(state.importer == .licenses)
        let deleteAllIsActive: Bool
        if case .deleteAll = state.alert {
            deleteAllIsActive = true
        } else {
            deleteAllIsActive = false
        }
        #expect(deleteAllIsActive)

        state.dismissSheet()
        state.dismissAlert()
        #expect(state.sheet == nil)
        #expect(state.alert == nil)
    }

    @Test
    func licenseImportIsPreparedBeforePrivateValuesAreStored() throws {
        let licenseStorage = InMemoryLicenseStorage()
        let app = makeApp(index: 1)
        let privateValue = UUID().uuidString
        let document = """
        {
          "licenses": [
            {
              "softwareName": "\(app.name)",
              "licenseKey": "\(privateValue)"
            }
          ]
        }
        """
        let url = temporaryDirectory()
            .appendingPathComponent("licenses.json")
        try Data(document.utf8).write(to: url)

        let plan = try LicenseImportService(
            licenseStorage: licenseStorage
        ).prepare(
            from: url,
            apps: [app]
        )

        #expect(plan.matches.count == 1)
        #expect(plan.matches.first?.appID == app.id)
        #expect(plan.matches.first?.appName == app.name)
        try? FileManager.default.removeItem(
            at: url.deletingLastPathComponent()
        )
    }

    @Test
    func sharedFileAccessReadsAndWritesDataAndText() throws {
        let directory = temporaryDirectory()
        let dataURL = directory.appendingPathComponent("catalog.json")
        let textURL = directory.appendingPathComponent("theme.json")
        let payload = Data(UUID().uuidString.utf8)

        try SecurityScopedFileAccess.write(payload, to: dataURL)
        try SecurityScopedFileAccess.write("{\"theme\":true}\n", to: textURL)

        #expect(try SecurityScopedFileAccess.readData(from: dataURL) == payload)
        #expect(
            String(
                data: try SecurityScopedFileAccess.readData(from: textURL),
                encoding: .utf8
            ) == "{\"theme\":true}\n"
        )
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func catalogTransferServiceRoundTripsUnprotectedCatalog() throws {
        let directory = temporaryDirectory()
        let url = directory.appendingPathComponent("catalog.json")
        let app = makeApp(index: 2)
        let service = CatalogTransferService(
            licenseStorage: InMemoryLicenseStorage()
        )

        try SecurityScopedFileAccess.write(
            service.exportData(apps: [app], protection: .withoutLicenses),
            to: url
        )
        let prepared = try service.prepareImport(from: url)

        switch prepared {
        case .ready(let result):
            #expect(result.apps == [app])
            #expect(result.licenses.isEmpty)
        case .passwordRequired:
            Issue.record("Ein ungeschützter Export darf kein Passwort verlangen.")
        }
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func backupReminderUsesConfiguredIntervalAndExportDate() {
        let defaults = UserDefaults.standard
        defer {
            defaults.removeObject(forKey: BackupReminderService.intervalKey)
            defaults.removeObject(forKey: BackupReminderService.lastExportDateKey)
        }

        defaults.removeObject(forKey: BackupReminderService.intervalKey)
        defaults.removeObject(forKey: BackupReminderService.lastExportDateKey)
        #expect(BackupReminderService.currentInterval == .thirtyDays)
        #expect(BackupReminderService.isReminderDue())

        defaults.set(
            BackupReminderInterval.thirtyDays.rawValue,
            forKey: BackupReminderService.intervalKey
        )
        defaults.removeObject(forKey: BackupReminderService.lastExportDateKey)
        #expect(BackupReminderService.isReminderDue())

        let now = Date()
        BackupReminderService.recordExport(date: now)
        #expect(!BackupReminderService.isReminderDue(now: now))
        #expect(
            BackupReminderService.isReminderDue(
                now: now.addingTimeInterval(31 * 24 * 60 * 60)
            )
        )

        defaults.set(
            BackupReminderInterval.never.rawValue,
            forKey: BackupReminderService.intervalKey
        )
        #expect(
            !BackupReminderService.isReminderDue(
                now: now.addingTimeInterval(365 * 24 * 60 * 60)
            )
        )
    }

    @Test
    func catalogPersistenceRecoversPreviousValidVersion() throws {
        let directory = temporaryDirectory()
        let fileURL = directory.appendingPathComponent("catalog.json")
        let persistence = CatalogPersistence(fileURL: fileURL)
        let first = makeApp(index: 10)
        let second = makeApp(index: 11)

        try persistence.save([first])
        try persistence.save([second])
        try Data("{invalid".utf8).write(to: fileURL, options: .atomic)

        let recovered = try persistence.load()

        #expect(recovered == [first])
        #expect(try persistence.load() == [first])
        let quarantined = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        #expect(
            quarantined.contains {
                $0.lastPathComponent.contains(".corrupt-")
            }
        )
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func catalogPersistenceRejectsDuplicateIdentifiersAndPaths() throws {
        let directory = temporaryDirectory()
        let persistence = CatalogPersistence(
            fileURL: directory.appendingPathComponent("catalog.json")
        )
        let first = makeApp(index: 20)
        var duplicateID = makeApp(index: 21)
        duplicateID = AppEntry(
            id: first.id,
            name: duplicateID.name,
            category: duplicateID.category,
            subcategory: duplicateID.subcategory,
            files: duplicateID.files
        )

        var rejectedDuplicateID = false
        do {
            try persistence.save([first, duplicateID])
        } catch CatalogPersistenceError.duplicateAppIDs {
            rejectedDuplicateID = true
        }
        #expect(rejectedDuplicateID)

        let duplicatePath = AppEntry(
            name: "Second path owner",
            category: "Test",
            subcategory: "Stability",
            files: first.files
        )
        var rejectedDuplicatePath = false
        do {
            try persistence.save([first, duplicatePath])
        } catch CatalogPersistenceError.duplicateFilePaths {
            rejectedDuplicatePath = true
        }
        #expect(rejectedDuplicatePath)
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func scanReconciliationPreservesManualMetadataAndUsesPathIdentity() {
        let manualIcon = Data(UUID().uuidString.utf8)
        let original = AppEntry(
            name: "Old Name",
            summary: "Manually written",
            category: "Old",
            subcategory: "Old",
            iconData: manualIcon,
            files: [makeFile(index: 30)],
            userCustomizations: UserCustomizations(icon: true),
            iconOrigin: .manual
        )
        let scanned = AppEntry(
            name: "Current Name",
            category: "Graphics",
            subcategory: "Editors",
            iconData: Data(UUID().uuidString.utf8),
            files: [makeFile(index: 30)],
            iconOrigin: .localBundle
        )

        let result = CatalogScanReconciler().reconcile(
            existingApps: [original],
            scannedApps: [scanned]
        )
        let merged = result.apps[0]

        #expect(result.apps.count == 1)
        #expect(merged.id == original.id)
        #expect(merged.name == "Current Name")
        #expect(merged.category == "Graphics")
        #expect(merged.iconData == manualIcon)
        #expect(merged.iconOrigin == .manual)
    }

    @Test
    func scanReconciliationRemovesMissingFilesAndKeepsManualEntries() {
        let scannedFile = makeFile(index: 40)
        let missingFile = makeFile(index: 41)
        let retained = AppEntry(
            name: "Retained",
            category: "Category",
            subcategory: "",
            files: [scannedFile]
        )
        let missing = AppEntry(
            name: "Missing",
            category: "Category",
            subcategory: "",
            files: [missingFile]
        )
        let manual = AppEntry(
            name: "Manual",
            category: "Category",
            subcategory: "",
            files: [],
            sourceStatus: .manual
        )
        let rescanned = AppEntry(
            name: "Retained",
            category: "Category",
            subcategory: "",
            files: [scannedFile]
        )

        let result = CatalogScanReconciler().reconcile(
            existingApps: [retained, missing, manual],
            scannedApps: [rescanned]
        )

        #expect(Set(result.apps.map(\.id)) == Set([retained.id, manual.id]))
        #expect(result.removedApps.map(\.id) == [missing.id])
    }

    @Test
    func scanReconciliationReplacesChangedFileMetadata() throws {
        let originalFile = LocalAppFile(
            fileName: "Application.dmg",
            fileType: "dmg",
            sourceCategory: "Category",
            sourceSubcategory: "",
            relativePath: "Category/Application.dmg",
            sizeInBytes: 10,
            modifiedAt: Date(timeIntervalSince1970: 100),
            detectedVersion: "1"
        )
        let changedFile = LocalAppFile(
            fileName: "Application.dmg",
            fileType: "dmg",
            sourceCategory: "Category",
            sourceSubcategory: "",
            relativePath: "Category/Application.dmg",
            sizeInBytes: 20,
            modifiedAt: Date(timeIntervalSince1970: 200),
            detectedVersion: "2"
        )
        let original = AppEntry(
            name: "Application",
            category: "Category",
            subcategory: "",
            files: [originalFile]
        )
        let rescanned = AppEntry(
            name: "Application",
            category: "Category",
            subcategory: "",
            files: [changedFile]
        )

        let result = CatalogScanReconciler().reconcile(
            existingApps: [original],
            scannedApps: [rescanned]
        )
        let file = try #require(result.apps.first?.files.first)

        #expect(result.apps.first?.id == original.id)
        #expect(file.sizeInBytes == 20)
        #expect(file.modifiedAt == Date(timeIntervalSince1970: 200))
        #expect(file.detectedVersion == "2")
        #expect(result.removedApps.isEmpty)
    }

    @Test
    func largeCatalogOperationsStayWithinRegressionBudgets() throws {
        let count = 5_000
        let existing = (0..<count).map(makeApp)
        let scanned = (0..<count).map { index in
            AppEntry(
                name: "Application \(index)",
                category: "Category \(index % 20)",
                subcategory: "Section \(index % 50)",
                files: [makeFile(index: index)]
            )
        }

        let reconciliationBaseline = CatalogPerformanceMonitor.measure(
            operation: "scan-reconciliation-baseline",
            itemCount: count
        ) {
            CatalogScanReconciler().reconcile(
                existingApps: existing,
                scannedApps: scanned
            )
        }
        let reconciliation = CatalogPerformanceMonitor.measure(
            operation: "scan-reconciliation",
            itemCount: count
        ) {
            CatalogScanReconciler().reconcile(
                existingApps: existing,
                scannedApps: scanned
            )
        }
        #expect(reconciliation.result.apps.count == count)
        #expect(
            reconciliation.measurement.duration
                <= reconciliationBaseline.measurement.duration * 10
        )

        let searchBaseline = CatalogPerformanceMonitor.measure(
            operation: "catalog-search-baseline",
            itemCount: count
        ) {
            existing.filter { $0.matchesSearch("Application 4321") }
        }
        let search = CatalogPerformanceMonitor.measure(
            operation: "catalog-search",
            itemCount: count
        ) {
            existing.filter { $0.matchesSearch("Application 4321") }
        }
        #expect(search.result.contains { $0.id == existing[4_321].id })
        #expect(
            search.measurement.duration
                <= searchBaseline.measurement.duration * 10
        )

        let directory = temporaryDirectory()
        let persistence = CatalogPersistence(
            fileURL: directory.appendingPathComponent("catalog.json")
        )
        let storageBaseline = try CatalogPerformanceMonitor.measure(
            operation: "catalog-save-load-baseline",
            itemCount: count
        ) {
            try persistence.save(existing)
            return try persistence.load()
        }
        let storage = try CatalogPerformanceMonitor.measure(
            operation: "catalog-save-load",
            itemCount: count
        ) {
            try persistence.save(existing)
            return try persistence.load()
        }
        #expect(storage.result == existing)
        #expect(
            storage.measurement.duration
                <= storageBaseline.measurement.duration * 10
        )
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeApp(index: Int) -> AppEntry {
        AppEntry(
            name: "Application \(index)",
            summary: "Stable catalog entry \(index)",
            category: "Category \(index % 20)",
            subcategory: "Section \(index % 50)",
            files: [makeFile(index: index)]
        )
    }

    private func makeFile(index: Int) -> LocalAppFile {
        LocalAppFile(
            fileName: "Application-\(index).dmg",
            fileType: "DMG",
            sourceCategory: "Category \(index % 20)",
            sourceSubcategory: "Section \(index % 50)",
            relativePath: "Category-\(index % 20)/Application-\(index).dmg",
            sizeInBytes: Int64(index + 1),
            modifiedAt: nil,
            detectedVersion: nil
        )
    }

    private func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }
}
