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
        static let releasesURL = URL(
            string: "https://api.github.com/repos/Schrotty74/AppAtlas/releases?per_page=20"
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
        var request = URLRequest(url: Constants.releasesURL)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw AppUpdateError.unexpectedResponse
        }
        let releases = try JSONDecoder().decode([GitHubRelease].self, from: data)
        guard let latestRelease = releases
            .filter({ !$0.draft })
            .max(by: { lhs, rhs in
                Self.compareVersions(lhs.tagName, rhs.tagName) == .orderedAscending
            }) else {
            throw AppUpdateError.unexpectedResponse
        }
        return latestRelease
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
        compareVersions(candidate, current) == .orderedDescending
    }

    private nonisolated static func compareVersions(
        _ lhs: String,
        _ rhs: String
    ) -> ComparisonResult {
        let lhsVersion = ParsedVersion(lhs)
        let rhsVersion = ParsedVersion(rhs)
        let count = max(lhsVersion.baseParts.count, rhsVersion.baseParts.count)
        for index in 0..<count {
            let lhsPart = index < lhsVersion.baseParts.count
                ? lhsVersion.baseParts[index]
                : 0
            let rhsPart = index < rhsVersion.baseParts.count
                ? rhsVersion.baseParts[index]
                : 0
            if lhsPart != rhsPart {
                return lhsPart > rhsPart ? .orderedDescending : .orderedAscending
            }
        }

        if lhsVersion.isPrerelease != rhsVersion.isPrerelease {
            return lhsVersion.isPrerelease ? .orderedAscending : .orderedDescending
        }

        let prereleaseCount = max(
            lhsVersion.prereleaseParts.count,
            rhsVersion.prereleaseParts.count
        )
        for index in 0..<prereleaseCount {
            let lhsPart = index < lhsVersion.prereleaseParts.count
                ? lhsVersion.prereleaseParts[index]
                : 0
            let rhsPart = index < rhsVersion.prereleaseParts.count
                ? rhsVersion.prereleaseParts[index]
                : 0
            if lhsPart != rhsPart {
                return lhsPart > rhsPart ? .orderedDescending : .orderedAscending
            }
        }

        return .orderedSame
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
    let draft: Bool

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case draft
    }
}

private struct ParsedVersion {
    let baseParts: [Int]
    let prereleaseParts: [Int]
    let isPrerelease: Bool

    init(_ version: String) {
        let normalized = version.trimmingCharacters(
            in: CharacterSet(charactersIn: "vV")
        )
        let pieces = normalized.split(separator: "-", maxSplits: 1)
        baseParts = pieces
            .first?
            .split { !$0.isNumber }
            .compactMap { Int($0) } ?? []
        if pieces.count > 1 {
            isPrerelease = true
            prereleaseParts = pieces[1]
                .split { !$0.isNumber }
                .compactMap { Int($0) }
        } else {
            isPrerelease = false
            prereleaseParts = []
        }
    }
}

private enum AppUpdateError: LocalizedError {
    case unexpectedResponse

    var errorDescription: String? {
        "Die Update-Information konnte nicht gelesen werden."
    }
}
