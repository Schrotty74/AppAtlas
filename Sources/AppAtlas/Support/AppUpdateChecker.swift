import AppKit
import Foundation

enum AppUpdateStatus: Equatable, Sendable {
    case idle
    case checking
    case upToDate(Date)
    case updateAvailable(AppUpdateInfo)
    case failed(String)
}

struct AppUpdateInfo: Codable, Equatable, Sendable {
    let latestVersion: String
    let releaseURL: URL
    let checkedAt: Date
}

@MainActor
final class AppUpdateChecker: ObservableObject {
    private enum Constants {
        static let cacheKey = "appUpdateChecker.cachedResult"
        static let automaticDelay: UInt64 = 2_000_000_000
        static let cacheLifetime: TimeInterval = 24 * 60 * 60
        static let releaseURL = URL(
            string: "https://api.github.com/repos/Schrotty74/AppAtlas/releases/latest"
        )!
    }

    @Published private(set) var status: AppUpdateStatus = .idle

    private var didRunAutomaticCheck = false
    private let session: URLSession
    private let defaults: UserDefaults

    init(
        session: URLSession = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.session = session
        self.defaults = defaults
        if let cachedInfo = Self.cachedInfo(defaults: defaults),
           Self.isNewerVersion(
                cachedInfo.latestVersion,
                than: Self.currentVersion
           ) {
            status = .updateAvailable(cachedInfo)
        }
    }

    func checkAutomaticallyAfterLaunch() async {
        guard !didRunAutomaticCheck else {
            return
        }
        didRunAutomaticCheck = true

        try? await Task.sleep(nanoseconds: Constants.automaticDelay)
        guard shouldRunAutomaticCheck else {
            return
        }

        do {
            _ = try await performCheck()
        } catch {
            // Automatic checks should never interrupt the user.
        }
    }

    func checkManually() async {
        status = .checking
        do {
            let result = try await performCheck()
            switch result {
            case .updateAvailable(let info):
                status = .updateAvailable(info)
            case .upToDate:
                status = .upToDate(Date())
            }
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func openReleasePage() {
        guard case .updateAvailable(let info) = status else {
            return
        }
        NSWorkspace.shared.open(info.releaseURL)
    }

    private var shouldRunAutomaticCheck: Bool {
        guard let cachedInfo = Self.cachedInfo(defaults: defaults) else {
            return true
        }
        return Date().timeIntervalSince(cachedInfo.checkedAt)
            >= Constants.cacheLifetime
    }

    private func performCheck() async throws -> CheckResult {
        let release = try await fetchLatestRelease()
        let checkedAt = Date()
        let info = AppUpdateInfo(
            latestVersion: release.tagName,
            releaseURL: release.htmlURL,
            checkedAt: checkedAt
        )
        Self.save(info, defaults: defaults)

        if Self.isNewerVersion(release.tagName, than: Self.currentVersion) {
            status = .updateAvailable(info)
            return .updateAvailable(info)
        }

        status = .upToDate(checkedAt)
        return .upToDate
    }

    private func fetchLatestRelease() async throws -> GitHubRelease {
        var request = URLRequest(url: Constants.releaseURL)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw AppUpdateError.unexpectedResponse
        }
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    nonisolated static var currentVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "0"
    }

    nonisolated static var userAgent: String {
        "AppAtlas/\(currentVersion)"
    }

    nonisolated static func isNewerVersion(
        _ candidate: String,
        than current: String
    ) -> Bool {
        let candidateParts = versionParts(candidate)
        let currentParts = versionParts(current)
        let count = max(candidateParts.count, currentParts.count)
        for index in 0..<count {
            let candidatePart = index < candidateParts.count ? candidateParts[index] : 0
            let currentPart = index < currentParts.count ? currentParts[index] : 0
            if candidatePart != currentPart {
                return candidatePart > currentPart
            }
        }
        return false
    }

    private nonisolated static func versionParts(_ version: String) -> [Int] {
        version
            .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            .split { !$0.isNumber }
            .compactMap { Int($0) }
    }

    private static func cachedInfo(defaults: UserDefaults) -> AppUpdateInfo? {
        guard let data = defaults.data(forKey: Constants.cacheKey) else {
            return nil
        }
        return try? JSONDecoder().decode(AppUpdateInfo.self, from: data)
    }

    private static func save(_ info: AppUpdateInfo, defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(info) else {
            return
        }
        defaults.set(data, forKey: Constants.cacheKey)
    }
}

private enum CheckResult {
    case upToDate
    case updateAvailable(AppUpdateInfo)
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

private enum AppUpdateError: LocalizedError {
    case unexpectedResponse

    var errorDescription: String? {
        "Die Update-Information konnte nicht gelesen werden."
    }
}
