import Foundation
@testable import AppAtlas

final class InMemoryLicenseStorage: LicenseStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var records: [UUID: AppLicenseRecord] = [:]

    func load(for appID: UUID) -> AppLicenseRecord? {
        lock.withLock {
            records[appID]
        }
    }

    func save(_ record: AppLicenseRecord, for appID: UUID) throws {
        lock.withLock {
            if record.isEmpty {
                records.removeValue(forKey: appID)
            } else {
                records[appID] = record
            }
        }
    }

    func delete(for appID: UUID) {
        lock.withLock {
            _ = records.removeValue(forKey: appID)
        }
    }
}
