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

        let plan = try LicenseImportService().prepare(
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
        let service = CatalogTransferService()

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
        #expect(reconciliation.measurement.duration < 5)
        #expect(reconciliation.measurement.itemsPerSecond > 500)

        let search = CatalogPerformanceMonitor.measure(
            operation: "catalog-search",
            itemCount: count
        ) {
            existing.filter { $0.matchesSearch("Application 4321") }
        }
        #expect(search.result.contains { $0.id == existing[4_321].id })
        #expect(search.measurement.duration < 2)

        let directory = temporaryDirectory()
        let persistence = CatalogPersistence(
            fileURL: directory.appendingPathComponent("catalog.json")
        )
        let storage = try CatalogPerformanceMonitor.measure(
            operation: "catalog-save-load",
            itemCount: count
        ) {
            try persistence.save(existing)
            return try persistence.load()
        }
        #expect(storage.result == existing)
        #expect(storage.measurement.duration < 8)
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
