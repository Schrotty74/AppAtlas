import CommonCrypto
import CryptoKit
import Foundation
import Security

struct CatalogImportResult: Sendable {
    let apps: [AppEntry]
    let licenses: [UUID: AppLicenseRecord]
}

enum CatalogExportProtection: Sendable {
    case withoutLicenses
    case licensesPlaintext
    case licensesEncrypted(password: String)
}

enum CatalogTransferDocument {
    static func encoded(
        apps: [AppEntry],
        protection: CatalogExportProtection,
        licenseStore: LicenseKeychainStore = .shared
    ) throws -> Data {
        switch protection {
        case .withoutLicenses:
            return try CatalogDocument(apps: apps).encoded()
        case .licensesPlaintext:
            return try encoder.encode(
                PlaintextDocument(
                    payload: Payload(
                        apps: apps,
                        licenses: exportedLicenses(
                            for: apps,
                            licenseStore: licenseStore
                        )
                    )
                )
            )
        case .licensesEncrypted(let password):
            guard !password.isEmpty else {
                throw CatalogTransferError.emptyPassword
            }
            let payloadData = try encoder.encode(
                Payload(
                    apps: apps,
                    licenses: exportedLicenses(
                        for: apps,
                        licenseStore: licenseStore
                    )
                )
            )
            return try encoder.encode(
                EncryptedDocument.encrypt(payloadData, password: password)
            )
        }
    }

    static func decode(
        _ data: Data,
        password: String? = nil
    ) throws -> CatalogImportResult {
        if let encrypted = try? decoder.decode(EncryptedDocument.self, from: data),
           encrypted.format == EncryptedDocument.expectedFormat
        {
            guard let password else {
                throw CatalogTransferError.passwordRequired
            }
            let payloadData = try encrypted.decrypt(password: password)
            return try decoder.decode(Payload.self, from: payloadData).result
        }

        if let plaintext = try? decoder.decode(PlaintextDocument.self, from: data),
           plaintext.format == PlaintextDocument.expectedFormat,
           plaintext.version == 1
        {
            return plaintext.payload.result
        }

        let legacy = try CatalogDocument.decode(data)
        return CatalogImportResult(apps: legacy.apps, licenses: [:])
    }

    static func requiresPassword(_ data: Data) -> Bool {
        guard let document = try? decoder.decode(EncryptedDocument.self, from: data)
        else {
            return false
        }
        return document.format == EncryptedDocument.expectedFormat
    }

    private static func exportedLicenses(
        for apps: [AppEntry],
        licenseStore: LicenseKeychainStore
    ) -> [LicenseItem] {
        apps.compactMap { app in
            licenseStore.load(for: app.id).map {
                LicenseItem(appID: app.id, record: $0)
            }
        }
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private struct Payload: Codable, Sendable {
    let apps: [AppEntry]
    let licenses: [LicenseItem]

    var result: CatalogImportResult {
        CatalogImportResult(
            apps: apps,
            licenses: Dictionary(
                uniqueKeysWithValues: licenses.map { ($0.appID, $0.record) }
            )
        )
    }
}

private struct LicenseItem: Codable, Sendable {
    let appID: UUID
    let record: AppLicenseRecord
}

private struct PlaintextDocument: Codable, Sendable {
    static let expectedFormat = "appatlas-catalog-with-licenses"

    let format: String
    let version: Int
    let exportedAt: Date
    let warning: String
    let payload: Payload

    init(payload: Payload) {
        self.format = Self.expectedFormat
        self.version = 1
        self.exportedAt = Date()
        self.warning = "Enthält private Lizenzdaten im Klartext."
        self.payload = payload
    }
}

private struct EncryptedDocument: Codable, Sendable {
    static let expectedFormat = "appatlas-encrypted-catalog"
    static let iterationCount = 600_000

    let format: String
    let version: Int
    let exportedAt: Date
    let algorithm: String
    let keyDerivation: String
    let iterations: Int
    let salt: Data
    let sealedData: Data

    static func encrypt(_ payload: Data, password: String) throws -> Self {
        let salt = try randomData(count: 32)
        let key = try derivedKey(
            password: password,
            salt: salt,
            iterations: iterationCount
        )
        let sealed = try AES.GCM.seal(payload, using: key)
        guard let combined = sealed.combined else {
            throw CatalogTransferError.encryptionFailed
        }
        return Self(
            format: expectedFormat,
            version: 1,
            exportedAt: Date(),
            algorithm: "AES-256-GCM",
            keyDerivation: "PBKDF2-HMAC-SHA256",
            iterations: iterationCount,
            salt: salt,
            sealedData: combined
        )
    }

    func decrypt(password: String) throws -> Data {
        guard format == Self.expectedFormat,
              version == 1,
              algorithm == "AES-256-GCM",
              keyDerivation == "PBKDF2-HMAC-SHA256",
              (100_000...2_000_000).contains(iterations)
        else {
            throw CatalogTransferError.unsupportedFormat
        }
        do {
            let key = try Self.derivedKey(
                password: password,
                salt: salt,
                iterations: iterations
            )
            return try AES.GCM.open(
                AES.GCM.SealedBox(combined: sealedData),
                using: key
            )
        } catch {
            throw CatalogTransferError.wrongPasswordOrDamagedFile
        }
    }

    private static func derivedKey(
        password: String,
        salt: Data,
        iterations: Int
    ) throws -> SymmetricKey {
        let keyLength = 32
        var keyData = Data(count: keyLength)
        let result = keyData.withUnsafeMutableBytes { keyBytes in
            salt.withUnsafeBytes { saltBytes in
                password.withCString { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes,
                        strlen(passwordBytes),
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        keyBytes.bindMemory(to: UInt8.self).baseAddress,
                        keyLength
                    )
                }
            }
        }
        guard result == kCCSuccess else {
            throw CatalogTransferError.keyDerivationFailed
        }
        return SymmetricKey(data: keyData)
    }

    private static func randomData(count: Int) throws -> Data {
        var data = Data(count: count)
        let status = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!)
        }
        guard status == errSecSuccess else {
            throw CatalogTransferError.randomGenerationFailed
        }
        return data
    }
}

enum CatalogTransferError: LocalizedError {
    case emptyPassword
    case passwordRequired
    case wrongPasswordOrDamagedFile
    case unsupportedFormat
    case encryptionFailed
    case keyDerivationFailed
    case randomGenerationFailed

    var errorDescription: String? {
        switch self {
        case .emptyPassword:
            "Für den verschlüsselten Export ist ein Passwort erforderlich."
        case .passwordRequired:
            "Dieser Katalog ist passwortgeschützt."
        case .wrongPasswordOrDamagedFile:
            "Das Passwort ist falsch oder die Exportdatei wurde beschädigt."
        case .unsupportedFormat:
            "Das verschlüsselte Exportformat wird nicht unterstützt."
        case .encryptionFailed:
            "Die Lizenzdaten konnten nicht verschlüsselt werden."
        case .keyDerivationFailed:
            "Der Verschlüsselungsschlüssel konnte nicht erzeugt werden."
        case .randomGenerationFailed:
            "Sichere Zufallsdaten konnten nicht erzeugt werden."
        }
    }
}
