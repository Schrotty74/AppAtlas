import Foundation
import Testing
@testable import AppAtlas

struct TSVImporterTests {
    @Test
    func importsValidRow() throws {
        let text = """
        Name\tTyp\tHauptkategorie\tUnterkategorie\tRelativer Pfad\tGroesse Bytes\tGeaendert
        ExampleTool.zip\tzip\tSystem\tHardware\tSystem/Hardware/ExampleTool.zip\t2048\t2026-06-07 10:00:00
        """

        let files = try TSVImporter().importFiles(from: Data(text.utf8))

        #expect(files.count == 1)
        #expect(files[0].fileName == "ExampleTool.zip")
        #expect(files[0].sizeInBytes == 2048)
    }

    @Test
    func rejectsUnexpectedHeader() {
        let text = "Name\tTyp\nTest.dmg\tdmg"

        #expect(throws: TSVImportError.self) {
            try TSVImporter().importFiles(from: Data(text.utf8))
        }
    }

    @Test
    func mergesKnownMultipleFiles() throws {
        let text = """
        Name\tTyp\tHauptkategorie\tUnterkategorie\tRelativer Pfad\tGroesse Bytes\tGeaendert
        ExampleTool.app\tapp\tSystem\tHardware\tSystem/ExampleTool.app\t100\t2026-06-07 10:00:00
        ExampleTool.zip\tzip\tSystem\tHardware\tSystem/ExampleTool.zip\t200\t2026-06-07 10:00:00
        """
        let files = try TSVImporter().importFiles(from: Data(text.utf8))

        let entries = AppCatalogBuilder().buildEntries(from: files)

        #expect(entries.count == 1)
        #expect(entries[0].name == "ExampleTool")
        #expect(entries[0].files.count == 2)
        #expect(!entries[0].summary.isEmpty)
        #expect(!entries[0].details.isEmpty)
    }

    @Test @MainActor
    func newUserStartsWithEmptyCatalog() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("catalog.json")
        let store = CatalogStore(
            persistence: CatalogPersistence(fileURL: fileURL)
        )

        await store.loadBundledCatalog()

        #expect(store.apps.isEmpty)
        #expect(try CatalogPersistence(fileURL: fileURL).load() == [])
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }
}
