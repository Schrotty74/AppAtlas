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
    private let exclusionPolicy = ScanExclusionPolicy()

    func scan(_ rootURL: URL) throws -> ScanResult {
        let keys: [URLResourceKey] = [.isDirectoryKey]
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
                    sizeInBytes: 0,
                    modifiedAt: nil,
                    detectedVersion: AppNameNormalizer.detectVersion(
                        in: url.lastPathComponent
                    )
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
    private let excludedDirectoryNames = Set([
        "__macosx",
        "cfg",
        "crack - readme",
        "plugins"
    ])

    func shouldExclude(url: URL, relativePathComponents: [String]) -> Bool {
        let normalizedComponents = relativePathComponents.map(normalize)
        guard let firstComponent = normalizedComponents.first else {
            return false
        }

        if url.hasDirectoryPath,
           normalizedComponents.count >= 2,
           firstComponent == "backup",
           normalizedComponents[1].contains("backup") {
            return true
        }

        if normalizedComponents.contains(where: excludedDirectoryNames.contains) {
            return true
        }

        return isBackupArchive(url)
    }

    private func isBackupArchive(_ url: URL) -> Bool {
        guard url.pathExtension.lowercased() == "zip" else {
            return false
        }

        let name = normalize(url.deletingPathExtension().lastPathComponent)
        let words = Set(name.split(whereSeparator: \.isWhitespace).map(String.init))
        return words.contains("backup")
            || words.contains("sicherung")
            || name.contains("profilebackup")
    }

    private func normalize(_ value: String) -> String {
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
}
