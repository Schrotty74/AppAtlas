import Foundation

struct LocalAppMetadata: Sendable {
    let bundleIdentifier: String?
    let developer: String?
}

struct LocalAppMetadataExtractor: Sendable {
    func metadata(for appURL: URL) -> LocalAppMetadata {
        guard appURL.pathExtension.lowercased() == "app" else {
            return LocalAppMetadata(
                bundleIdentifier: nil,
                developer: nil
            )
        }
        let infoURL = appURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Info.plist")
        guard let info = NSDictionary(contentsOf: infoURL)
            as? [String: Any]
        else {
            return LocalAppMetadata(
                bundleIdentifier: nil,
                developer: nil
            )
        }
        return LocalAppMetadata(
            bundleIdentifier: info["CFBundleIdentifier"] as? String,
            developer: developer(from: info)
        )
    }

    private func developer(from info: [String: Any]) -> String? {
        for key in ["NSHumanReadableCopyright", "CFBundleGetInfoString"] {
            guard let value = info[key] as? String else {
                continue
            }
            let cleaned = value
                .replacingOccurrences(
                    of: #"(?i)copyright|©|\(c\)|\d{4}(?:-\d{4})?|all rights reserved\.?"#,
                    with: " ",
                    options: .regularExpression
                )
                .replacingOccurrences(
                    of: #"\s+"#,
                    with: " ",
                    options: .regularExpression
                )
                .trimmingCharacters(
                    in: CharacterSet.whitespacesAndNewlines.union(
                        CharacterSet(charactersIn: ".,")
                    )
                )
            if !cleaned.isEmpty {
                return cleaned
            }
        }
        return nil
    }
}
