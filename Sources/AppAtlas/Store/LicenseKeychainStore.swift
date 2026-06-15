import Foundation
import Security

extension Notification.Name {
    static let appAtlasLicenseDataDidChange = Notification.Name(
        "AppAtlasLicenseDataDidChange"
    )
}

protocol LicenseStorage: Sendable {
    func load(for appID: UUID) -> AppLicenseRecord?
    func save(_ record: AppLicenseRecord, for appID: UUID) throws
    func delete(for appID: UUID)
}

extension LicenseStorage {
    func save(_ records: [UUID: AppLicenseRecord]) throws {
        for (appID, record) in records {
            try save(record, for: appID)
        }
    }
}

struct LicenseKeychainStore: LicenseStorage, Sendable {
    static let shared = LicenseKeychainStore()
    private let service = "at.schrotty.appatlas.licenses"

    func load(for appID: UUID) -> AppLicenseRecord? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: appID.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(
            query as CFDictionary,
            &result
        ) == errSecSuccess,
        let data = result as? Data
        else {
            return nil
        }
        return try? JSONDecoder().decode(AppLicenseRecord.self, from: data)
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
    }

    func delete(for appID: UUID) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: appID.uuidString
        ]
        SecItemDelete(query as CFDictionary)
    }

    enum KeychainError: LocalizedError {
        case status(OSStatus)

        var errorDescription: String? {
            switch self {
            case .status(let status):
                return SecCopyErrorMessageString(status, nil) as String?
                    ?? "Schlüsselbundfehler \(status)"
            }
        }
    }
}
