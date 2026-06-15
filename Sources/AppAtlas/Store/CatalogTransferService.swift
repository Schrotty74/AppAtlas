import Foundation

enum PreparedCatalogImport: Sendable {
    case ready(CatalogImportResult)
    case passwordRequired(Data)
}

struct CatalogTransferService: Sendable {
    private let licenseStorage: any LicenseStorage

    init(licenseStorage: any LicenseStorage = LicenseKeychainStore.shared) {
        self.licenseStorage = licenseStorage
    }

    func prepareImport(from url: URL) throws -> PreparedCatalogImport {
        let data = try SecurityScopedFileAccess.readData(from: url)
        if CatalogTransferDocument.requiresPassword(data) {
            return .passwordRequired(data)
        }
        return .ready(try CatalogTransferDocument.decode(data))
    }

    func decodeEncrypted(_ data: Data, password: String) throws
        -> CatalogImportResult
    {
        try CatalogTransferDocument.decode(data, password: password)
    }

    func exportData(
        apps: [AppEntry],
        protection: CatalogExportProtection
    ) throws -> Data {
        try CatalogTransferDocument.encoded(
            apps: apps,
            protection: protection,
            licenseStore: licenseStorage
        )
    }
}
