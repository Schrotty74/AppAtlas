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

final class CountingLicenseStorage: LicenseStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var records: [UUID: AppLicenseRecord] = [:]
    private(set) var exportReads: [UUID] = []

    func load(for appID: UUID) -> AppLicenseRecord? {
        lock.withLock {
            records[appID]
        }
    }

    func loadForExport(for appID: UUID) throws -> AppLicenseRecord? {
        lock.withLock {
            exportReads.append(appID)
            return records[appID]
        }
    }

    func hasRecord(for appID: UUID) -> Bool {
        lock.withLock {
            records[appID]?.isEmpty == false
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
