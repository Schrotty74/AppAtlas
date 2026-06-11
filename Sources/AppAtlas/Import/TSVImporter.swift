import Foundation

enum TSVImportError: LocalizedError {
    case unreadableData
    case missingHeader
    case invalidHeader([String])
    case malformedRow(line: Int, fields: Int)

    var errorDescription: String? {
        switch self {
        case .unreadableData:
            "Die TSV-Datei ist nicht als UTF-8 lesbar."
        case .missingHeader:
            "Die TSV-Datei enthält keine Kopfzeile."
        case .invalidHeader(let fields):
            "Unerwartete TSV-Spalten: \(fields.joined(separator: ", "))."
        case .malformedRow(let line, let fields):
            "Zeile \(line) enthält \(fields) statt 7 Feldern."
        }
    }
}

struct TSVImporter: Sendable {
    static let expectedHeader = [
        "Name",
        "Typ",
        "Hauptkategorie",
        "Unterkategorie",
        "Relativer Pfad",
        "Groesse Bytes",
        "Geaendert"
    ]

    func importFiles(from data: Data) throws -> [LocalAppFile] {
        guard var text = String(data: data, encoding: .utf8) else {
            throw TSVImportError.unreadableData
        }

        if text.hasPrefix("\u{feff}") {
            text.removeFirst()
        }

        let lines = text.split(whereSeparator: \.isNewline)
        guard let headerLine = lines.first else {
            throw TSVImportError.missingHeader
        }

        let header = headerLine.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard header == Self.expectedHeader else {
            throw TSVImportError.invalidHeader(header)
        }

        return try lines.dropFirst().enumerated().map { offset, line in
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == Self.expectedHeader.count else {
                throw TSVImportError.malformedRow(line: offset + 2, fields: fields.count)
            }

            return LocalAppFile(
                fileName: fields[0],
                fileType: fields[1].lowercased(),
                sourceCategory: fields[2],
                sourceSubcategory: fields[3],
                relativePath: fields[4],
                sizeInBytes: Int64(fields[5]) ?? 0,
                modifiedAt: Self.parseDate(fields[6]),
                detectedVersion: AppNameNormalizer.detectVersion(in: fields[0])
            )
        }
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Europe/Vienna")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: value)
    }
}
