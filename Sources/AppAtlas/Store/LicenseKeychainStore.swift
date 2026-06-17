import Foundation
import Security

extension Notification.Name {
    static let appAtlasLicenseDataDidChange = Notification.Name(
        "AppAtlasLicenseDataDidChange"
    )
}

protocol LicenseStorage: Sendable {
    func load(for appID: UUID) -> AppLicenseRecord?
    func loadForExport(for appID: UUID) throws -> AppLicenseRecord?
    func hasRecord(for appID: UUID) -> Bool
    func save(_ record: AppLicenseRecord, for appID: UUID) throws
    func delete(for appID: UUID)
}

extension LicenseStorage {
    func loadForExport(for appID: UUID) throws -> AppLicenseRecord? {
        load(for: appID)
    }

    func hasRecord(for appID: UUID) -> Bool {
        load(for: appID)?.isEmpty == false
    }

    func save(_ records: [UUID: AppLicenseRecord]) throws {
        for (appID, record) in records {
            try save(record, for: appID)
        }
    }
}

private enum LicenseRecordIndex {
    private static let key = "licenseRecordAppIDs"

    static func contains(_ appID: UUID) -> Bool {
        appIDs().contains(appID.uuidString)
    }

    static func add(_ appID: UUID) {
        var ids = appIDs()
        ids.insert(appID.uuidString)
        save(ids)
    }

    static func remove(_ appID: UUID) {
        var ids = appIDs()
        ids.remove(appID.uuidString)
        save(ids)
    }

    private static func appIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    private static func save(_ ids: Set<String>) {
        UserDefaults.standard.set(
            ids.sorted(),
            forKey: key
        )
    }
}

struct LicenseKeychainStore: LicenseStorage, Sendable {
    static let shared = LicenseKeychainStore()
    private let service = "at.schrotty.appatlas.licenses"

    func load(for appID: UUID) -> AppLicenseRecord? {
        try? loadItem(for: appID)
    }

    func loadForExport(for appID: UUID) throws -> AppLicenseRecord? {
        try loadItem(for: appID)
    }

    private func loadItem(
        for appID: UUID
    ) throws -> AppLicenseRecord? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: appID.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
        guard let data = result as? Data else {
            return nil
        }
        return try JSONDecoder().decode(AppLicenseRecord.self, from: data)
    }

    func hasRecord(for appID: UUID) -> Bool {
        LicenseRecordIndex.contains(appID)
    }

    func save(_ record: AppLicenseRecord, for appID: UUID) throws {
        if record.isEmpty {
            delete(for: appID)
            return
        }
        let data = try JSONEncoder().encode(record)
        let identity: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: appID.uuidString
        ]
        let values: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrLabel as String: "AppAtlas-Lizenz"
        ]
        let status = SecItemUpdate(
            identity as CFDictionary,
            values as CFDictionary
        )
        if status == errSecItemNotFound {
            var item = identity
            values.forEach { item[$0.key] = $0.value }
            let addStatus = SecItemAdd(item as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.status(addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.status(status)
        }
        LicenseRecordIndex.add(appID)
    }

    func delete(for appID: UUID) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: appID.uuidString
        ]
        SecItemDelete(query as CFDictionary)
        LicenseRecordIndex.remove(appID)
    }

    enum KeychainError: LocalizedError {
        case status(OSStatus)

        var errorDescription: String? {
            switch self {
            case .status(let status):
                if status == errSecInteractionNotAllowed
                    || status == errSecAuthFailed
                    || status == errSecUserCanceled
                {
                    return "AppAtlas konnte die Lizenzdaten nicht aus dem "
                        + "macOS-Schlüsselbund lesen. Öffne den "
                        + "Schlüsselbund und erlaube AppAtlas den Zugriff "
                        + "auf „AppAtlas-Lizenz“, oder exportiere den "
                        + "Katalog ohne Lizenzdaten."
                }
                return SecCopyErrorMessageString(status, nil) as String?
                    ?? "Schlüsselbundfehler \(status)"
            }
        }
    }
}
