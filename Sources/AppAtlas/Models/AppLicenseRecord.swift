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
}
