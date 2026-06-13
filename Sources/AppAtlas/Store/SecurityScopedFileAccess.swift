import Foundation

enum SecurityScopedFileAccess {
    static func readData(from url: URL) throws -> Data {
        try withAccess(to: url) {
            try Data(contentsOf: url)
        }
    }

    static func write(_ data: Data, to url: URL) throws {
        try withAccess(to: url) {
            try data.write(to: url, options: .atomic)
        }
    }

    static func write(_ text: String, to url: URL) throws {
        try withAccess(to: url) {
            try text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    static func withAccess<T>(
        to url: URL,
        operation: () throws -> T
    ) rethrows -> T {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try operation()
    }
}
