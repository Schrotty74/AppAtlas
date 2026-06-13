import Foundation

struct ThemeTransferService: Sendable {
    func importTheme(from url: URL) throws -> AppAtlasThemeDefinition {
        try ThemeDocumentDecoder.decode(
            SecurityScopedFileAccess.readData(from: url)
        )
    }

    func exportText(for theme: AppAtlasThemeDefinition) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(theme)
        guard var text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        text += "\n"
        return text
    }
}
