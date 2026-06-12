import Foundation

struct AppLicenseRecord: Codable, Equatable, Sendable {
    var serialNumber = ""
    var registeredEmail = ""
    var licenseType = ""
    var notes = ""

    var isEmpty: Bool {
        [serialNumber, registeredEmail, licenseType, notes].allSatisfy {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    func mergingMissingValues(from imported: AppLicenseRecord) -> AppLicenseRecord {
        AppLicenseRecord(
            serialNumber: serialNumber.isEmpty
                ? imported.serialNumber
                : serialNumber,
            registeredEmail: registeredEmail.isEmpty
                ? imported.registeredEmail
                : registeredEmail,
            licenseType: licenseType.isEmpty
                ? imported.licenseType
                : licenseType,
            notes: notes.isEmpty ? imported.notes : notes
        )
    }
}
