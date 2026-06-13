import Foundation

struct ScanResult: Sendable {
    let rootURL: URL
    let files: [LocalAppFile]
    let apps: [AppEntry]
}

enum VolumeScannerError: LocalizedError {
    case unreadableFolder

    var errorDescription: String? {
        switch self {
        case .unreadableFolder:
            "Der ausgewählte Ordner konnte nicht gelesen werden."
        }
    }
}

struct VolumeScanner: Sendable {
    private let supportedExtensions = Set(["app", "dmg", "pkg", "zip", "iso", "apk", "exe"])
    private let exclusionPolicy: ScanExclusionPolicy
    private let excludedFileExtensions: Set<String>

    init(
        excludedDirectories: [String] = ScannerSettings.excludedDirectories,
        excludedDirectoryURLs: [URL] = ScannerSettings.excludedFolderURLs,
        excludedFileExtensions: [String] = ScannerSettings.excludedFileExtensions
    ) {
        exclusionPolicy = ScanExclusionPolicy(
            customExcludedDirectories: excludedDirectories,
            excludedDirectoryURLs: excludedDirectoryURLs
        )
        self.excludedFileExtensions = Set(
            ScannerSettings.parseFileExtensions(
                excludedFileExtensions.joined(separator: "\n")
            )
        )
    }

    func scan(_ rootURL: URL) throws -> ScanResult {
        let keys: [URLResourceKey] = [
            .isDirectoryKey,
            .fileSizeKey,
            .contentModificationDateKey
        ]
        let rootPaths = rootPathAliases(for: rootURL)
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw VolumeScannerError.unreadableFolder
        }

        var files: [LocalAppFile] = []
        while let url = enumerator.nextObject() as? URL {
            let relativePath = relativePath(for: url, rootPaths: rootPaths)
            let pathComponents = relativePath.split(separator: "/").map(String.init)

            if exclusionPolicy.shouldExclude(
                url: url,
                relativePathComponents: pathComponents
            ) {
                if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                    enumerator.skipDescendants()
                }
                continue
            }

            let fileExtension = url.pathExtension.lowercased()
            guard supportedExtensions.contains(fileExtension) else {
                continue
            }
            if excludedFileExtensions.contains(fileExtension) {
                if fileExtension == "app" {
                    enumerator.skipDescendants()
                }
                continue
            }

            let resourceValues = try? url.resourceValues(
                forKeys: Set(keys)
            )
            if fileExtension == "app" {
                enumerator.skipDescendants()
            }

            let category = pathComponents.first ?? "Sonstiges"
            let subcategory = pathComponents
                .dropFirst()
                .dropLast()
                .joined(separator: "/")

            files.append(
                LocalAppFile(
                    fileName: url.lastPathComponent,
                    fileType: fileExtension,
                    sourceCategory: category,
                    sourceSubcategory: subcategory,
                    relativePath: relativePath,
                    sizeInBytes: Int64(resourceValues?.fileSize ?? 0),
                    modifiedAt: resourceValues?.contentModificationDate,
                    detectedVersion: AppNameNormalizer.detectVersion(
                        in: url.lastPathComponent
                    ),
                    iconData: fileExtension == "app"
                        ? LocalAppIconExtractor().iconData(for: url)
                        : nil
                )
            )
        }

        return ScanResult(
            rootURL: rootURL,
            files: files,
            apps: AppCatalogBuilder().buildEntries(from: files)
        )
    }

    private func relativePath(for url: URL, rootPaths: [String]) -> String {
        let path = url.path
        for rootPath in rootPaths where path.hasPrefix(rootPath) {
            return String(path.dropFirst(rootPath.count))
                .trimmingCharacters(
                    in: CharacterSet(charactersIn: "/")
                )
        }
        return url.lastPathComponent
    }

    private func rootPathAliases(for rootURL: URL) -> [String] {
        let rootPath = rootURL.path
        if rootPath == "/var" || rootPath.hasPrefix("/var/") {
            return [rootPath, "/private\(rootPath)"]
        }
        return [rootPath]
    }
}

struct ScanExclusionPolicy: Sendable {
    private let builtInExcludedDirectoryNames = Set([
        "__macosx",
        "cfg",
        "crack - readme",
        "plugins"
    ])
    private let customExcludedDirectoryNames: Set<String>
    private let customExcludedPaths: Set<String>
    private let excludedAbsolutePaths: Set<String>

    init(
        customExcludedDirectories: [String] = [],
        excludedDirectoryURLs: [URL] = []
    ) {
        let normalized = customExcludedDirectories
            .map(Self.normalizePath)
            .filter { !$0.isEmpty }
        customExcludedDirectoryNames = Set(
            normalized.filter { !$0.contains("/") }
        )
        customExcludedPaths = Set(
            normalized.filter { $0.contains("/") }
        )
        excludedAbsolutePaths = Set(
            excludedDirectoryURLs.map {
                $0.standardizedFileURL.path
            }
        )
    }

    func shouldExclude(url: URL, relativePathComponents: [String]) -> Bool {
        let absolutePath = url.standardizedFileURL.path
        if excludedAbsolutePaths.contains(where: {
            absolutePath == $0 || absolutePath.hasPrefix($0 + "/")
        }) {
            return true
        }

        let normalizedComponents = relativePathComponents.map(Self.normalize)
        guard let firstComponent = normalizedComponents.first else {
            return false
        }

        if url.hasDirectoryPath,
           normalizedComponents.count >= 2,
           firstComponent == "backup",
           normalizedComponents[1].contains("backup") {
            return true
        }

        if normalizedComponents.contains(
            where: builtInExcludedDirectoryNames.contains
        ) {
            return true
        }

        if normalizedComponents.contains(
            where: customExcludedDirectoryNames.contains
        ) {
            return true
        }

        let normalizedPath = normalizedComponents.joined(separator: "/")
        if customExcludedPaths.contains(where: {
            normalizedPath == $0 || normalizedPath.hasPrefix($0 + "/")
        }) {
            return true
        }

        return isBackupArchive(url)
    }

    private func isBackupArchive(_ url: URL) -> Bool {
        guard url.pathExtension.lowercased() == "zip" else {
            return false
        }

        let name = Self.normalize(
            url.deletingPathExtension().lastPathComponent
        )
        let words = Set(name.split(whereSeparator: \.isWhitespace).map(String.init))
        return words.contains("backup")
            || words.contains("sicherung")
            || name.contains("profilebackup")
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func normalizePath(_ value: String) -> String {
        value
            .split(separator: "/")
            .map { normalize(String($0)) }
            .filter { !$0.isEmpty }
            .joined(separator: "/")
    }
}
