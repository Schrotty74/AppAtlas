import Foundation

enum BackupReminderInterval: Int, CaseIterable, Identifiable, Sendable {
    case never = 0
    case sevenDays = 7
    case thirtyDays = 30
    case ninetyDays = 90

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .never:
            "Nie"
        case .sevenDays:
            "Alle 7 Tage"
        case .thirtyDays:
            "Alle 30 Tage"
        case .ninetyDays:
            "Alle 90 Tage"
        }
    }

    var days: Int? {
        rawValue == 0 ? nil : rawValue
    }
}

enum BackupReminderService {
    static let lastExportDateKey = "backupReminderLastExportDate"
    static let intervalKey = "backupReminderIntervalDays"
    static let defaultInterval = BackupReminderInterval.thirtyDays

    static var currentInterval: BackupReminderInterval {
        guard UserDefaults.standard.object(forKey: intervalKey) != nil else {
            return defaultInterval
        }
        return BackupReminderInterval(
            rawValue: UserDefaults.standard.integer(forKey: intervalKey)
        ) ?? defaultInterval
    }

    static var lastExportDate: Date? {
        let timestamp = UserDefaults.standard.double(forKey: lastExportDateKey)
        guard timestamp > 0 else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }

    static func recordExport(date: Date = Date()) {
        UserDefaults.standard.set(
            date.timeIntervalSince1970,
            forKey: lastExportDateKey
        )
    }

    static func isReminderDue(now: Date = Date()) -> Bool {
        guard let days = currentInterval.days else {
            return false
        }
        guard let lastExportDate else {
            return true
        }
        let interval = TimeInterval(days * 24 * 60 * 60)
        return now.timeIntervalSince(lastExportDate) >= interval
    }
}
