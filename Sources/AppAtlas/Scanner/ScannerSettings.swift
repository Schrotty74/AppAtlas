import Foundation

enum ScannerSettings {
    static let excludedDirectoriesKey = "scannerExcludedDirectories"
    static let excludedFolderBookmarksKey = "scannerExcludedFolderBookmarks"
    static let excludedFileExtensionsKey = "scannerExcludedFileExtensions"

    private struct ExcludedFolderBookmark: Codable {
        let bookmarkData: Data
        let displayPath: String
    }

    static var excludedDirectories: [String] {
        parse(
            UserDefaults.standard.string(
                forKey: excludedDirectoriesKey
            ) ?? ""
        )
    }

    static var excludedFileExtensions: [String] {
        parseFileExtensions(
            UserDefaults.standard.string(
                forKey: excludedFileExtensionsKey
            ) ?? ""
        )
    }

    static var excludedFolderURLs: [URL] {
        loadExcludedFolderBookmarks().compactMap { record in
            var isStale = false
            guard let url = try? URL(
                resolvingBookmarkData: record.bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) else {
                return nil
            }
            return url
        }
    }

    static var excludedFolderDisplayPaths: [String] {
        loadExcludedFolderBookmarks()
            .map(\.displayPath)
            .sorted {
                $0.localizedStandardCompare($1) == .orderedAscending
            }
    }

    static func addExcludedFolder(_ url: URL) throws {
        let standardizedURL = url.standardizedFileURL
        let bookmarkData = try standardizedURL.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        var records = loadExcludedFolderBookmarks()
        records.removeAll {
            $0.displayPath == standardizedURL.path
        }
        records.append(
            ExcludedFolderBookmark(
                bookmarkData: bookmarkData,
                displayPath: standardizedURL.path
            )
        )
        saveExcludedFolderBookmarks(records)
    }

    static func removeExcludedFolder(displayPath: String) {
        saveExcludedFolderBookmarks(
            loadExcludedFolderBookmarks().filter {
                $0.displayPath != displayPath
            }
        )
    }

    static func parse(_ rawValue: String) -> [String] {
        Array(
            Set(
                rawValue
                    .components(separatedBy: .newlines)
                    .map {
                        $0.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    static func encode(_ values: [String]) -> String {
        parse(values.joined(separator: "\n"))
            .joined(separator: "\n")
    }

    static func parseFileExtensions(_ rawValue: String) -> [String] {
        let lines = rawValue.components(separatedBy: .newlines)
        let normalized = lines.compactMap { line -> String? in
            var value = line.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            if value.hasPrefix(".") {
                value.removeFirst()
            }
            value = value.lowercased()
            guard !value.isEmpty,
                  value.allSatisfy({ character in
                      character.isLetter || character.isNumber
                  })
            else {
                return nil
            }
            return value
        }
        return Array(Set(normalized)).sorted()
    }

    static func encodeFileExtensions(_ values: [String]) -> String {
        parseFileExtensions(values.joined(separator: "\n"))
            .joined(separator: "\n")
    }

    private static func loadExcludedFolderBookmarks() -> [ExcludedFolderBookmark] {
        guard let data = UserDefaults.standard.data(
            forKey: excludedFolderBookmarksKey
        ) else {
            return []
        }
        return (try? JSONDecoder().decode(
            [ExcludedFolderBookmark].self,
            from: data
        )) ?? []
    }

    private static func saveExcludedFolderBookmarks(
        _ records: [ExcludedFolderBookmark]
    ) {
        guard let data = try? JSONEncoder().encode(records) else {
            return
        }
        UserDefaults.standard.set(data, forKey: excludedFolderBookmarksKey)
    }
}
