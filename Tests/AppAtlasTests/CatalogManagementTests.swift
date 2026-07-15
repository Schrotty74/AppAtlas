import AppKit
import Foundation
import ImageIO
import Testing
@testable import AppAtlas

struct CatalogManagementTests {
    @Test
    func helpLinksOpenThePublicManualAndSupportedAIServices() throws {
        #expect(
            AppHelpLinks.manualURL.absoluteString.hasPrefix(
                "https://github.com/Schrotty74/AppAtlas/blob/main/docs/output/pdf/"
            )
        )
        #expect(
            [
                "AppAtlas-Handbuch-DE.pdf",
                "AppAtlas-User-Manual-EN.pdf",
            ].contains { AppHelpLinks.manualURL.absoluteString.hasSuffix($0) }
        )
        #expect(
            AIHelpService.allCases.map(\.url.host) == [
                "chatgpt.com",
                "gemini.google.com",
                "claude.ai"
            ]
        )
        #expect(AIHelpService.allCases.allSatisfy { $0.url.scheme == "https" })
        #expect(
            AppHelpLinks.aiPrompt.hasPrefix(
                "Ich habe AppAtlas gerade zum ersten Mal geöffnet"
            )
        )
        #expect(AppHelpLinks.aiPrompt.contains("„Ordner scannen“"))
        #expect(AppHelpLinks.aiPrompt.contains("„Katalog mit … Apps abgleichen“"))
        #expect(AppHelpLinks.aiPrompt.contains("ohne Lizenzdaten"))
        #expect(
            AppHelpLinks.aiPrompt.contains(
                AppHelpLinks.manualURL.absoluteString
            )
        )
        #expect(!AppHelpLinks.aiPrompt.contains("BEGINN DES APPATLAS-HANDBUCHS"))

        for service in AIHelpService.allCases {
            let resource = service.logoResource
            let url = try #require(
                AppResources.bundle.url(
                    forResource: resource.name,
                    withExtension: resource.extension
                )
            )
            #expect(NSImage(contentsOf: url) != nil)
        }
    }

    @Test
    func updateCheckerComparesGitHubTagsWithBundleVersions() {
        #expect(AppUpdateChecker.isNewerVersion("v1.2.1", than: "1.2.0"))
        #expect(AppUpdateChecker.isNewerVersion("v1.2.1-beta.1", than: "1.2.0"))
        #expect(AppUpdateChecker.isNewerVersion("1.2.0", than: "1.1.9"))
        #expect(AppUpdateChecker.isNewerVersion("v1.2.0-beta.2", than: "1.2.0-beta.1"))
        #expect(AppUpdateChecker.isNewerVersion("v1.2.0-beta.10", than: "1.2.0-beta.2"))
        #expect(AppUpdateChecker.isNewerVersion("v1.2.0", than: "1.2.0-beta.3"))
        #expect(!AppUpdateChecker.isNewerVersion("v1.2.0", than: "1.2.0"))
        #expect(!AppUpdateChecker.isNewerVersion("v1.2.0-beta.3", than: "1.2.0"))
        #expect(!AppUpdateChecker.isNewerVersion("v1.1.1", than: "1.2.0"))
    }

    @Test
    func cinebenchLogoURLDownloadsValidPNG() async throws {
        let url = try #require(URL(
            string: "https://cinebench.net/wp-content/uploads/2025/09/Cinebench_logo.png"
        ))
        let (data, response) = try await URLSession.shared.data(from: url)
        let http = try #require(response as? HTTPURLResponse)

        #expect(http.statusCode == 200)
        #expect(data.starts(with: [0x89, 0x50, 0x4E, 0x47]))

        let source = try #require(
            CGImageSourceCreateWithData(data as CFData, nil)
        )
        #expect(CGImageSourceGetCount(source) > 0)
        #expect(CGImageSourceGetType(source) as String? == "public.png")
    }

    @Test
    func localDataDirectoriesAreSeparatedByBuildBundleIdentifier() {
        #expect(
            AppLocalDataDirectory.directoryName(
                bundleIdentifier: "at.schrotty.appatlas.dev"
            ) == "AppAtlas-Dev"
        )
        #expect(
            AppLocalDataDirectory.directoryName(
                bundleIdentifier: "at.schrotty.appatlas.beta"
            ) == "AppAtlas-Beta"
        )
        #expect(
            AppLocalDataDirectory.directoryName(
                bundleIdentifier: "at.schrotty.appatlas"
            ) == "AppAtlas"
        )
    }

    @Test
    func importsLicenseManagerJSONAndMatchesOnlyConfidentApps() throws {
        let json = """
        {
          "licenses": [
            {
              "softwareName": "Example Pro",
              "licenseKey": "value-one",
              "licenseKey2": "value-two",
              "licenseType": "Lifetime",
              "userEmail": "user@example.com",
              "notes": "Private note"
            },
            {
              "softwareName": "Unknown Tool",
              "licenseKey": "unknown-value",
              "licenseType": "Lifetime"
            }
          ]
        }
        """
        let importer = LicenseDataImporter()
        let licenses = try importer.decode(
            data: Data(json.utf8),
            fileExtension: "json"
        )
        let app = AppEntry(
            name: "Example",
            category: "Test",
            subcategory: "",
            files: []
        )

        let plan = importer.plan(licenses: licenses, apps: [app])

        #expect(plan.matches.count == 1)
        #expect(plan.matches.first?.appID == app.id)
        #expect(plan.matches.first?.record.serialNumber == "value-one\nvalue-two")
        #expect(plan.unmatchedNames == ["Unknown Tool"])
    }

    @Test
    func licenseImportMatchesPackagingSuffixesAndMergesDuplicates() throws {
        let firstValue = UUID().uuidString
        let secondValue = UUID().uuidString
        let json = """
        {
          "licenses": [
            {
              "softwareName": "Example Tool",
              "licenseKey": "\(firstValue)"
            },
            {
              "softwareName": "Example Tool",
              "licenseKey": "\(secondValue)"
            },
            {
              "softwareName": "Mouse Utility for Mac",
              "licenseKey": "value"
            }
          ]
        }
        """
        let apps = [
            AppEntry(
                name: "Example Tool v2 2 1",
                category: "Test",
                subcategory: "",
                files: []
            ),
            AppEntry(
                name: "MouseUtilityApp",
                category: "Test",
                subcategory: "",
                files: []
            )
        ]
        let importer = LicenseDataImporter()
        let licenses = try importer.decode(
            data: Data(json.utf8),
            fileExtension: "json"
        )

        let plan = importer.plan(licenses: licenses, apps: apps)

        #expect(plan.matches.count == 2)
        #expect(plan.unmatchedNames.isEmpty)
        #expect(plan.ambiguousNames.isEmpty)
        let merged = try #require(
            plan.matches.first { $0.appName == "Example Tool v2 2 1" }
        )
        #expect(merged.record.serialNumber.contains(firstValue))
        #expect(merged.record.serialNumber.contains(secondValue))
    }

    @Test
    func licenseImportKeepsTrulyMissingAppsAvailableForManualCreation() {
        let missing = ImportedLicense(
            softwareName: "Store Only Utility",
            record: AppLicenseRecord(serialNumber: UUID().uuidString)
        )

        let plan = LicenseDataImporter().plan(licenses: [missing], apps: [])

        #expect(plan.matches.isEmpty)
        #expect(plan.unmatchedNames == ["Store Only Utility"])
        #expect(plan.unmatchedLicenses.first?.record.isEmpty == false)
    }

    @Test
    func licenseImportCanCreatePrivateManualCatalogEntries() throws {
        let licenseStorage = InMemoryLicenseStorage()
        let privateValue = UUID().uuidString
        let missing = ImportedLicense(
            softwareName: "Store Only Utility",
            record: AppLicenseRecord(serialNumber: privateValue)
        )
        let plan = LicenseDataImporter().plan(licenses: [missing], apps: [])

        let outcome = LicenseImportService(
            licenseStorage: licenseStorage
        ).apply(
            plan,
            createMissingEntries: true
        )

        let app = try #require(outcome.createdApps.first)
        #expect(app.name == "Store Only Utility")
        #expect(app.category == "Lizenzen")
        #expect(app.files.isEmpty)
        #expect(outcome.saveResult.savedCount == 1)
        #expect(
            licenseStorage.load(for: app.id)?.serialNumber
                == privateValue
        )
    }

    @Test
    func importsLicenseManagerCSVLicenseSection() throws {
        let csv = """
        # CATEGORIES
        # Name,Color,SortOrder
        Utilities,#000000,0

        # LICENSES
        softwareName,licenseKey,licenseKey2,licenseType,userEmail,notes
        "Example, App",value-one,value-two,Lifetime,user@example.com,"Private, note"
        """
        let licenses = try LicenseDataImporter().decode(
            data: Data(csv.utf8),
            fileExtension: "csv"
        )

        #expect(licenses.count == 1)
        #expect(licenses.first?.softwareName == "Example, App")
        #expect(licenses.first?.record.serialNumber == "value-one\nvalue-two")
        #expect(licenses.first?.record.notes == "Private, note")
    }

    @Test
    func licenseImportKeepsExistingValues() {
        let existingValue = UUID().uuidString
        let importedValue = UUID().uuidString
        let existing = AppLicenseRecord(
            serialNumber: existingValue,
            registeredEmail: "",
            licenseType: "Existing",
            notes: ""
        )
        let imported = AppLicenseRecord(
            serialNumber: importedValue,
            registeredEmail: "user@example.com",
            licenseType: "Imported",
            notes: "Imported note"
        )

        let merged = existing.mergingMissingValues(from: imported)

        #expect(merged.serialNumber == existingValue)
        #expect(merged.registeredEmail == "user@example.com")
        #expect(merged.licenseType == "Existing")
        #expect(merged.notes == "Imported note")
    }

    @Test
    func automaticLanguageUsesGermanOnlyForDACHRegions() {
        for region in ["DE", "AT", "CH", "LI"] {
            #expect(
                AppLanguageChoice.automatic.resolvedLanguage(
                    regionCode: region
                ) == "de"
            )
        }
        for region in ["US", "GB", "FR", "IT", nil] {
            #expect(
                AppLanguageChoice.automatic.resolvedLanguage(
                    regionCode: region
                ) == "en"
            )
        }
        #expect(
            AppLanguageChoice.german.resolvedLanguage(regionCode: "US") == "de"
        )
        #expect(
            AppLanguageChoice.english.resolvedLanguage(regionCode: "DE") == "en"
        )
    }

    @Test @MainActor
    func loadedDescriptionsTranslateOnlyAfterExplicitRefresh() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let persistence = CatalogPersistence(fileURL: fileURL)
        try persistence.save([
            AppEntry(
                name: "Example",
                summary: "A useful utility",
                details: "This application manages files and improves daily workflows on the Mac.",
                category: "System",
                subcategory: "Tools",
                files: [],
                sourceStatus: .manual,
                userCustomizations: UserCustomizations()
            )
        ])
        let store = makeCatalogStore(
            persistence: persistence,
            targetLanguageProvider: { "de" }
        )

        await store.loadBundledCatalog()

        #expect(store.pendingTranslation == nil)

        store.refreshDescriptionTranslations()

        let refreshedApp = try #require(store.apps.first)
        #expect(refreshedApp.suggestions.isEmpty)
        #expect(store.pendingTranslation == nil)
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func englishModeKeepsEnglishAndTranslatesOtherLanguagesToEnglish() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let persistence = CatalogPersistence(fileURL: fileURL)
        try persistence.save([
            AppEntry(
                name: "English",
                details: "This application manages files and improves workflows.",
                category: "System",
                subcategory: "Tools",
                files: [],
                sourceStatus: .manual
            ),
            AppEntry(
                name: "German",
                details: "Diese Anwendung verwaltet Dateien und verbessert Arbeitsabläufe.",
                category: "System",
                subcategory: "Werkzeuge",
                files: [],
                sourceStatus: .manual
            )
        ])
        let store = makeCatalogStore(
            persistence: persistence,
            targetLanguageProvider: { "en" }
        )

        await store.loadBundledCatalog()

        #expect(store.pendingTranslation == nil)

        store.refreshDescriptionTranslations()

        let refreshedEnglish = try #require(
            store.apps.first { $0.name == "English" }
        )
        let refreshedGerman = try #require(
            store.apps.first { $0.name == "German" }
        )
        #expect(!refreshedEnglish.suggestions.contains { $0.kind == .description })
        #expect(!refreshedGerman.suggestions.contains { $0.kind == .description })
        #expect(store.pendingTranslation == nil)
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test
    func clampsOnlineUpdateConcurrencyToSupportedRange() {
        #expect(OnlineUpdateSettings.sanitized(-1) == 1)
        #expect(OnlineUpdateSettings.sanitized(3) == 3)
        #expect(OnlineUpdateSettings.sanitized(8) == 5)
    }

    @Test
    func extendedOnlineSearchDefaultsToDisabled() {
        let previous = UserDefaults.standard.object(
            forKey: OnlineUpdateSettings.extendedSearchKey
        )
        defer {
            if let previous {
                UserDefaults.standard.set(
                    previous,
                    forKey: OnlineUpdateSettings.extendedSearchKey
                )
            } else {
                UserDefaults.standard.removeObject(
                    forKey: OnlineUpdateSettings.extendedSearchKey
                )
            }
        }
        UserDefaults.standard.removeObject(
            forKey: OnlineUpdateSettings.extendedSearchKey
        )

        #expect(!OnlineUpdateSettings.extendedSearchEnabled)
    }

    @Test
    func processUsageMeasurementProducesPlausibleValues() {
        let result = ProcessUsageMeasurement().result(
            concurrency: 3,
            appCount: 12
        )

        #expect(result.concurrency == 3)
        #expect(result.appCount == 12)
        #expect(result.duration >= 0)
        #expect(result.averageCPUPercent >= 0)
    }

    @Test
    func persistsManualApps() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let persistence = CatalogPersistence(fileURL: fileURL)
        let app = AppEntry(
            name: "Test App",
            summary: "Manuell",
            category: "Test",
            subcategory: "Werkzeuge",
            files: [],
            sourceStatus: .manual
        )

        try persistence.save([app])
        let loadedApps = try persistence.load()
        let loaded = try #require(loadedApps)

        #expect(loaded == [app])
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    @Test
    func catalogEncodingNeverContainsLicenseSecrets() throws {
        let app = AppEntry(
            name: "Private Test App",
            category: "Test",
            subcategory: "",
            files: []
        )
        let encoded = try JSONEncoder().encode(app)
        let text = try #require(String(data: encoded, encoding: .utf8))

        #expect(!text.localizedCaseInsensitiveContains("serial"))
        #expect(!text.localizedCaseInsensitiveContains("license"))
    }

    @Test
    func storesPrivateLicenseRecord() throws {
        let licenseStorage = InMemoryLicenseStorage()
        let appID = UUID()
        let record = AppLicenseRecord(
            serialNumber: ["TEST", "NOT", "REAL"].joined(separator: "-"),
            registeredEmail: "test@example.invalid",
            licenseType: "Test",
            notes: "Wird nach dem Test gelöscht."
        )
        try licenseStorage.save(record, for: appID)

        #expect(licenseStorage.load(for: appID) == record)
    }

    @Test
    func catalogDocumentRoundTripsWithoutLicenseData() throws {
        let app = AppEntry(
            name: "Example App",
            category: "Example",
            subcategory: "",
            files: []
        )
        let data = try CatalogDocument(apps: [app]).encoded()
        let decoded = try CatalogDocument.decode(data)
        let text = try #require(String(data: data, encoding: .utf8))

        #expect(decoded.apps == [app])
        #expect(!text.localizedCaseInsensitiveContains("serial"))
        #expect(!text.localizedCaseInsensitiveContains("registeredEmail"))
    }

    @Test
    func encryptedCatalogTransferProtectsAndRestoresLicenseData() throws {
        let licenseStorage = InMemoryLicenseStorage()
        let app = AppEntry(
            name: "Transfer Test",
            category: "Test",
            subcategory: "",
            files: []
        )
        let secret = ["PRIVATE", "TEST", "VALUE"].joined(separator: "-")
        let license = AppLicenseRecord(serialNumber: secret)
        try licenseStorage.save(license, for: app.id)

        let data = try CatalogTransferDocument.encoded(
            apps: [app],
            protection: .licensesEncrypted(
                password: "a-long-test-password"
            ),
            licenseStore: licenseStorage
        )
        let text = try #require(String(data: data, encoding: .utf8))
        let decoded = try CatalogTransferDocument.decode(
            data,
            password: "a-long-test-password"
        )

        #expect(CatalogTransferDocument.requiresPassword(data))
        #expect(!text.contains(secret))
        #expect(decoded.apps == [app])
        #expect(decoded.licenses[app.id] == license)
    }

    @Test
    func rejectsWrongCatalogTransferPassword() throws {
        let licenseStorage = InMemoryLicenseStorage()
        let data = try CatalogTransferDocument.encoded(
            apps: [],
            protection: .licensesEncrypted(
                password: "correct-test-password"
            ),
            licenseStore: licenseStorage
        )

        #expect(throws: CatalogTransferError.self) {
            try CatalogTransferDocument.decode(
                data,
                password: "incorrect-test-password"
            )
        }
    }

    @Test
    func plaintextCatalogTransferIncludesChosenLicenseData() throws {
        let licenseStorage = InMemoryLicenseStorage()
        let app = AppEntry(
            name: "Plain Transfer Test",
            category: "Test",
            subcategory: "",
            files: []
        )
        let secret = ["VISIBLE", "TEST", "VALUE"].joined(separator: "-")
        let license = AppLicenseRecord(serialNumber: secret)
        try licenseStorage.save(license, for: app.id)

        let data = try CatalogTransferDocument.encoded(
            apps: [app],
            protection: .licensesPlaintext,
            licenseStore: licenseStorage
        )
        let decoded = try CatalogTransferDocument.decode(data)
        let text = try #require(String(data: data, encoding: .utf8))

        #expect(text.contains(secret))
        #expect(decoded.licenses[app.id] == license)
    }

    @Test
    func catalogTransferReadsOnlyKnownLicenseRecords() throws {
        let licenseStorage = CountingLicenseStorage()
        let licensedApp = AppEntry(
            name: "Licensed Transfer Test",
            category: "Test",
            subcategory: "",
            files: []
        )
        let unlicensedApp = AppEntry(
            name: "Unlicensed Transfer Test",
            category: "Test",
            subcategory: "",
            files: []
        )
        let license = AppLicenseRecord(licenseType: "Test")
        try licenseStorage.save(license, for: licensedApp.id)

        let data = try CatalogTransferDocument.encoded(
            apps: [licensedApp, unlicensedApp],
            protection: .licensesPlaintext,
            licenseStore: licenseStorage
        )
        let decoded = try CatalogTransferDocument.decode(data)

        #expect(decoded.licenses == [licensedApp.id: license])
        #expect(licenseStorage.exportReads == [licensedApp.id])
    }

    @Test
    func quarantinesOversizedCatalogInsteadOfLoadingIt() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let fileURL = directory.appendingPathComponent("catalog.json")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        let handle = try FileHandle(forWritingTo: fileURL)
        try handle.truncate(atOffset: 100_000_001)
        try handle.close()

        let loaded = try CatalogPersistence(fileURL: fileURL).load()
        let remainingFiles = try FileManager.default.contentsOfDirectory(
            atPath: directory.path
        )

        #expect(loaded == nil)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        #expect(remainingFiles.contains { $0.contains("oversized-") })
        try? FileManager.default.removeItem(at: directory)
    }

    @Test @MainActor
    func deletesOnlyCatalogEntry() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(persistence: CatalogPersistence(fileURL: fileURL))
        let app = AppEntry(
            name: "Löschtest",
            category: "Test",
            subcategory: "",
            files: []
        )

        store.add(app)
        store.delete(app)

        #expect(store.apps.isEmpty)
        #expect(try CatalogPersistence(fileURL: fileURL).load()?.isEmpty == true)
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    @Test @MainActor
    func deletesEntireCatalogAndPrivateLicenses() throws {
        let licenseStorage = InMemoryLicenseStorage()
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL),
            licenseStorage: licenseStorage
        )
        let first = AppEntry(
            name: "First Test App",
            category: "Test",
            subcategory: "",
            files: []
        )
        let second = AppEntry(
            name: "Second Test App",
            category: "Test",
            subcategory: "",
            files: []
        )
        let firstTestValue = "TEST-FIRST"
        let secondTestValue = "TEST-SECOND"
        defer {
            try? FileManager.default.removeItem(
                at: fileURL.deletingLastPathComponent()
            )
        }
        try licenseStorage.save(
            AppLicenseRecord(serialNumber: firstTestValue),
            for: first.id
        )
        try licenseStorage.save(
            AppLicenseRecord(serialNumber: secondTestValue),
            for: second.id
        )
        store.add(first)
        store.add(second)

        store.deleteAll()

        #expect(store.apps.isEmpty)
        #expect(store.selectedAppID == nil)
        #expect(try CatalogPersistence(fileURL: fileURL).load()?.isEmpty == true)
        #expect(licenseStorage.load(for: first.id) == nil)
        #expect(licenseStorage.load(for: second.id) == nil)
    }

    @Test @MainActor
    func scanDoesNotOverwriteManualIcon() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(persistence: CatalogPersistence(fileURL: fileURL))
        let manual = AppEntry(
            name: "Icon Protection Test",
            category: "Grafik",
            subcategory: "",
            iconFileName: "manual-icon.png",
            files: [],
            userCustomizations: UserCustomizations(icon: true),
            iconOrigin: .manual
        )
        let scanned = AppEntry(
            name: "Icon Protection Test",
            category: "Grafik",
            subcategory: "",
            iconData: Data([1, 2, 3]),
            files: [
                LocalAppFile(
                    fileName: "Icon Protection Test.app",
                    fileType: "app",
                    sourceCategory: "Grafik",
                    sourceSubcategory: "",
                    relativePath: "Grafik/Icon Protection Test.app",
                    sizeInBytes: 0,
                    modifiedAt: nil,
                    detectedVersion: nil,
                    iconData: Data([1, 2, 3])
                )
            ],
            iconOrigin: .localBundle
        )
        defer {
            try? FileManager.default.removeItem(
                at: fileURL.deletingLastPathComponent()
            )
        }
        store.add(manual)

        store.mergeScannedApps([scanned])

        let result = try #require(store.apps.first)
        #expect(result.iconFileName == "manual-icon.png")
        #expect(result.iconOrigin == .manual)
        #expect(result.customizations.icon)
    }

    @Test @MainActor
    func scanDropsEntriesInsideExcludedFolders() throws {
        let previousExcludedDirectories = UserDefaults.standard.object(
            forKey: ScannerSettings.excludedDirectoriesKey
        )
        defer {
            if let previousExcludedDirectories {
                UserDefaults.standard.set(
                    previousExcludedDirectories,
                    forKey: ScannerSettings.excludedDirectoriesKey
                )
            } else {
                UserDefaults.standard.removeObject(
                    forKey: ScannerSettings.excludedDirectoriesKey
                )
            }
        }
        UserDefaults.standard.set(
            "GDrive",
            forKey: ScannerSettings.excludedDirectoriesKey
        )

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let excludedFile = LocalAppFile(
            fileName: "action launcher plugin 4 release.apk",
            fileType: "apk",
            sourceCategory: "GDrive",
            sourceSubcategory: "Handy/Apps",
            relativePath: "GDrive/Handy/Apps/action launcher plugin 4 release.apk",
            sizeInBytes: 0,
            modifiedAt: nil,
            detectedVersion: nil
        )
        let includedFile = LocalAppFile(
            fileName: "Visible Tool.dmg",
            fileType: "dmg",
            sourceCategory: "Tools",
            sourceSubcategory: "",
            relativePath: "Tools/Visible Tool.dmg",
            sizeInBytes: 0,
            modifiedAt: nil,
            detectedVersion: nil
        )
        store.add(
            AppEntry(
                name: "action launcher plugin 4 release",
                category: "GDrive",
                subcategory: "Handy/Apps",
                files: [excludedFile]
            )
        )

        store.mergeScannedApps([
            AppEntry(
                name: "action launcher plugin 4 release",
                category: "GDrive",
                subcategory: "Handy/Apps",
                files: [excludedFile]
            ),
            AppEntry(
                name: "Visible Tool",
                category: "Tools",
                subcategory: "",
                files: [includedFile]
            )
        ])

        #expect(store.apps.map(\.name) == ["Visible Tool"])
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func scanDropsEntriesInsideSelectedExcludedFolderCategories() throws {
        struct BookmarkRecord: Codable {
            let bookmarkData: Data
            let displayPath: String
        }

        let previousExcludedBookmarks = UserDefaults.standard.object(
            forKey: ScannerSettings.excludedFolderBookmarksKey
        )
        defer {
            if let previousExcludedBookmarks {
                UserDefaults.standard.set(
                    previousExcludedBookmarks,
                    forKey: ScannerSettings.excludedFolderBookmarksKey
                )
            } else {
                UserDefaults.standard.removeObject(
                    forKey: ScannerSettings.excludedFolderBookmarksKey
                )
            }
        }

        let records = [
            BookmarkRecord(
                bookmarkData: Data(),
                displayPath: "/ExternalDemo/Backup/Firefox"
            ),
            BookmarkRecord(
                bookmarkData: Data(),
                displayPath: "/ExternalDemo/GDrive"
            )
        ]
        UserDefaults.standard.set(
            try JSONEncoder().encode(records),
            forKey: ScannerSettings.excludedFolderBookmarksKey
        )

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let excludedFile = LocalAppFile(
            fileName: "Firefox Profile Backup.zip",
            fileType: "zip",
            sourceCategory: "",
            sourceSubcategory: "",
            relativePath: "Profiles/Firefox Profile Backup.zip",
            sizeInBytes: 0,
            modifiedAt: nil,
            detectedVersion: nil
        )
        let includedFile = LocalAppFile(
            fileName: "Visible Tool.dmg",
            fileType: "dmg",
            sourceCategory: "Tools",
            sourceSubcategory: "",
            relativePath: "Tools/Visible Tool.dmg",
            sizeInBytes: 0,
            modifiedAt: nil,
            detectedVersion: nil
        )

        store.add(
            AppEntry(
                name: "Firefox Profile Backup",
                category: "Firefox",
                subcategory: "Profiles",
                files: [excludedFile]
            )
        )
        #expect(store.appsNeedingWebsiteReview.isEmpty)

        store.mergeScannedApps([
            AppEntry(
                name: "Visible Tool",
                category: "Tools",
                subcategory: "",
                files: [includedFile]
            )
        ])

        #expect(store.apps.map(\.name) == ["Visible Tool"])
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func fastScanAddsConservativeKnownLocalLinks() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )

        store.mergeScannedApps([
            AppEntry(
                name: "Affinity",
                category: "Grafik",
                subcategory: "",
                files: [
                    LocalAppFile(
                        fileName: "Affinity.dmg",
                        fileType: "dmg",
                        sourceCategory: "Grafik",
                        sourceSubcategory: "",
                        relativePath: "Grafik/Affinity.dmg",
                        sizeInBytes: 0,
                        modifiedAt: nil,
                        detectedVersion: nil
                    )
                ]
            )
        ])

        let result = try #require(store.apps.first)
        #expect(result.homepage == URL(string: "https://affinity.serif.com/"))
        #expect(result.downloadURL == URL(string: "https://affinity.serif.com/"))
        #expect(result.metadataSources?.contains("Lokaler Hersteller-Hinweis") == true)
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func fastScanAddsKnownLinksForCommonApps() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )

        store.mergeScannedApps([
            knownScannedApp(
                name: "Adobe Photoshop",
                fileName: "Adobe Photoshop v27.1.0 AIO.pkg",
                category: "Grafik",
                subcategory: "Adobe"
            ),
            knownScannedApp(
                name: "Pearcleaner",
                fileName: "Pearcleaner.dmg",
                category: "System",
                subcategory: ""
            ),
            knownScannedApp(
                name: "VLC",
                fileName: "VLC.app",
                category: "Multimedia",
                subcategory: "Video"
            ),
            knownScannedApp(
                name: "Downie 4",
                fileName: "Downie_4.9.11.dmg",
                category: "Internet",
                subcategory: "Downloads"
            ),
            knownScannedApp(
                name: "AnyDesk macOS",
                fileName: "AnyDesk_macOS.dmg",
                category: "Netzwerk",
                subcategory: "Fernwartung"
            )
        ])

        let apps = Dictionary(uniqueKeysWithValues: store.apps.map {
            ($0.name, $0)
        })
        #expect(
            apps["Adobe Photoshop"]?.homepage
                == URL(string: "https://www.adobe.com/products/photoshop.html")
        )
        #expect(
            apps["Pearcleaner"]?.githubURL
                == URL(string: "https://github.com/alienator88/Pearcleaner")
        )
        #expect(
            apps["VLC"]?.downloadURL
                == URL(string: "https://www.videolan.org/vlc/download-macosx.html")
        )
        #expect(
            apps["Downie 4"]?.homepage
                == URL(string: "https://software.charliemonroe.net/downie/")
        )
        #expect(
            apps["AnyDesk macOS"]?.downloadURL
                == URL(string: "https://anydesk.com/downloads/mac-os")
        )
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func fastScanUsesCachedHomebrewCaskMetadata() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let catalogURL = directory.appendingPathComponent("catalog.json")
        let caskURL = directory.appendingPathComponent("homebrew-cask.json")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try Data(
            """
            [
              {
                "token": "kaset",
                "full_token": "kaset",
                "name": ["Kaset"],
                "desc": "Audio cassette player for macOS.",
                "homepage": "https://example.com/kaset",
                "url": "https://example.com/kaset.dmg"
              }
            ]
            """.utf8
        ).write(to: caskURL)
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: catalogURL),
            homebrewCaskMetadataCache: HomebrewCaskMetadataCache(
                fileURL: caskURL
            )
        )

        store.mergeScannedApps([
            knownScannedApp(
                name: "kaset",
                fileName: "kaset-v0.9.0.dmg",
                category: "Multimedia",
                subcategory: "Audio"
            )
        ])

        let app = try #require(store.apps.first)
        #expect(app.homepage == URL(string: "https://example.com/kaset"))
        #expect(app.downloadURL == URL(string: "https://example.com/kaset.dmg"))
        let suggestion = try #require(app.suggestions.first)
        #expect(suggestion.value == "Audio cassette player for macOS.")
        #expect(!suggestion.needsTranslation)
        #expect(store.pendingTranslation == nil)
        #expect(app.metadataSources?.contains("Homebrew-Cask-Katalog") == true)
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func homebrewCaskLookupHandlesVersionedLocalFileNames() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let caskURL = directory.appendingPathComponent("homebrew-cask.json")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try Data(
            """
            [
              {
                "token": "iina",
                "full_token": "iina",
                "name": ["IINA"],
                "desc": "Modern media player.",
                "homepage": "https://iina.io/",
                "url": "https://dl.iina.io/IINA.v1.4.3.dmg"
              },
              {
                "token": "mos",
                "full_token": "mos",
                "name": ["Mos"],
                "desc": "Mouse scrolling utility.",
                "homepage": "https://mos.caldis.me/",
                "url": "https://github.com/Caldis/Mos/releases/latest"
              },
              {
                "token": "latest",
                "full_token": "latest",
                "name": ["Latest"],
                "desc": "App update tracker.",
                "homepage": "https://max.codes/latest",
                "url": "https://max.codes/latest/0.11.zip"
              }
            ]
            """.utf8
        ).write(to: caskURL)
        let cache = HomebrewCaskMetadataCache(fileURL: caskURL)

        let iina = AppEntry(
            name: "IINA.v",
            category: "Multimedia",
            subcategory: "",
            files: [
                localFile(
                    named: "IINA.v1.4.2-build164.dmg",
                    category: "Multimedia"
                )
            ]
        )
        let mos = AppEntry(
            name: "Mos.Versions",
            category: "Hardware",
            subcategory: "Mouse",
            files: [
                localFile(
                    named: "Mos.Versions.4.2.0-20260505.1.zip",
                    category: "Hardware",
                    subcategory: "Mouse"
                )
            ]
        )
        let latest = AppEntry(
            name: "",
            category: "System",
            subcategory: "Updates",
            files: [
                localFile(
                    named: "Latest.zip",
                    category: "System",
                    subcategory: "Updates"
                )
            ]
        )

        #expect(cache.metadata(for: iina)?.homepage == URL(string: "https://iina.io/"))
        #expect(cache.metadata(for: mos)?.homepage == URL(string: "https://mos.caldis.me/"))
        #expect(cache.metadata(for: latest)?.homepage == URL(string: "https://max.codes/latest"))
        try? FileManager.default.removeItem(at: directory)
    }

    @Test @MainActor
    func cachedHomebrewLookupStaysFastForLargeCatalogs() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let caskURL = directory.appendingPathComponent("homebrew-cask.json")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let casks = (0..<5_000).map {
            """
              {
                "token": "tool-\($0)",
                "full_token": "tool-\($0)",
                "name": ["Tool \($0)"],
                "desc": "Utility app \($0)",
                "homepage": "https://example.com/tool-\($0)",
                "url": "https://example.com/tool-\($0).dmg"
              }
            """
        }.joined(separator: ",\n")
        try Data("[\(casks)]".utf8).write(to: caskURL)
        let cache = HomebrewCaskMetadataCache(fileURL: caskURL)
        let apps = (0..<400).map {
            AppEntry(
                name: "Tool \($0)",
                category: "Tools",
                subcategory: "",
                files: [
                    localFile(
                        named: "tool-\($0).dmg",
                        category: "Tools"
                    )
                ]
            )
        }
        let startedAt = ContinuousClock.now
        let matches = apps.compactMap { cache.metadata(for: $0) }
        let duration = startedAt.duration(to: .now)

        #expect(matches.count == apps.count)
        #expect(duration < .seconds(3))
        try? FileManager.default.removeItem(at: directory)
    }

    @Test @MainActor
    func fastScanReusesConfirmedLocalLinks() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let confirmedStore = ConfirmedMetadataMatchStore(defaults: defaults)
        confirmedStore.confirm(
            appName: "Example Tool",
            url: try #require(URL(string: "https://example.com/tool"))
        )
        let urls = confirmedStore.confirmedURLs(for: "Example Tool")

        #expect(urls == [URL(string: "https://example.com/tool")])
        #expect(confirmedStore.confirmedURLs(
            matchingHomepage: try #require(URL(string: "https://example.com/"))
        ) == [URL(string: "https://example.com/tool")])
        confirmedStore.confirm(
            appName: "Rejected Tool",
            url: try #require(URL(string: "https://example.com/rejected-icon.png"))
        )
        confirmedStore.reject(
            appName: "Rejected Tool",
            url: try #require(URL(string: "https://example.com/rejected-icon.png"))
        )
        #expect(!confirmedStore.confirmedURLs(
            matchingHomepage: try #require(URL(string: "https://example.com"))
        ).contains(try #require(URL(string: "https://example.com/rejected-icon.png"))))
    }

    @Test
    func scannerNameCleanupRemovesLeadingNumbersAndInstallerSuffixes() {
        #expect(
            AppNameNormalizer.displayName(for: "02 RapidRAW.dmg")
                == "RapidRAW"
        )
        #expect(
            AppNameNormalizer.displayName(for: "kaset-v0.9.0.dmg")
                == "kaset"
        )
        #expect(
            AppNameNormalizer.displayName(
                for: "Adobe Photoshop v27.1.0 AIO.pkg"
            ) == "Adobe Photoshop"
        )
        #expect(AppNameNormalizer.displayName(for: "IINA.v") == "IINA")
        #expect(
            AppNameNormalizer.displayName(for: "Mos.Versions") == "Mos"
        )
        #expect(
            AppNameNormalizer.displayName(for: "Lap_0.2.0_aarch64.dmg")
                == "Lap"
        )
        #expect(
            AppNameNormalizer.displayName(
                for: "peazip-10.9.0.DARWIN.aarch64.dmg"
            ) == "peazip"
        )
        #expect(
            AppNameNormalizer.displayName(for: "Example_arm64.zip")
                == "Example"
        )
        #expect(
            AppNameNormalizer.displayName(for: "Example_x86_64.zip")
                == "Example"
        )
    }

    @Test
    func catalogEntryFilterDropsTechnicalInstallerHelpers() {
        let filter = CatalogEntryFilter()
        #expect(!filter.shouldInclude(localFile(named: "Activation.pkg")))
        #expect(!filter.shouldInclude(localFile(named: "Adobe Runtime UB.pkg")))
        #expect(!filter.shouldInclude(localFile(named: "CCXP.pkg")))
        #expect(!filter.shouldInclude(localFile(named: "Adobe Creative Cloud Cleaner Tool.app")))
        #expect(filter.shouldInclude(localFile(named: "Adobe Photoshop.pkg")))
    }

    @Test @MainActor
    func keepsManualMetadataEdits() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(persistence: CatalogPersistence(fileURL: fileURL))
        var app = AppMetadataEnricher().enrich(
            AppEntry(
                name: "Example Browser",
                category: "Browser",
                subcategory: "",
                files: []
            )
        )
        store.add(app)

        app.details = "Meine eigene Beschreibung"
        app.homepage = URL(string: "https://example.com")
        store.update(app)

        #expect(store.apps.first?.details == "Meine eigene Beschreibung")
        #expect(store.apps.first?.homepage?.host() == "example.com")
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func addsMissingDescriptionEvenWhenIconAlreadyExists() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let icon = try #require(Data(base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
        ))
        let description = "Eine konkrete Beschreibung \(UUID().uuidString)."
        let app = AppEntry(
            name: "Metadata Test",
            details: "Metadata Test ist eine Anwendung aus dem Bereich Test. Beschreibung und offizielle Links können lokal ergänzt oder online verifiziert werden.",
            category: "Test",
            subcategory: "",
            iconData: icon,
            files: []
        )
        store.add(app)

        store.applyOnlineMetadata(
            AppleArtworkLookup.Metadata(
                description: description,
                homepage: nil,
                downloadURL: nil,
                artworkURL: nil
            ),
            iconData: nil,
            to: app.id
        )

        #expect(store.apps.first?.hasIcon == true)
        #expect(store.pendingTranslation == nil)
        let suggestion = try #require(store.apps.first?.suggestions.first)
        store.acceptSuggestion(suggestion.id, for: app.id)
        #expect(store.apps.first?.details == description)
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func automaticForeignDescriptionStartsTranslationDownload() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL),
            targetLanguageProvider: { "de" }
        )
        let app = AppEntry(
            name: "Metadata Test",
            details: "Metadata Test ist eine Anwendung aus dem Bereich Test. Beschreibung und offizielle Links können lokal ergänzt oder online verifiziert werden.",
            category: "Test",
            subcategory: "",
            files: []
        )
        store.add(app)

        store.applyOnlineMetadata(
            AppleArtworkLookup.Metadata(
                description: "A focused app for managing audio recordings.",
                homepage: nil,
                downloadURL: nil,
                artworkURL: nil
            ),
            iconData: nil,
            to: app.id
        )

        let suggestion = try #require(store.apps.first?.suggestions.first)
        #expect(suggestion.kind == .description)
        #expect(suggestion.needsTranslation == false)
        #expect(store.pendingTranslation == nil)
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func acceptedDescriptionSuggestionDoesNotReappearAfterRefresh() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL),
            targetLanguageProvider: { "de" }
        )
        let description = "Akzeptierte Beschreibung \(UUID().uuidString)."
        let app = AppEntry(
            name: "Accepted Description Test \(UUID().uuidString)",
            details: "Beschreibung und offizielle Links können lokal ergänzt oder online verifiziert werden.",
            category: "Test",
            subcategory: "",
            files: []
        )
        store.add(app)

        store.applyOnlineMetadata(
            AppleArtworkLookup.Metadata(
                description: description,
                homepage: nil,
                downloadURL: nil,
                artworkURL: nil
            ),
            iconData: nil,
            to: app.id
        )
        let suggestion = try #require(store.apps.first?.suggestions.first)
        store.acceptSuggestion(suggestion.id, for: app.id)

        #expect(store.apps.first?.suggestions.isEmpty == true)

        store.applyOnlineMetadata(
            AppleArtworkLookup.Metadata(
                description: description,
                homepage: nil,
                downloadURL: nil,
                artworkURL: nil
            ),
            iconData: nil,
            to: app.id
        )

        #expect(store.apps.first?.suggestions.isEmpty == true)
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func rejectedDescriptionSuggestionDoesNotReappearAfterRefresh() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL),
            targetLanguageProvider: { "de" }
        )
        let description = "Abgelehnte Beschreibung \(UUID().uuidString)."
        let app = AppEntry(
            name: "Rejected Description Test \(UUID().uuidString)",
            details: "Beschreibung und offizielle Links können lokal ergänzt oder online verifiziert werden.",
            category: "Test",
            subcategory: "",
            files: []
        )
        store.add(app)

        store.applyOnlineMetadata(
            AppleArtworkLookup.Metadata(
                description: description,
                homepage: nil,
                downloadURL: nil,
                artworkURL: nil
            ),
            iconData: nil,
            to: app.id
        )
        let suggestion = try #require(store.apps.first?.suggestions.first)
        store.dismissSuggestion(suggestion.id, for: app.id)

        #expect(store.apps.first?.suggestions.isEmpty == true)

        store.applyOnlineMetadata(
            AppleArtworkLookup.Metadata(
                description: description,
                homepage: nil,
                downloadURL: nil,
                artworkURL: nil
            ),
            iconData: nil,
            to: app.id
        )

        #expect(store.apps.first?.suggestions.isEmpty == true)
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test
    func iconStorePreparesCacheDirectoriesWithoutSavingAnIcon() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let iconStore = IconStore(rootURL: directory)

        try iconStore.prepareDirectories()

        #expect(
            FileManager.default.fileExists(
                atPath: directory.appendingPathComponent("Icons").path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: directory.appendingPathComponent("IconThumbnails").path
            )
        )
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func iconStoreKeepsOriginalAndThumbnailOutsideCatalogJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let iconStore = IconStore(rootURL: directory)
        let appID = UUID()
        let icon = try #require(Data(base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
        ))

        let fileName = try iconStore.save(icon, for: appID)
        let original = iconStore.data(fileName: fileName, thumbnail: false)
        let thumbnail = iconStore.data(fileName: fileName, thumbnail: true)

        #expect(original != nil)
        #expect(thumbnail != nil)
        #expect(
            FileManager.default.fileExists(
                atPath: directory
                    .appendingPathComponent("Icons")
                    .appendingPathComponent(fileName)
                    .path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: directory
                    .appendingPathComponent("IconThumbnails")
                    .appendingPathComponent(fileName)
                    .path
            )
        )
        try? FileManager.default.removeItem(at: directory)
    }

    @Test @MainActor
    func localCatalogSeparatesIconsWhileExportKeepsThem() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let icon = try #require(Data(base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
        ))
        let app = AppEntry(
            name: "Separated Icon Test",
            category: "Test",
            subcategory: "",
            iconData: icon,
            files: []
        )

        store.add(app)
        let localText = try String(contentsOf: fileURL, encoding: .utf8)
        let exported = try CatalogDocument(
            apps: store.exportApps()
        ).encoded()
        let decoded = try CatalogDocument.decode(exported)

        #expect(!localText.contains("\"iconData\""))
        #expect(localText.contains("\"iconFileName\""))
        #expect(decoded.apps.first?.iconData != nil)

        store.delete(try #require(store.apps.first))
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func recognizesCurrentGeneratedDescriptionAsPlaceholder() {
        let text = "Example ist eine Anwendung aus dem Bereich Test. Beschreibung und offizielle Links können lokal ergänzt oder online verifiziert werden."

        #expect(AppMetadataEnricher.isPlaceholderDescription(text))
        #expect(
            !AppMetadataEnricher.isPlaceholderDescription(
                "Eine manuell gepflegte Beschreibung."
            )
        )
    }

    @Test
    func expandsShortDescriptionWithUsefulFunctionHints() {
        let expanded = AppMetadataEnricher.expandedDescription(
            sourceText: "A focused image editor.",
            category: "Grafik",
            subcategory: "Bildbearbeitung",
            keywords: ["RAW"]
        )

        #expect(expanded.contains("Typische Funktionen:"))
        #expect(expanded.contains("Bilder anzeigen"))
    }

    @Test
    func rejectsTinyImageAsAppIcon() throws {
        #expect(
            !IconQualityInspector.isLikelyAppIcon(
                try #require(Data(base64Encoded:
                    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
                ))
            )
        )
    }

    @Test
    func transparentWhitePixelsDoNotMakeIconTooBright() throws {
        let size = NSSize(width: 128, height: 128)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.withAlphaComponent(0.04).setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        NSColor.black.setFill()
        NSBezierPath(
            ovalIn: NSRect(x: 56, y: 56, width: 16, height: 16)
        ).fill()
        image.unlockFocus()

        let tiff = try #require(image.tiffRepresentation)
        let png = try #require(IconImageConverter.compactPNG(from: tiff))

        #expect(IconQualityInspector.isLikelyAppIcon(png))
    }

    @Test
    func onlineIconChecksRequireQualityAndIconLikeURLs() throws {
        let iconData = try #require(Data(base64Encoded: """
        iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAAAXNSR0IArs4c6QAAADhlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAAAgKADAAQAAAABAAAAgAAAAABrRiZNAAAJJ0lEQVR4Ae1dXYhUZRh+zpimS5tuWGFdZKBlRUaSWGjQRhpGoHtRIbXQDybUjWwqeTd3xmaLXXRRIQUaUl6oEEkabZASkhkVlaWQXVhUkmvGuinu6X32zOyccX9mZ8aZ837f975w9pw5Z8457/M+z7zn+zvfRrgc1hNPQw5L5VLtiDAPMebIuk3WrbKecjluEew1YpyXGJ6VWJ6W9XFZH5VY9GIQ+9EVnas3LlHNF9gUt2EqVohTXJbJdVpqvpadWEsE+kUM+2TZgwFZNkana7lI9QLIxy2YgS652QYhvrWWm9o5lzkCsWQIoBt96EE+6q/m6hMXwGPxJCzBc6K4vBA/q5qb2HebFIEYvws3eRzAVuyMLk7krhMTQE98ozzjd8vF75nIRe07GUcgxmEpI6yUMsLJSp5UFsCWeJFcZJf96iuFUtlxZgOgA2ujQ+N5lhvvILbETwnxnxn540ZJ50E+pskdORzHxs4ACfnbxjnXDrkSgRidkgm2j+bu6AJg2qd6IBU9Mx8iMCCF9wdGexyMFEBS4PvS0r4PvKcwsEwwiIWXFgzLywCs6iWlfavmpWLnxSbLBOSWHKesXACs51tVLxUezzbJLTlOWekRkLTwHbfUn4qOj5t8FPRJX02hxbCUAdi8ay18PlJejokcJ035Q/uTDMCOnWn4VQRgbfvl4fLzE/sOzuEmdiAlGSDp1TPy/aR7JCr+0Mm5WCIAdumahRWBAucROJhjEk4JeuvPD0sC/biImTnJARzJY+SHRT7RtpB7PgLaw8NuiAsRaM9JyX+ehSPQCAj3OekkmBMofIMt3DMDtFkkAo2AcM8MYPX/QPkn98wAU0LFHzxu4b7UFxB8NMIMgAkgTN6HUZsAhkMR5oYJIEzeh1GbAIZDEeaGCSBM3odRmwCGQxHmxhW+w54pbzbcfwNw17XA3BnJcr30fV41OVmI/98LyfKHvFd7rC9ZvvkL+Pw34NSA3xGK8Hoc+wZxgZC96hZg+Wzg9muAqDT0tSqojMwPfwN7TwA7fgaOiCh8M28EwF/06juANXcCtzaod+MnmYLhze+At79PMoYPYnBeANOlIXvdAuDF+UBbk15kOy2PhTe+BTYfAc6cd1sGzgqAWf3p24BXFgPXZTSe6U8pM7x8EHj3R0i/ipvmpABuvhp472HgPiUvsH0hb+I/+THwyz/uicC5auDjc4GvV+khn5RTiPSJvrlmzgiAKX/zEuD95cD0K/WFmT7RN/pYY6UjE1BOCGCyeLltGfCSFPa0G32kr/TZBVPvJgO5+1F5xjo0dJW+0mcXRKBaAEyl7zwEPDLbhd9SuY/0mb5rfxyoFsCr8jx16ZdfLoHEd2LQbGoFwBK1C8/8SuQSg+bagUoBsJ7/1oOVQuvOcWIhJo2mTgB8ZrKRR2NVr1YCiYWYNJYH1AmAzbtaWvhqJXy084iJ2LSZKgGwY4dt+74asRGjJlMlgPVSYMqqY6cZpBAbey41mRoBsD//hfmaQtMYX9htTaxaTI0AOJijWf35WQafGIlVi6kRAEfyhGKasKoQAMfwNWoYl0ZRESsxazAVAuAAztBMC2YVAuAMnJyEMRQjVi2zjqoQAInnDJyhmCasagTA6Vc5A6fvRozEqsXUCIDt4px+1XcjRg19AMU4qxEAHeLcu5x+1VcjNmLUZKoEwImXOfeur0Zs2iaXViUAEs+Jlzn3rm9GTMSmzdQJgLNuc+LlM/9pC1Xt/hALMWmcUVydABhmzrr9/Ke1B1zbmcSidSZxlQIggR8cA15TVmCqRVibv0qw1HJuM85RKwCCX39Aplc72owwNOYe9H2D8kKtagHwmfnMJ8BHJxpDUCOvSp/pu8bnfhq3agHQ0QuDwMoP3coE/OXTZ/qu3dQLgAFkIDv3uVEmYLmFvrpAPmPrhADoKFPpOikTPLFXZxWRVT36Rh+1p33Gs2jOCKDoMGsHd+/Q1VjERh76RN9cM+cEwACzTr14J/Ds/mz7Dti2Tx/oi9Z6fiVBOvlv49Kg7B9HpqNR/bbzAihC5pu29q9ji9GY+NobAaQh2z+PTkdj/G0vBZCGbP8+Ph2NkdveC2AkZNuTjoCTtYA0ANuuLwImgPri5/zZJgDnKawPgAmgvvg5f7YJwHkK6wNgAqgvfs6fbQJwnsL6AOSk71JG45sFGQHhPif/z/RskOANNP+X7VlmgIBezDbWyyIg3DMDHC/baR/CiYBwzwzg8MDrcLhqCFLhnrWA3oZc3C7qQgR6cxiEDGqCxy9lu8BDJj72k/scuqJz8hiQgcxmQUWAnAv3SUNQjD1BgTewHLs+xHkigAH5EFt7QDC6INfkXCwRwMaIbQHdwQTAgHYj4Tz1ZlAfeiQLyCsOZl5HgByT64IlGYAf8lG/NArlC/tt5WsEyDG5LlhJANxxAFslCxwuHrS1ZxEgt+Q4ZeUC2BldlLrhSnsUpCLkyyZTP7klxykrFwAPdEUn5W+HLAP8aOZFBMhlR4HbMkAjBcDDa6NDkgVWl33TPrgbAXJJTkex0QXAL66NtosIOmXLMsEogXNk18AQh+RyDIvG2F/avSVeJB92SQ1hVmmnbamPQFKl7xjrl1/0f+wMUPwGU8cgFoqSrHZQjIn2NbkiZ2Ok/bT7lQXAb7NgeBD3ytYaEYI1FqUjqGk74WbNEFdJYb6id5UfAZdeIh+3YAa6ZPcGeSy0XnrYPmcQgaQfp3uohS/VyDMRT6oXQPGqm+I2TMUKEQGXZbK7pXjI1k2JQL9k432y7Bnq2Cm07Vd759oFkL5TTzxNehWWyq52EcM8cWqOrNtk3SrrKemv2naVEeCwfY7c5uBdjt9MhvD1yjN+P/vzq7zaiK//D5MkSke3fcG7AAAAAElFTkSuQmCC
        """))

        #expect(IconQualityInspector.isLikelyOnlineAppIcon(iconData))
        #expect(
            WebMetadataLookup.isLikelyIconURL(
                try #require(
                    URL(string: "https://example.com/assets/app-icon.png")
                )
            )
        )
        #expect(
            !WebMetadataLookup.isLikelyIconURL(
                try #require(
                    URL(string: "https://example.com/images/screenshot.png")
                )
            )
        )
        #expect(
            !WebMetadataLookup.isLikelyIconURL(
                try #require(
                    URL(string: "https://example.com/images/banner-logo.png")
                )
            )
        )
        let nextAbsoluteURL = try #require(URL(
            string: "https://example.com/_next/image?url=https%3A%2F%2Fcdn.example.com%2Fassets%2Fapp-icon.svg&w=256&q=75"
        ))
        let nextRelativeURL = try #require(URL(
            string: "https://example.com/_next/image?url=%2Fassets%2Fproduct-icon.png&w=512&q=80"
        ))
        let regularURL = try #require(URL(
            string: "https://example.com/_assets/app-icon.png?w=512"
        ))

        #expect(
            OnlineIconLoader.imageSourceURL(from: nextAbsoluteURL)
                .absoluteString == "https://cdn.example.com/assets/app-icon.svg"
        )
        #expect(
            OnlineIconLoader.imageSourceURL(from: nextRelativeURL)
                .absoluteString == "https://example.com/assets/product-icon.png"
        )
        #expect(
            OnlineIconLoader.imageSourceURL(from: regularURL)
                .absoluteString == regularURL.absoluteString
        )
        #expect(
            OnlineIconLoader.cacheKey(
                for: try #require(URL(
                    string: "https://example.com/assets/app-icon.png#preview"
                ))
            ) == "https://example.com/assets/app-icon.png"
        )
        #expect(
            WebMetadataLookup.isLikelyIconURL(
                OnlineIconLoader.imageSourceURL(from: nextAbsoluteURL)
            )
        )
    }

    @Test @MainActor
    func automaticOnlineIconsAreNotReusedAcrossDifferentApps() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        store.add([
            AppEntry(
                name: "Adobe Photoshop",
                category: "Grafik",
                subcategory: "Adobe",
                files: []
            ),
            AppEntry(
                name: "Adobe Lightroom Classic",
                category: "Grafik",
                subcategory: "Adobe",
                files: []
            )
        ])
        let iconData = try #require(testIconData())
        let photoshopID = try #require(
            store.apps.first { $0.name == "Adobe Photoshop" }?.id
        )
        let lightroomID = try #require(
            store.apps.first { $0.name == "Adobe Lightroom Classic" }?.id
        )

        #expect(store.applyIconData(iconData, to: photoshopID))
        #expect(!store.applyIconData(iconData, to: lightroomID))
        #expect(
            store.apps.first { $0.id == photoshopID }?.iconOrigin == .website
        )
        #expect(
            store.apps.first { $0.id == lightroomID }?.hasIcon == false
        )
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func automaticOnlineIconCanBeSharedBySameHomepageFamily() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let homepage = try #require(URL(string: "https://cinebench.net/"))
        let iconData = try #require(testIconData())
        let cinebench2024 = AppEntry(
            name: "Cinebench 2024",
            category: "Benchmark",
            subcategory: "",
            homepage: homepage,
            files: []
        )
        let cinebenchR23 = AppEntry(
            name: "CinebenchR23",
            category: "Benchmark",
            subcategory: "",
            homepage: homepage,
            files: []
        )
        store.add([cinebench2024, cinebenchR23])

        #expect(store.applyIconData(iconData, to: cinebenchR23.id))
        #expect(store.applyIconData(iconData, to: cinebench2024.id))
        #expect(
            store.apps.first { $0.id == cinebench2024.id }?.iconOrigin
                == .website
        )
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func automaticOnlineIconReplacesLowQualityPlaceholderOnly() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let placeholderIcon = try #require(Data(base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
        ))
        let goodIcon = try #require(testIconData())
        let placeholderApp = AppEntry(
            name: "Cinebench 2024",
            category: "Benchmark",
            subcategory: "",
            iconData: placeholderIcon,
            files: []
        )
        let goodIconApp = AppEntry(
            name: "Cinebench R23",
            category: "Benchmark",
            subcategory: "",
            iconData: goodIcon,
            files: []
        )
        store.add([placeholderApp, goodIconApp])

        #expect(
            store.applyIconData(
                goodIcon,
                to: placeholderApp.id
            )
        )
        #expect(
            !store.applyIconData(
                goodIcon,
                to: goodIconApp.id
            )
        )
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func automaticOnlineIconReplacesMissingStoredIconReference() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let app = AppEntry(
            name: "Cinebench 2024",
            category: "Benchmark",
            subcategory: "",
            iconFileName: "missing-icon.png",
            files: [],
            userCustomizations: UserCustomizations(icon: true),
            iconOrigin: .manual
        )
        let iconData = try #require(testIconData())
        store.add([app])

        #expect(store.applyIconData(iconData, to: app.id))
        #expect(
            store.apps.first { $0.id == app.id }?.iconOrigin == .website
        )
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test
    func repositoryPagesAreMetadataSourcesButNotGenericIconSources() throws {
        let github = try #require(URL(string: "https://github.com/example/app"))
        let gitlab = try #require(URL(string: "https://gitlab.com/example/app"))
        let aggregator = try #require(
            URL(string: "https://alternativeto.net/software/example/")
        )

        #expect(OfficialWebsiteLookup.isOfficialCandidate(github))
        #expect(OfficialWebsiteLookup.isOfficialCandidate(gitlab))
        #expect(!OfficialWebsiteLookup.allowsGenericWebsiteIcon(github))
        #expect(!OfficialWebsiteLookup.allowsGenericWebsiteIcon(gitlab))
        #expect(!OfficialWebsiteLookup.isOfficialCandidate(aggregator))
    }

    @Test
    func detectsEquivalentLinksWithoutQueryOrTrailingSlash() throws {
        let first = try #require(
            URL(string: "https://example.com/download/?source=test")
        )
        let second = try #require(
            URL(string: "https://example.com/download")
        )
        let other = try #require(
            URL(string: "https://example.com/project")
        )

        #expect(URLRedirectResolver.equivalent(first, second))
        #expect(!URLRedirectResolver.equivalent(first, other))
    }

    @Test
    func nameMatcherHandlesVersionedAndSuffixedNames() {
        #expect(AppNameMatcher.similarity("Example", "Example 8") == 1)
        #expect(AppNameMatcher.similarity("Example Pro", "Example") == 1)
        #expect(AppNameMatcher.similarity("Tool: Mac Edition", "Tool") == 1)
        #expect(AppNameMatcher.searchName("Example darwin") == "Example")
        #expect(AppNameMatcher.similarity("Example darwin", "example") == 1)
        #expect(AppNameMatcher.similarity("Example", "Example Track") < 0.8)
        #expect(AppNameMatcher.searchName("Example Apple Silicon") == "Example")
        #expect(AppNameMatcher.similarity("Unrelated", "Example") < 0.8)
    }

    @Test
    func githubPageFallbackPrefersMatchingExternalHomepage() {
        let html = """
        <a href="https://unrelated.example/project">Other</a>
        <a href="https://project.example/docs/intro">Project docs</a>
        """

        #expect(
            GitHubRepositoryLookup.externalHomepage(
                in: html,
                repositoryName: "project"
            ) == URL(string: "https://project.example")
        )
    }

    @Test
    func categoryContextRejectsTechnicalLibraryForGraphics() {
        #expect(
            !AppContextMatcher.isPlausible(
                category: "Grafik",
                subcategory: "",
                candidateText: "Java concurrency library for CPU scheduling"
            )
        )
        #expect(
            AppContextMatcher.isPlausible(
                category: "Grafik",
                subcategory: "",
                candidateText: "Professional graphics and creative design suite"
            )
        )
        #expect(
            AppContextMatcher.searchHint(
                category: "Grafik",
                subcategory: ""
            ) == "graphics design"
        )
    }

    @Test
    func metadataScorerRequiresConfidenceAndClearWinner() throws {
        let app = AppEntry(
            name: "Canvas",
            category: "Grafik",
            subcategory: "Bildbearbeitung",
            files: []
        )
        let strong = MetadataMatchCandidate(
            name: "Canvas",
            contextText: "Professional graphics image editor and design app",
            developer: nil,
            url: URL(string: "https://canvas.example"),
            bundleIdentifier: nil,
            sourceReliability: 0.95
        )
        let weak = MetadataMatchCandidate(
            name: "Canvas Thread",
            contextText: "Java concurrency developer library",
            developer: nil,
            url: URL(string: "https://code.example"),
            bundleIdentifier: nil,
            sourceReliability: 0.6
        )
        let clearResult = try #require(
            MetadataMatchScorer.result(
                app: app,
                ranked: MetadataMatchScorer.ranked(
                    app: app,
                    candidates: [strong, weak],
                    candidate: { $0 }
                )
            )
        )
        let ambiguousResult = try #require(
            MetadataMatchScorer.result(
                app: app,
                ranked: MetadataMatchScorer.ranked(
                    app: app,
                    candidates: [strong, strong],
                    candidate: { $0 }
                )
            )
        )

        #expect(clearResult.match.decision == .automatic)
        #expect(
            clearResult.match.margin
                >= MetadataMatchScorer.minimumAutomaticMargin
        )
        #expect(ambiguousResult.match.decision == .review)
        #expect(ambiguousResult.match.margin == 0)
    }

    @Test
    func metadataScorerRejectsDifferentProductEditions() {
        #expect(
            AppNameNormalizer.displayName(
                for: "Adobe Photoshop v27.1.0 AIO.pkg"
            ) == "Adobe Photoshop"
        )

        let app = AppEntry(
            name: "Adobe Photoshop",
            category: "Grafik",
            subcategory: "Adobe",
            files: [
                LocalAppFile(
                    fileName: "Adobe Photoshop v27.1.0 AIO.pkg",
                    fileType: "pkg",
                    sourceCategory: "Grafik",
                    sourceSubcategory: "Adobe",
                    relativePath: "Grafik/Adobe/Adobe Photoshop v27.1.0 AIO.pkg",
                    sizeInBytes: 0,
                    modifiedAt: nil,
                    detectedVersion: "27.1.0"
                )
            ]
        )
        let elements = MetadataMatchCandidate(
            name: "Adobe Photoshop Elements 2026",
            contextText: "Adobe photo editor",
            developer: "Adobe",
            url: URL(string: "https://www.adobe.com/products/photoshop-elements.html"),
            bundleIdentifier: nil,
            sourceReliability: 0.95
        )
        let photoshop = MetadataMatchCandidate(
            name: "Adobe Photoshop",
            contextText: "Adobe photo editor",
            developer: "Adobe",
            url: URL(string: "https://www.adobe.com/products/photoshop.html"),
            bundleIdentifier: nil,
            sourceReliability: 0.95
        )

        #expect(MetadataMatchScorer.score(app: app, candidate: elements) == 0)
        #expect(
            MetadataMatchScorer.hasConflictingProductQualifier(
                appName: "Adobe Photoshop",
                candidateURL: URL(
                    string: "https://www.adobe.com/products/photoshop-elements/whats-new.html"
                )
            )
        )
        #expect(
            !MetadataMatchScorer.hasConflictingProductQualifier(
                appName: "Adobe Photoshop",
                candidateURL: URL(
                    string: "https://www.adobe.com/products/photoshop.html"
                )
            )
        )
        #expect(
            MetadataMatchScorer.score(app: app, candidate: photoshop)
                > MetadataMatchScorer.automaticThreshold
        )
    }

    @Test
    func metadataScorerUsesBundleIdentifierAndCategoryContext() {
        let file = LocalAppFile(
            fileName: "Affinity.app",
            fileType: "app",
            sourceCategory: "Grafik",
            sourceSubcategory: "Bildbearbeitung",
            relativePath: "Grafik/Affinity.app",
            sizeInBytes: 0,
            modifiedAt: nil,
            detectedVersion: nil,
            bundleIdentifier: "com.example.affinity"
        )
        let app = AppEntry(
            name: "Affinity",
            category: "Grafik",
            subcategory: "Bildbearbeitung",
            files: [file]
        )
        let correct = MetadataMatchScorer.score(
            app: app,
            candidate: MetadataMatchCandidate(
                name: "Affinity",
                contextText: "Graphics photo image editor",
                developer: nil,
                url: nil,
                bundleIdentifier: "com.example.affinity",
                sourceReliability: 0.95
            )
        )
        let technical = MetadataMatchScorer.score(
            app: app,
            candidate: MetadataMatchCandidate(
                name: "Thread Affinity",
                contextText: "Java CPU concurrency developer library",
                developer: nil,
                url: nil,
                bundleIdentifier: "org.example.thread-affinity",
                sourceReliability: 0.7
            )
        )

        #expect(correct >= MetadataMatchScorer.automaticThreshold)
        #expect(technical < MetadataMatchScorer.reviewThreshold)
    }

    @Test
    func metadataScorerUsesBundleIdentifierToBreakCloseTies() throws {
        let app = AppEntry(
            name: "AppCleaner",
            category: "System",
            subcategory: "Cleaner",
            files: [
                LocalAppFile(
                    fileName: "AppCleaner.app",
                    fileType: "app",
                    sourceCategory: "System",
                    sourceSubcategory: "Cleaner",
                    relativePath: "System/Cleaner/AppCleaner.app",
                    sizeInBytes: 0,
                    modifiedAt: nil,
                    detectedVersion: nil,
                    bundleIdentifier: "net.freemacsoft.AppCleaner"
                )
            ]
        )
        let wrong = MetadataMatchCandidate(
            name: "AppCleaner",
            contextText: "Cleaner utility",
            developer: nil,
            url: nil,
            bundleIdentifier: "com.example.AppCleaner",
            sourceReliability: 0.95
        )
        let correct = MetadataMatchCandidate(
            name: "AppCleaner",
            contextText: "Cleaner utility",
            developer: nil,
            url: nil,
            bundleIdentifier: "net.freemacsoft.AppCleaner",
            sourceReliability: 0.95
        )

        let selection = try #require(
            MetadataMatchScorer.result(
                app: app,
                ranked: MetadataMatchScorer.ranked(
                    app: app,
                    candidates: [wrong, correct],
                    candidate: { $0 }
                )
            )
        )

        #expect(selection.candidate.bundleIdentifier == correct.bundleIdentifier)
        #expect(selection.match.decision == .automatic)
        #expect(
            selection.match.margin
                >= MetadataMatchScorer.minimumAutomaticMargin
        )
    }

    @Test
    func metadataScorerUsesConfiguredReviewThresholds() {
        #expect(MetadataMatchScorer.automaticThreshold == 0.80)
        #expect(MetadataMatchScorer.reviewThreshold == 0.65)
        #expect(MetadataMatchScorer.minimumAutomaticMargin == 0.08)
    }

    @Test @MainActor
    func websiteReviewListOnlyShowsUnresolvedLookupMisses() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        store.add([
            AppEntry(
                name: "Only Missing Homepage",
                category: "Test",
                subcategory: "",
                files: []
            ),
            AppEntry(
                name: "Failed Lookup",
                category: "Test",
                subcategory: "",
                files: [],
                onlineLookupStatus: .failed
            ),
            AppEntry(
                name: "Suppressed Failed Lookup",
                category: "Test",
                subcategory: "",
                files: [],
                websitePromptSuppressed: true,
                onlineLookupStatus: .failed
            ),
            AppEntry(
                name: "Found Homepage",
                category: "Test",
                subcategory: "",
                homepage: URL(string: "https://example.com"),
                files: [],
                onlineLookupStatus: .failed
            )
        ])

        #expect(store.appsNeedingWebsiteReview.map(\.name) == ["Failed Lookup"])
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test
    func confirmedMetadataMatchesRemainLocalAndReusable() throws {
        let suiteName = "AppAtlasTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let store = ConfirmedMetadataMatchStore(defaults: defaults)
        let url = try #require(
            URL(string: "https://developer.example/app")
        )

        store.confirm(appName: "Example", url: url)
        store.confirm(appName: "Example", appleTrackID: 42)
        store.confirm(
            appName: "Example",
            suggestionKind: CatalogSuggestionKind.description.rawValue,
            value: "Eine bestätigte Beschreibung."
        )

        #expect(store.domainScore(
            for: "Example",
            candidateURL: url
        ) == 1)
        #expect(store.isConfirmed(appName: "Example", appleTrackID: 42))
        #expect(store.isConfirmed(appName: "Other Example", url: url))
        #expect(store.isConfirmed(
            appName: "Example",
            suggestionKind: CatalogSuggestionKind.description.rawValue,
            value: "Eine bestätigte Beschreibung."
        ))
        #expect(store.domainScore(
            for: "Other Example",
            candidateURL: url
        ) == 1)

        store.reject(appName: "Rejected Example", url: url)
        store.reject(appName: "Rejected Example", appleTrackID: 99)
        store.reject(
            appName: "Rejected Example",
            suggestionKind: CatalogSuggestionKind.description.rawValue,
            value: "Eine abgelehnte Beschreibung."
        )
        let reloadedStore = ConfirmedMetadataMatchStore(defaults: defaults)

        #expect(reloadedStore.isRejected(
            appName: "Rejected Example",
            url: url
        ))
        #expect(reloadedStore.isRejected(
            appName: "Other Example",
            url: url
        ))
        #expect(reloadedStore.isRejected(
            appName: "Rejected Example",
            appleTrackID: 99
        ))
        #expect(reloadedStore.isRejected(
            appName: "Rejected Example",
            suggestionKind: CatalogSuggestionKind.description.rawValue,
            value: "Eine abgelehnte Beschreibung."
        ))
        #expect(reloadedStore.domainScore(
            for: "Rejected Example",
            candidateURL: url
        ) == 0)
    }

    @Test
    func detectsDescriptionLanguageAndMarksOriginalFallback() {
        let german = "Diese Anwendung verwaltet Dateien und erleichtert die tägliche Arbeit auf dem Mac."
        let english = "This application manages files and improves daily workflows on the Mac."

        #expect(
            DescriptionLanguageProcessor.isGerman(
                DescriptionLanguageProcessor.detectedLanguage(for: german)
            )
        )
        #expect(
            !DescriptionLanguageProcessor.isGerman(
                DescriptionLanguageProcessor.detectedLanguage(for: english)
            )
        )
        #expect(
            DescriptionLanguageProcessor.originalWithLanguageNote(
                english,
                language: "en"
            ) == english
        )
    }

    @Test @MainActor
    func manualMetadataEditProtectsFieldsAndResolvesReview() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let suggestion = CatalogSuggestion(
            kind: .homepage,
            value: "https://example.com",
            sourceLabel: "Test"
        )
        let app = AppEntry(
            name: "Review Test",
            details: "Unvollständig",
            category: "Test",
            subcategory: "",
            files: [],
            reviewSuggestions: [suggestion]
        )
        store.add(app)
        var edited = try #require(store.apps.first)
        edited.details = "Manuell gepflegte Beschreibung."
        edited.homepage = URL(string: "https://manual.example")
        store.update(edited)

        let result = try #require(store.apps.first)
        #expect(result.customizations.description)
        #expect(result.customizations.links)
        #expect(result.suggestions.isEmpty)
        #expect(result.reviewStatus == .confirmed)
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func translatedSuggestionReplacesOriginalDescription() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let suggestion = CatalogSuggestion(
            kind: .description,
            value: "An English app description.",
            sourceLabel: "Test",
            detectedLanguage: "en",
            needsTranslation: true
        )
        let app = AppEntry(
            name: "Translation Test",
            category: "Test",
            subcategory: "",
            files: [],
            reviewSuggestions: [suggestion]
        )
        store.add(app)

        store.acceptSuggestion(suggestion.id, for: app.id)

        let result = try #require(store.apps.first)
        #expect(result.details.contains("An English app description."))
        #expect(result.suggestions.isEmpty)
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func editorStyleSaveDoesNotTurnAutomaticIconIntoManualIcon() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let app = AppEntry(
            name: "Automatic Icon",
            details: "Original",
            category: "Test",
            subcategory: "",
            iconFileName: "automatic.png",
            files: [],
            userCustomizations: UserCustomizations(),
            iconOrigin: .iTunes
        )
        store.add(app)
        var edited = try #require(store.apps.first)
        edited.details = "Manuell bearbeitete Beschreibung."
        edited.iconData = nil
        edited.iconFileName = "automatic.png"
        edited.iconOrigin = .iTunes

        store.update(edited)

        let result = try #require(store.apps.first)
        #expect(!result.customizations.icon)
        #expect(result.customizations.description)
        #expect(result.iconOrigin == .iTunes)
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func needsReviewFilterShowsOnlyFlaggedEntries() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        store.add(
            AppEntry(
                name: "Flagged",
                category: "Test",
                subcategory: "",
                files: [],
                reviewStatus: .needsReview
            )
        )
        store.add(
            AppEntry(
                name: "Confirmed",
                category: "Test",
                subcategory: "",
                files: [],
                reviewStatus: .confirmed
            )
        )
        store.selectedCategory = CatalogStore.needsReviewFilter

        #expect(store.filteredApps.map(\.name) == ["Flagged"])
        #expect(store.selectedCollectionTitle == "Zu prüfen")
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func catalogSearchIgnoresSelectedCategoryAndMatchesFolderPaths() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        store.add(
            AppEntry(
                name: "SoundBox",
                category: "Audio",
                subcategory: "Player",
                files: []
            )
        )
        store.add(
            AppEntry(
                name: "Capture One",
                category: "Grafik",
                subcategory: "Screenshot",
                files: []
            )
        )
        store.add(
            AppEntry(
                name: "Utility",
                category: "System",
                subcategory: "Werkzeuge",
                files: [
                    LocalAppFile(
                        fileName: "Utility.dmg",
                        fileType: "dmg",
                        sourceCategory: "System",
                        sourceSubcategory: "Werkzeuge",
                        relativePath: "System/Screenshot/Utility.dmg",
                        sizeInBytes: 0,
                        modifiedAt: nil,
                        detectedVersion: nil
                    )
                ]
            )
        )

        store.selectedCategory = "Grafik"
        store.searchText = "soundbox"
        #expect(store.filteredApps.map(\.name) == ["SoundBox"])

        store.searchText = "screen-shot"
        #expect(Set(store.filteredApps.map(\.name)) == Set(["Capture One", "Utility"]))
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func subcategoryFilterShowsOnlyMatchingFolder() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        store.add(
            AppEntry(
                name: "Screenshot App",
                category: "Grafik",
                subcategory: "Screenshot",
                files: [
                    LocalAppFile(
                        fileName: "Screenshot App.dmg",
                        fileType: "dmg",
                        sourceCategory: "Grafik",
                        sourceSubcategory: "Screenshot",
                        relativePath: "Grafik/Screenshot/Screenshot App.dmg",
                        sizeInBytes: 0,
                        modifiedAt: nil,
                        detectedVersion: nil
                    )
                ]
            )
        )
        store.add(
            AppEntry(
                name: "Vector App",
                category: "Grafik",
                subcategory: "Vektor",
                files: [
                    LocalAppFile(
                        fileName: "Vector App.dmg",
                        fileType: "dmg",
                        sourceCategory: "Grafik",
                        sourceSubcategory: "Vektor",
                        relativePath: "Grafik/Vektor/Vector App.dmg",
                        sizeInBytes: 0,
                        modifiedAt: nil,
                        detectedVersion: nil
                    )
                ]
            )
        )
        store.selectedCategory = CatalogStore.subcategoryFilter(
            category: "Grafik",
            subcategory: "Screenshot"
        )

        #expect(store.filteredApps.map(\.name) == ["Screenshot App"])
        #expect(store.selectedCollectionTitle == "Screenshot")
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func folderTreeIncludesEveryNestedFolderAndParentFiltersDescendants() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        store.add(
            AppEntry(
                name: "Nested App",
                category: "Entwicklung",
                subcategory: "Package-Manager",
                files: [
                    LocalAppFile(
                        fileName: "Nested App.dmg",
                        fileType: "dmg",
                        sourceCategory: "Entwicklung",
                        sourceSubcategory: "Package-Manager",
                        relativePath: "Entwicklung/Package-Manager/Homebrew/GUI/Nested App.dmg",
                        sizeInBytes: 0,
                        modifiedAt: nil,
                        detectedVersion: nil
                    )
                ]
            )
        )

        let tree = store.folderTree(for: "Entwicklung")
        let packageManager = tree.first { $0.name == "Package-Manager" }
        let homebrew = packageManager?.children.first { $0.name == "Homebrew" }
        let gui = homebrew?.children.first { $0.name == "GUI" }

        #expect(packageManager?.count == 1)
        #expect(homebrew?.count == 1)
        #expect(gui?.count == 1)

        store.selectedCategory = CatalogStore.subcategoryFilter(
            category: "Entwicklung",
            subcategory: "Package-Manager/Homebrew"
        )
        #expect(store.filteredApps.map(\.name) == ["Nested App"])
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func folderTreeUsesStoredFoldersAndNeverTreatsFilesAsFolders() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        store.add(
            AppEntry(
                name: "Direct App",
                category: "Benchmark",
                subcategory: "",
                files: [
                    LocalAppFile(
                        fileName: "Direct App.dmg",
                        fileType: "dmg",
                        sourceCategory: "Benchmark",
                        sourceSubcategory: "",
                        relativePath: "Benchmark/Direct App.dmg",
                        sizeInBytes: 0,
                        modifiedAt: nil,
                        detectedVersion: nil
                    )
                ]
            )
        )
        store.add(
            AppEntry(
                name: "Nested App",
                category: "Grafik",
                subcategory: "Icons",
                files: [
                    LocalAppFile(
                        fileName: "Nested App.zip",
                        fileType: "zip",
                        sourceCategory: "Grafik",
                        sourceSubcategory: "Icons",
                        relativePath: "Grafik/Icons/Nested App.zip",
                        sizeInBytes: 0,
                        modifiedAt: nil,
                        detectedVersion: nil
                    )
                ]
            )
        )

        #expect(store.folderTree(for: "Benchmark").isEmpty)
        #expect(store.folderTree(for: "Grafik").map(\.name) == ["Icons"])

        store.selectedCategory = CatalogStore.subcategoryFilter(
            category: "Grafik",
            subcategory: "Icons"
        )
        #expect(store.filteredApps.map(\.name) == ["Nested App"])
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func folderTreeIgnoresStoredSubcategoriesThatAreNotRealFolders() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        store.add(
            AppEntry(
                name: "Direct App",
                category: "Benchmark",
                subcategory: "Direct App",
                files: [
                    LocalAppFile(
                        fileName: "Direct App.dmg",
                        fileType: "dmg",
                        sourceCategory: "Benchmark",
                        sourceSubcategory: "Direct App",
                        relativePath: "Benchmark/Direct App.dmg",
                        sizeInBytes: 0,
                        modifiedAt: nil,
                        detectedVersion: nil
                    )
                ]
            )
        )
        store.add(
            AppEntry(
                name: "Manual App",
                category: "Benchmark",
                subcategory: "Manual App",
                files: []
            )
        )

        #expect(store.folderTree(for: "Benchmark").isEmpty)
        store.selectedCategory = "Benchmark"
        #expect(Set(store.filteredApps.map(\.name)) == Set(["Direct App", "Manual App"]))
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test
    func scannerStoresCompleteNestedFolderPath() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let nested = root.appendingPathComponent(
            "Entwicklung/Package-Manager/Homebrew",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: nested,
            withIntermediateDirectories: true
        )
        try Data().write(to: nested.appendingPathComponent("Tool.dmg"))

        let result = try VolumeScanner().scan(root)

        #expect(result.files.first?.sourceCategory == "Entwicklung")
        #expect(
            result.files.first?.sourceSubcategory
                == "Package-Manager/Homebrew"
        )
        #expect(result.apps.first?.subcategory == "Package-Manager/Homebrew")
        try? FileManager.default.removeItem(at: root)
    }

    @Test @MainActor
    func rescanUpdatesLegacyShortFolderPathWithoutCreatingDuplicate() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let path = "Entwicklung/Package-Manager/Homebrew/Tool.dmg"
        store.add(
            AppEntry(
                name: "Tool",
                category: "Entwicklung",
                subcategory: "Package-Manager",
                files: [
                    LocalAppFile(
                        fileName: "Tool.dmg",
                        fileType: "dmg",
                        sourceCategory: "Entwicklung",
                        sourceSubcategory: "Package-Manager",
                        relativePath: path,
                        sizeInBytes: 0,
                        modifiedAt: nil,
                        detectedVersion: nil
                    )
                ]
            )
        )
        store.mergeScannedApps([
            AppEntry(
                name: "Tool",
                category: "Entwicklung",
                subcategory: "Package-Manager/Homebrew",
                files: [
                    LocalAppFile(
                        fileName: "Tool.dmg",
                        fileType: "dmg",
                        sourceCategory: "Entwicklung",
                        sourceSubcategory: "Package-Manager/Homebrew",
                        relativePath: path,
                        sizeInBytes: 0,
                        modifiedAt: nil,
                        detectedVersion: nil
                    )
                ]
            )
        ])

        #expect(store.apps.count == 1)
        #expect(store.apps.first?.subcategory == "Package-Manager/Homebrew")
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func catalogRevisionChangesAfterScanAndManualUpdate() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let initialRevision = store.catalogRevision
        store.mergeScannedApps([
            AppEntry(
                name: "Refresh Test",
                category: "System",
                subcategory: "Tools",
                files: []
            )
        ])
        let scanRevision = store.catalogRevision
        var app = try #require(store.apps.first)
        app.summary = "Updated"
        store.update(app)

        #expect(scanRevision > initialRevision)
        #expect(store.catalogRevision > scanRevision)
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func websitePromptExclusionPersistsAndCanBeReenabled() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let persistence = CatalogPersistence(fileURL: fileURL)
        let store = makeCatalogStore(persistence: persistence)
        let app = AppEntry(
            name: "No Website Prompt",
            category: "System",
            subcategory: "Tools",
            files: [],
            sourceStatus: .manual
        )
        store.add(app)

        store.suppressWebsitePrompt(for: app.id)

        #expect(store.websitePromptExclusions.map(\.id) == [app.id])
        #expect(store.apps.first?.suppressesWebsitePrompt == true)

        let reloaded = makeCatalogStore(persistence: persistence)
        await reloaded.loadBundledCatalog()
        #expect(reloaded.websitePromptExclusions.map(\.id) == [app.id])
        #expect(reloaded.pendingWebsitePrompt == nil)

        reloaded.allowWebsitePrompt(for: app.id)
        #expect(reloaded.websitePromptExclusions.isEmpty)
        #expect(reloaded.apps.first?.suppressesWebsitePrompt == false)
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func confirmingWebsiteClearsPromptExclusion() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let app = AppEntry(
            name: "Website Test",
            category: "System",
            subcategory: "Tools",
            files: [],
            websitePromptSuppressed: true
        )
        store.add(app)

        store.confirmWebsite("https://example.com", for: app.id)

        #expect(store.apps.first?.homepage == URL(string: "https://example.com"))
        #expect(store.websitePromptExclusions.isEmpty)
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func confirmedWebsiteDerivesGitHubAndDownloadLinks() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let githubApp = AppEntry(
            name: "Pearcleaner",
            category: "System",
            subcategory: "Cleaner",
            files: []
        )
        let installerApp = AppEntry(
            name: "Direct Installer",
            category: "System",
            subcategory: "Tools",
            files: []
        )
        store.add([githubApp, installerApp])

        store.confirmWebsite(
            "https://github.com/alienator88/Pearcleaner/releases/latest",
            for: githubApp.id
        )
        store.confirmWebsite(
            "https://downloads.example.com/DirectInstaller.dmg",
            for: installerApp.id
        )

        let apps = Dictionary(uniqueKeysWithValues: store.apps.map {
            ($0.name, $0)
        })
        #expect(
            apps["Pearcleaner"]?.homepage
                == URL(string: "https://github.com/alienator88/Pearcleaner")
        )
        #expect(
            apps["Pearcleaner"]?.githubURL
                == URL(string: "https://github.com/alienator88/Pearcleaner")
        )
        #expect(
            apps["Pearcleaner"]?.downloadURL
                == URL(string: "https://github.com/alienator88/Pearcleaner/releases/latest")
        )
        #expect(
            apps["Direct Installer"]?.homepage
                == URL(string: "https://downloads.example.com")
        )
        #expect(
            apps["Direct Installer"]?.downloadURL
                == URL(string: "https://downloads.example.com/DirectInstaller.dmg")
        )
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test
    func scannerKeepsNumberedAppEditionsSeparate() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let category = root.appendingPathComponent(
            "Benchmark",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: category,
            withIntermediateDirectories: true
        )
        for name in [
            "BenchmarkR23.dmg",
            "Benchmark2024_macOS.dmg",
            "Benchmark2026_macOS.dmg"
        ] {
            try Data().write(to: category.appendingPathComponent(name))
        }

        let result = try VolumeScanner().scan(root)

        #expect(result.apps.count == 3)
        #expect(Set(result.apps.map(\.name)) == Set([
            "BenchmarkR23",
            "Benchmark2024",
            "Benchmark2026"
        ]))
        try? FileManager.default.removeItem(at: root)
    }

    @Test @MainActor
    func rescanSplitsPreviouslyMergedNumberedEditions() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = makeCatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )
        let firstPath = "Benchmark/Benchmark2024_macOS.dmg"
        let secondPath = "Benchmark/Benchmark2026_macOS.dmg"
        let makeFile: (String, String) -> LocalAppFile = { name, path in
            LocalAppFile(
                fileName: name,
                fileType: "dmg",
                sourceCategory: "Benchmark",
                sourceSubcategory: "",
                relativePath: path,
                sizeInBytes: 0,
                modifiedAt: nil,
                detectedVersion: nil
            )
        }
        store.add(
            AppEntry(
                name: "Benchmark",
                category: "Benchmark",
                subcategory: "",
                files: [
                    makeFile("Benchmark2024_macOS.dmg", firstPath),
                    makeFile("Benchmark2026_macOS.dmg", secondPath)
                ]
            )
        )

        store.mergeScannedApps([
            AppEntry(
                name: "Benchmark2024",
                category: "Benchmark",
                subcategory: "",
                files: [
                    makeFile("Benchmark2024_macOS.dmg", firstPath)
                ]
            ),
            AppEntry(
                name: "Benchmark2026",
                category: "Benchmark",
                subcategory: "",
                files: [
                    makeFile("Benchmark2026_macOS.dmg", secondPath)
                ]
            )
        ])

        #expect(Set(store.apps.map(\.name)) == Set([
            "Benchmark2024", "Benchmark2026"
        ]))
        #expect(store.apps.allSatisfy { $0.files.count == 1 })
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test @MainActor
    func loadingCatalogSplitsPreviouslyMergedNumberedEditions() {
        let first = LocalAppFile(
            fileName: "Benchmark2024_macOS.dmg",
            fileType: "dmg",
            sourceCategory: "Benchmark",
            sourceSubcategory: "",
            relativePath: "Benchmark/Benchmark2024_macOS.dmg",
            sizeInBytes: 0,
            modifiedAt: nil,
            detectedVersion: nil
        )
        let second = LocalAppFile(
            fileName: "Benchmark2026_macOS.dmg",
            fileType: "dmg",
            sourceCategory: "Benchmark",
            sourceSubcategory: "",
            relativePath: "Benchmark/Benchmark2026_macOS.dmg",
            sizeInBytes: 0,
            modifiedAt: nil,
            detectedVersion: nil
        )
        let merged = AppEntry(
            name: "Benchmark2024",
            category: "Benchmark",
            subcategory: "",
            files: [first, second]
        )

        let repaired = CatalogStore.splittingMergedEntries(in: [merged])

        #expect(Set(repaired.map(\.name)) == Set([
            "Benchmark2024", "Benchmark2026"
        ]))
        #expect(repaired.allSatisfy { $0.files.count == 1 })
        #expect(repaired.first { $0.name == "Benchmark2024" }?.id == merged.id)
    }

    @Test @MainActor
    func loadingCatalogRepairsSingleEntryLocationFromItsFile() throws {
        let file = LocalAppFile(
            fileName: "Package Tool.app",
            fileType: "app",
            sourceCategory: "Downloads",
            sourceSubcategory: "Package Managers",
            relativePath: "Downloads/Package Managers/Package Tool.app",
            sizeInBytes: 0,
            modifiedAt: nil,
            detectedVersion: nil
        )
        let originalID = UUID()
        let misplaced = AppEntry(
            id: originalID,
            name: "Package Tool",
            summary: "Existing summary",
            details: "Existing description",
            category: "Development",
            subcategory: "Tools",
            homepage: URL(string: "https://example.com"),
            files: [file]
        )

        let repaired = try #require(
            CatalogStore.splittingMergedEntries(in: [misplaced]).first
        )

        #expect(repaired.id == originalID)
        #expect(repaired.category == "Downloads")
        #expect(repaired.subcategory == "Package Managers")
        #expect(repaired.summary == "Existing summary")
        #expect(repaired.details == "Existing description")
        #expect(repaired.homepage == misplaced.homepage)
    }

    @Test
    func scannerNeverMergesSameNamedAppsAcrossFolders() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        for path in [
            "Grafik/Screenshot/Studio.dmg",
            "Audio/Player/Studio.dmg",
            "Entwicklung/Editor/Studio.dmg"
        ] {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data().write(to: url)
        }

        let result = try VolumeScanner().scan(root)

        #expect(result.files.count == 3)
        #expect(result.apps.count == 3)
        #expect(Set(result.apps.map(\.category)) == Set([
            "Grafik", "Audio", "Entwicklung"
        ]))
        #expect(result.apps.flatMap(\.files).count == result.files.count)
        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func scannerRepresentsEveryIncludedFileInCatalogEntries() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileNames = [
            "Werkzeuge/Alpha-One.dmg",
            "Werkzeuge/Alpha_One.pkg",
            "Werkzeuge/Beta2.zip",
            "Werkzeuge/Beta3.zip",
            "Medien/Screenshot Tool.app"
        ]
        for path in fileNames {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if url.pathExtension == "app" {
                try FileManager.default.createDirectory(
                    at: url,
                    withIntermediateDirectories: true
                )
            } else {
                try Data().write(to: url)
            }
        }

        let result = try VolumeScanner().scan(root)
        let representedPaths = result.apps.flatMap(\.files).map(\.relativePath)

        #expect(result.files.count == fileNames.count)
        #expect(representedPaths.count == result.files.count)
        #expect(Set(representedPaths) == Set(result.files.map(\.relativePath)))
        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func searchMatchesJoinedAndSeparatedWordsGenerally() {
        let app = AppEntry(
            name: "ExampleCapture",
            category: "Grafik",
            subcategory: "Bild Aufnahme",
            files: []
        )

        #expect(app.matchesSearch("example capture"))
        #expect(app.matchesSearch("Bildaufnahme"))
        #expect(app.matchesSearch("capture"))
    }

    @Test @MainActor
    func tagsAreSearchableAndFilterable() {
        let store = makeCatalogStore()
        let screenshotApp = AppEntry(
            name: "Bildschirm Werkzeug",
            summary: "Screenshots aufnehmen",
            category: "Grafik",
            subcategory: "Screenshot",
            tags: ["Screenshot", "Favorit"],
            files: []
        )
        let otherApp = AppEntry(
            name: "Video Werkzeug",
            summary: "Videos bearbeiten",
            category: "Multimedia",
            subcategory: "Video",
            tags: ["Video"],
            files: []
        )

        store.add([screenshotApp, otherApp])
        store.selectedCategory = CatalogStore.tagFilter("Screenshot")

        #expect(screenshotApp.matchesSearch("favorit"))
        #expect(store.tags.map(\.name).contains("Screenshot"))
        #expect(store.filteredApps.map(\.id) == [screenshotApp.id])
        #expect(store.selectedCollectionTitle == "#Screenshot")
    }

    @Test
    func legacyCatalogEntriesDecodeWithoutTags() throws {
        let app = AppEntry(
            name: "Legacy App",
            category: "Test",
            subcategory: "",
            files: []
        )
        var object = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(app)
            ) as? [String: Any]
        )
        object.removeValue(forKey: "tags")
        let data = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(AppEntry.self, from: data)

        #expect(decoded.tags.isEmpty)
    }

    @Test @MainActor
    func catalogStatisticsSummarizeLocalCatalogAndLicenses() throws {
        let licenseStorage = InMemoryLicenseStorage()
        let store = makeCatalogStore(licenseStorage: licenseStorage)
        let validIconData = testIconData()
        #expect(validIconData != nil)
        let licensed = AppEntry(
            name: "Lizenzierte App",
            summary: "Hat eine Beschreibung",
            details: "",
            category: "Office",
            subcategory: "",
            homepage: URL(string: "https://example.invalid"),
            iconData: validIconData,
            files: [
                LocalAppFile(
                    fileName: "Licensed.dmg",
                    fileType: "DMG",
                    sourceCategory: "Office",
                    sourceSubcategory: "",
                    relativePath: "Office/Licensed.dmg",
                    sizeInBytes: 1_500_000,
                    modifiedAt: nil,
                    detectedVersion: nil
                )
            ]
        )
        let incomplete = AppEntry(
            name: "Unvollständige App",
            category: "Office",
            subcategory: "",
            files: [],
            sourceStatus: .manual
        )
        try licenseStorage.save(
            AppLicenseRecord(
                serialNumber: ["TEST", "LICENSE"].joined(separator: "-")
            ),
            for: licensed.id
        )

        try store.replaceCatalog(with: [licensed, incomplete])
        let statistics = store.statistics

        #expect(statistics.totalApps == 2)
        #expect(statistics.appsPerCategory.first?.category == "Office")
        #expect(statistics.appsPerCategory.first?.count == 2)
        #expect(statistics.totalSizeInBytes == 1_500_000)
        #expect(statistics.appsWithoutDescription == 1)
        #expect(statistics.appsWithoutIcon == 1)
        #expect(statistics.appsWithoutHomepage == 1)
        #expect(statistics.appsWithLicenseData == 1)
    }

    @Test
    func searchToleratesSmallTyposInAppNamesOnly() {
        let catalogTool = AppEntry(
            name: "CatalogTool",
            details: "A file manager",
            category: "Network",
            subcategory: "Files",
            files: []
        )
        let displayTool = AppEntry(
            name: "DisplayManager",
            details: "Controls displays",
            category: "System",
            subcategory: "Monitor",
            files: []
        )
        let unrelated = AppEntry(
            name: "Audio Player",
            details: "Creates and edits sound effects",
            category: "Audio",
            subcategory: "Player",
            files: []
        )

        #expect(catalogTool.matchesSearch("CatlogTool"))
        #expect(displayTool.matchesSearch("Display Managr"))
        #expect(!unrelated.matchesSearch("CatlogTool"))
    }

    @Test
    func scansSupportedFilesWithoutChangingThem() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let category = root.appendingPathComponent("Multimedia/Video", isDirectory: true)
        try FileManager.default.createDirectory(at: category, withIntermediateDirectories: true)
        let installer = category.appendingPathComponent("VideoTool-2.1.dmg")
        try Data("unchanged".utf8).write(to: installer)

        let result = try VolumeScanner().scan(root)

        #expect(result.files.count == 1)
        #expect(result.files[0].relativePath == "Multimedia/Video/VideoTool-2.1.dmg")
        #expect(result.files[0].sizeInBytes == 9)
        #expect(result.files[0].modifiedAt != nil)
        #expect(result.files[0].iconData == nil)
        #expect(try String(contentsOf: installer, encoding: .utf8) == "unchanged")
        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func scannerAppliesCustomDirectoryExclusions() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        for path in [
            "Tools/Visible.dmg",
            "Archive/Hidden.dmg",
            "Media/Old/Hidden.pkg",
            "Media/New/Visible.pkg"
        ] {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data().write(to: url)
        }

        let result = try VolumeScanner(
            excludedDirectories: ["Archive", "Media/Old"]
        ).scan(root)

        #expect(Set(result.files.map(\.relativePath)) == Set([
            "Tools/Visible.dmg",
            "Media/New/Visible.pkg"
        ]))
        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func scannerSettingsNormalizeAndDeduplicateEntries() {
        let parsed = ScannerSettings.parse(
            " Archive \nMedia/Old\nArchive\n\n"
        )

        #expect(parsed == ["Archive", "Media/Old"])
        #expect(
            ScannerSettings.encode(["Media/Old", "Archive", "Archive"])
                == "Archive\nMedia/Old"
        )
    }

    @Test
    func scannerAppliesAndNormalizesFileExtensionExclusions() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
        for fileName in ["Application.dmg", "Archive.ISO", "Package.pkg"] {
            try Data().write(to: root.appendingPathComponent(fileName))
        }

        let parsed = ScannerSettings.parseFileExtensions(
            " .ISO \niso\n ZIP\ninvalid value\n"
        )
        let result = try VolumeScanner(
            excludedFileExtensions: parsed
        ).scan(root)

        #expect(parsed == ["iso", "zip"])
        #expect(
            ScannerSettings.encodeFileExtensions([".ISO", "zip", "ISO"])
                == "iso\nzip"
        )
        #expect(Set(result.files.map(\.fileType)) == Set(["dmg", "pkg"]))
        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func scannerExcludesDirectlySelectedLocalFolder() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let included = root.appendingPathComponent("Included/App.dmg")
        let excludedFolder = root.appendingPathComponent(
            "Excluded",
            isDirectory: true
        )
        let excluded = excludedFolder.appendingPathComponent("Hidden.dmg")
        for url in [included, excluded] {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data().write(to: url)
        }

        let result = try VolumeScanner(
            excludedDirectoryURLs: [excludedFolder]
        ).scan(root)

        #expect(result.files.map(\.relativePath) == ["Included/App.dmg"])
        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func scanExcludesBackupDataAndTechnicalCollections() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let includedDirectory = root.appendingPathComponent(
            "Backup/App-Installer",
            isDirectory: true
        )
        let oldBackupDirectory = root.appendingPathComponent(
            "Backup/Old Disk Backup/Archive",
            isDirectory: true
        )
        let pluginDirectory = root.appendingPathComponent(
            "Entwicklung/Editoren/Plugins",
            isDirectory: true
        )
        let macSoftwareBackupDirectory = root.appendingPathComponent(
            "Backup/Festplatte Diverses Backup/GDrive/Handy/Apps",
            isDirectory: true
        )
        let downloaderConfigDirectory = root.appendingPathComponent(
            "Download/JDownloader 2/cfg",
            isDirectory: true
        )
        let nextPadPluginDirectory = root.appendingPathComponent(
            "Entwicklung/Editoren/NextPad/Plugins",
            isDirectory: true
        )
        let crackReadmeDirectory = root.appendingPathComponent(
            "Grafik/Adobe/Adobe Lightroom Classic/CRACK - README",
            isDirectory: true
        )
        let macosxDirectory = root.appendingPathComponent(
            "__MACOSX",
            isDirectory: true
        )
        for directory in [
            includedDirectory,
            oldBackupDirectory,
            pluginDirectory,
            macSoftwareBackupDirectory,
            downloaderConfigDirectory,
            nextPadPluginDirectory,
            crackReadmeDirectory,
            macosxDirectory
        ] {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }

        try Data().write(to: includedDirectory.appendingPathComponent("BackupUtility.dmg"))
        try Data().write(to: includedDirectory.appendingPathComponent("Mail_profile_backup.zip"))
        try Data().write(to: oldBackupDirectory.appendingPathComponent("OldTool.exe"))
        try Data().write(to: pluginDirectory.appendingPathComponent("EditorPlugin.zip"))
        try Data().write(to: macSoftwareBackupDirectory.appendingPathComponent("AndroPods.apk"))
        try Data().write(to: downloaderConfigDirectory.appendingPathComponent("downloadList194.zip"))
        try Data().write(to: nextPadPluginDirectory.appendingPathComponent("ComparePlus.zip"))
        try Data().write(to: crackReadmeDirectory.appendingPathComponent("Offline Crack.dmg"))
        try Data().write(to: macosxDirectory.appendingPathComponent("ArchiveHelper.dmg"))

        let result = try VolumeScanner().scan(root)

        #expect(result.files.map(\.fileName) == ["BackupUtility.dmg"])
        #expect(result.apps.map(\.name) == ["BackupUtility"])
        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func scanKeepsBackupApplicationsOutsideBackupArchives() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let category = root.appendingPathComponent("Backup", isDirectory: true)
        try FileManager.default.createDirectory(at: category, withIntermediateDirectories: true)
        try Data().write(to: category.appendingPathComponent("Backup To Go.dmg"))
        try Data().write(to: category.appendingPathComponent("AOMEI Backupper.zip"))

        let result = try VolumeScanner().scan(root)

        #expect(Set(result.files.map(\.fileName)) == Set([
            "Backup To Go.dmg",
            "AOMEI Backupper.zip"
        ]))
        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func scanKeepsRealAppsFromReferenceComparison() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let appBundle = root.appendingPathComponent(
            "Backup/Backup To Go 2.app",
            isDirectory: true
        )
        let appInternalResource = appBundle.appendingPathComponent(
            "Contents/Resources/InternalHelper.dmg"
        )
        let files = [
            "Backup/App-Installer/AppStateSaver.dmg",
            "Multimedia/Audio/Radiola-12.2.0.dmg",
            "Hardware/Monitor/Atoll.2.2.0.dmg",
            "Download/Harbor-1.2.10.dmg"
        ]
        try FileManager.default.createDirectory(
            at: appInternalResource.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data().write(to: appInternalResource)
        for path in files {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data().write(to: url)
        }

        let result = try VolumeScanner().scan(root)
        let paths = Set(result.files.map(\.relativePath))

        #expect(paths.contains("Backup/Backup To Go 2.app"))
        #expect(!paths.contains("Backup/Backup To Go 2.app/Contents/Resources/InternalHelper.dmg"))
        #expect(paths.contains("Backup/App-Installer/AppStateSaver.dmg"))
        #expect(paths.contains("Multimedia/Audio/Radiola-12.2.0.dmg"))
        #expect(paths.contains("Hardware/Monitor/Atoll.2.2.0.dmg"))
        #expect(paths.contains("Download/Harbor-1.2.10.dmg"))
        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func scannerHandlesLargeFlatCollectionEfficiently() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let category = root.appendingPathComponent("Grafik", isDirectory: true)
        try FileManager.default.createDirectory(
            at: category,
            withIntermediateDirectories: true
        )
        for index in 0..<3_000 {
            try Data().write(
                to: category.appendingPathComponent("Data-\(index).txt")
            )
        }
        for index in 0..<263 {
            try Data().write(
                to: category.appendingPathComponent("App-\(index).dmg")
            )
        }

        let startedAt = Date()
        let result = try VolumeScanner().scan(root)
        let duration = Date().timeIntervalSince(startedAt)

        #expect(result.files.count == 263)
        #expect(duration < 10)
        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func extractsIconFromLocalAppBundle() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let appURL = root.appendingPathComponent("Example.app", isDirectory: true)
        let contents = appURL.appendingPathComponent("Contents", isDirectory: true)
        let resources = contents.appendingPathComponent("Resources", isDirectory: true)
        try FileManager.default.createDirectory(
            at: resources,
            withIntermediateDirectories: true
        )

        let info: [String: Any] = [
            "CFBundleIconFile": "ExampleIcon.png",
            "CFBundleIdentifier": "com.example.app",
            "NSHumanReadableCopyright":
                "Copyright © 2026 Example Software. All rights reserved."
        ]
        let infoData = try PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        )
        try infoData.write(to: contents.appendingPathComponent("Info.plist"))

        let png = Data(base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
        )
        try #require(png).write(
            to: resources.appendingPathComponent("ExampleIcon.png")
        )

        let iconData = LocalAppIconExtractor().iconData(for: appURL)
        let metadata = LocalAppMetadataExtractor().metadata(for: appURL)

        #expect(iconData?.isEmpty == false)
        #expect(metadata.bundleIdentifier == "com.example.app")
        #expect(metadata.developer == "Example Software")
        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func convertsDroppedImageToCompactPNG() throws {
        let source = try #require(Data(base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
        ))
        let converted = try #require(
            IconImageConverter.compactPNG(from: source)
        )

        #expect(converted.starts(with: [0x89, 0x50, 0x4E, 0x47]))
        #expect(converted.count <= IconImageConverter.maximumStoredBytes)
        #expect(converted == source)
    }

    @Test
    func enrichesPlaceholderDescriptions() {
        let app = AppEntry(
            name: "Movie Tool",
            summary: "Aus einem lokalen App-Bestand importiert.",
            details: "Metadaten und Beschreibung müssen noch geprüft und ergänzt werden.",
            category: "Multimedia",
            subcategory: "Video",
            files: []
        )

        let enriched = AppMetadataEnricher().enrich(app)

        #expect(enriched.summary.contains("Video"))
        #expect(enriched.details.contains("Multimedia / Video"))
    }

    @Test
    func keepsManualAppsWithoutFiles() {
        let app = AppEntry(
            name: "Manueller Eintrag",
            category: "Test",
            subcategory: "",
            files: [],
            sourceStatus: .manual
        )

        #expect(CatalogEntryFilter().shouldInclude(app))
    }

    @Test
    func recommendsAppsFromLocalMetadata() throws {
        let apps = [
            AppEntry(
                name: "Movie Studio",
                summary: "Videos schneiden und erstellen",
                category: "Multimedia",
                subcategory: "Video",
                keywords: ["Videoschnitt", "Film"],
                files: []
            ),
            AppEntry(
                name: "Backup Tool",
                summary: "Dateien sichern",
                category: "Backup",
                subcategory: "Sicherung",
                files: []
            )
        ]

        let recommendations = CatalogAssistant().localRecommendations(
            query: "Mit welcher App kann ich Videos erstellen?",
            apps: apps
        )

        #expect(recommendations.first?.appName == "Movie Studio")
    }

    @MainActor
    private func knownScannedApp(
        name: String,
        fileName: String,
        category: String,
        subcategory: String
    ) -> AppEntry {
        AppEntry(
            name: name,
            category: category,
            subcategory: subcategory,
            files: [
                localFile(
                    named: fileName,
                    category: category,
                    subcategory: subcategory
                )
            ]
        )
    }

    private func localFile(
        named fileName: String,
        category: String = "Test",
        subcategory: String = ""
    ) -> LocalAppFile {
        LocalAppFile(
            fileName: fileName,
            fileType: (fileName as NSString).pathExtension.lowercased(),
            sourceCategory: category,
            sourceSubcategory: subcategory,
            relativePath: [category, subcategory, fileName]
                .filter { !$0.isEmpty }
                .joined(separator: "/"),
            sizeInBytes: 0,
            modifiedAt: nil,
            detectedVersion: AppNameNormalizer.detectVersion(in: fileName)
        )
    }

    private func testIconData() -> Data? {
        let size = NSSize(width: 128, height: 128)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.systemBlue.setFill()
        NSBezierPath(
            roundedRect: NSRect(origin: .zero, size: size),
            xRadius: 28,
            yRadius: 28
        ).fill()
        NSColor.white.setFill()
        NSBezierPath(
            ovalIn: NSRect(x: 38, y: 38, width: 52, height: 52)
        ).fill()
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation else {
            return nil
        }
        return IconImageConverter.compactPNG(from: tiff)
    }

    @MainActor
    private func makeCatalogStore(
        persistence: CatalogPersistence = CatalogPersistence(),
        licenseStorage: any LicenseStorage = InMemoryLicenseStorage(),
        homebrewCaskMetadataCache: HomebrewCaskMetadataCache = .shared,
        targetLanguageProvider: @escaping @Sendable () -> String = {
            AppLanguageChoice.current.resolvedLanguage()
        }
    ) -> CatalogStore {
        CatalogStore(
            persistence: persistence,
            licenseStorage: licenseStorage,
            homebrewCaskMetadataCache: homebrewCaskMetadataCache,
            targetLanguageProvider: targetLanguageProvider
        )
    }
}
