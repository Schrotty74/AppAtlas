import Foundation

struct ImportedLicense: Sendable {
    let softwareName: String
    let record: AppLicenseRecord
}

struct LicenseImportMatch: Sendable {
    let appID: UUID
    let record: AppLicenseRecord
}

struct LicenseImportPlan: Sendable {
    let matches: [LicenseImportMatch]
    let unmatchedNames: [String]
    let ambiguousNames: [String]

    var summary: String {
        "\(matches.count) Lizenzdaten zugeordnet, \(unmatchedNames.count) ohne passenden Katalogeintrag, \(ambiguousNames.count) nicht eindeutig."
    }
}

enum LicenseDataImportError: LocalizedError {
    case unsupportedFormat
    case malformedData
    case noLicenses

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            "Das gewählte Lizenzformat wird nicht unterstützt."
        case .malformedData:
            "Die Lizenzdatei konnte nicht gelesen werden."
        case .noLicenses:
            "Die Datei enthält keine importierbaren Lizenzdaten."
        }
    }
}

struct LicenseDataImporter: Sendable {
    func decode(data: Data, fileExtension: String) throws -> [ImportedLicense] {
        let licenses: [ImportedLicense]
        switch fileExtension.lowercased() {
        case "json":
            licenses = try decodeJSON(data)
        case "csv":
            licenses = try decodeCSV(data)
        default:
            throw LicenseDataImportError.unsupportedFormat
        }
        guard !licenses.isEmpty else {
            throw LicenseDataImportError.noLicenses
        }
        return licenses
    }

    func plan(
        licenses: [ImportedLicense],
        apps: [AppEntry]
    ) -> LicenseImportPlan {
        var matches: [LicenseImportMatch] = []
        var unmatched: [String] = []
        var ambiguous: [String] = []

        for license in licenses where !license.record.isEmpty {
            let ranked = apps
                .map { ($0, AppNameMatcher.similarity(license.softwareName, $0.name)) }
                .sorted { $0.1 > $1.1 }
            guard let best = ranked.first else {
                unmatched.append(license.softwareName)
                continue
            }
            let secondScore = ranked.dropFirst().first?.1 ?? 0
            let exact = AppNameMatcher.normalized(license.softwareName)
                == AppNameMatcher.normalized(best.0.name)
            guard exact || (best.1 >= 0.9 && best.1 - secondScore >= 0.08) else {
                if best.1 >= 0.8 {
                    ambiguous.append(license.softwareName)
                } else {
                    unmatched.append(license.softwareName)
                }
                continue
            }
            matches.append(
                LicenseImportMatch(appID: best.0.id, record: license.record)
            )
        }
        return LicenseImportPlan(
            matches: matches,
            unmatchedNames: unmatched.sorted(),
            ambiguousNames: ambiguous.sorted()
        )
    }

    private func decodeJSON(_ data: Data) throws -> [ImportedLicense] {
        do {
            let export = try JSONDecoder().decode(LicenseManagerExport.self, from: data)
            return export.licenses.compactMap(\.importedLicense)
        } catch {
            throw LicenseDataImportError.malformedData
        }
    }

    private func decodeCSV(_ data: Data) throws -> [ImportedLicense] {
        guard let text = String(data: data, encoding: .utf8) else {
            throw LicenseDataImportError.malformedData
        }
        let rows = parseCSV(text)
        guard let marker = rows.firstIndex(where: {
            $0.first?.trimmingCharacters(in: .whitespacesAndNewlines)
                == "# LICENSES"
        }), rows.indices.contains(marker + 1)
        else {
            throw LicenseDataImportError.malformedData
        }
        let headers = rows[marker + 1]
        return rows.dropFirst(marker + 2).compactMap { row in
            guard !row.isEmpty, row.first != "" else {
                return nil
            }
            let values = Dictionary(
                uniqueKeysWithValues: zip(headers, row).map {
                    ($0.0, $0.1)
                }
            )
            return importedLicense(from: values)
        }
    }

    private func importedLicense(
        from values: [String: String]
    ) -> ImportedLicense? {
        let softwareName = values["softwareName"]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !softwareName.isEmpty else {
            return nil
        }
        let keys = (1...4).compactMap { index -> String? in
            let field = index == 1 ? "licenseKey" : "licenseKey\(index)"
            let value = values[field]?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return value.isEmpty ? nil : value
        }
        return ImportedLicense(
            softwareName: softwareName,
            record: AppLicenseRecord(
                serialNumber: keys.joined(separator: "\n"),
                registeredEmail: values["userEmail"] ?? "",
                licenseType: values["licenseType"] ?? "",
                notes: values["notes"] ?? ""
            )
        )
    }

    private func parseCSV(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var quoted = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            if character == "\"" {
                let next = text.index(after: index)
                if quoted, next < text.endIndex, text[next] == "\"" {
                    field.append("\"")
                    index = next
                } else {
                    quoted.toggle()
                }
            } else if character == ",", !quoted {
                row.append(field)
                field = ""
            } else if character == "\n", !quoted {
                row.append(field.trimmingCharacters(in: .newlines))
                rows.append(row)
                row = []
                field = ""
            } else {
                field.append(character)
            }
            index = text.index(after: index)
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field.trimmingCharacters(in: .newlines))
            rows.append(row)
        }
        return rows
    }
}

private struct LicenseManagerExport: Decodable {
    let licenses: [LicenseManagerRecord]
}

private struct LicenseManagerRecord: Decodable {
    let softwareName: String
    let licenseKey: String?
    let licenseKey2: String?
    let licenseKey3: String?
    let licenseKey4: String?
    let licenseType: String?
    let userEmail: String?
    let notes: String?

    var importedLicense: ImportedLicense? {
        let name = softwareName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return nil
        }
        let keys = [licenseKey, licenseKey2, licenseKey3, licenseKey4]
            .compactMap {
                let value = $0?.trimmingCharacters(in: .whitespacesAndNewlines)
                    ?? ""
                return value.isEmpty ? nil : value
            }
        return ImportedLicense(
            softwareName: name,
            record: AppLicenseRecord(
                serialNumber: keys.joined(separator: "\n"),
                registeredEmail: userEmail ?? "",
                licenseType: licenseType ?? "",
                notes: notes ?? ""
            )
        )
    }
}
