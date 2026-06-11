import Foundation

actor URLRedirectResolver {
    static let shared = URLRedirectResolver()

    func finalURL(for url: URL) async -> URL {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 15
        request.setValue("AppAtlas/0.1", forHTTPHeaderField: "User-Agent")
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return response.url ?? url
        } catch {
            return url
        }
    }

    nonisolated static func equivalent(_ lhs: URL?, _ rhs: URL?) -> Bool {
        guard let lhs, let rhs else {
            return false
        }
        return canonical(lhs) == canonical(rhs)
    }

    private nonisolated static func canonical(_ url: URL) -> String {
        var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        )
        components?.scheme = nil
        components?.query = nil
        components?.fragment = nil
        var value = components?.string?.lowercased() ?? url.absoluteString
        while value.hasSuffix("/") {
            value.removeLast()
        }
        return value
    }
}
