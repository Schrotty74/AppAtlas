import Foundation

public struct FastOnlineResult: Sendable {
    public let appID: String
    public let apple: AppleArtworkLookup.Metadata?
    public let appleIconData: Data?
    public let website: WebMetadataLookup.Metadata?
}

public struct SlowOnlineResult: Sendable {
    public let appID: String
    public let homepage: OfficialWebsiteLookup.Result?
    public let website: WebMetadataLookup.Metadata?
    public let github: GitHubRepositoryLookup.Metadata?
    public let reddit: RedditDescriptionLookup.Result?
}

public enum OnlineEnrichmentLookup {
    public static func fastResult(
        for app: any EnrichableApp
    ) async -> FastOnlineResult {
        return await withTimeout(seconds: 30) {
            async let apple = AppleArtworkLookup.shared.metadata(for: app)
            async let website: WebMetadataLookup.Metadata? = {
                guard let metadataURL = metadataSourceURL(for: app) else {
                    return nil
                }
                return await WebMetadataLookup.shared.metadata(
                    for: metadataURL,
                    needsIcon: true
                )
            }()
            let appleMetadata = await apple
            let appleIconData: Data?
            if let artworkURL = appleMetadata?.artworkURL
            {
                appleIconData = await OnlineIconLoader.shared.iconData(
                    from: artworkURL
                )
            } else {
                appleIconData = nil
            }
            return FastOnlineResult(
                appID: app.name,
                apple: appleMetadata,
                appleIconData: appleIconData,
                website: await website
            )
        } ?? FastOnlineResult(
            appID: app.name,
            apple: nil,
            appleIconData: nil,
            website: nil
        )
    }

    public static func fastResults(
        for apps: [any EnrichableApp]
    ) async -> [FastOnlineResult] {
        await withTaskGroup(of: FastOnlineResult.self) { group in
            for app in apps {
                group.addTask {
                    await fastResult(for: app)
                }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }
    }

    public static func slowResult(
        for app: any EnrichableApp
    ) async -> SlowOnlineResult {
        await withTimeout(seconds: 30) {
            async let homepageLookup: OfficialWebsiteLookup.Result? = {
                guard shouldDiscoverHomepage(for: app) else {
                    return nil
                }
                return await OfficialWebsiteLookup.shared.homepage(for: app)
            }()
            async let github: GitHubRepositoryLookup.Metadata? = {
                guard app.homepage == nil else {
                    return nil
                }
                return await githubMetadata(for: app)
            }()
            async let reddit: RedditDescriptionLookup.Result? = {
                return await RedditDescriptionLookup.shared.description(for: app)
            }()
            let homepage = await homepageLookup
            let website: WebMetadataLookup.Metadata?
            let metadataURL: URL? = if let homepage,
               homepage.match.decision == .automatic {
                homepage.url
            } else {
                metadataSourceURL(for: app)
            }
            if let metadataURL,
               true
            {
                website = await WebMetadataLookup.shared.metadata(
                    for: metadataURL,
                    needsIcon: true
                )
            } else {
                website = nil
            }
            return await SlowOnlineResult(
                appID: app.name,
                homepage: homepage,
                website: website,
                github: github,
                reddit: reddit
            )
        } ?? SlowOnlineResult(
            appID: app.name,
            homepage: nil,
            website: nil,
            github: nil,
            reddit: nil
        )
    }

    private static func metadataSourceURL(for app: any EnrichableApp) -> URL? {
        app.homepage
    }

    private static func shouldDiscoverHomepage(
        for app: any EnrichableApp
    ) -> Bool {
        app.homepage == nil
    }

    public static func slowResults(
        for apps: [any EnrichableApp]
    ) async -> [SlowOnlineResult] {
        await withTaskGroup(of: SlowOnlineResult.self) { group in
            for app in apps {
                group.addTask {
                    await slowResult(for: app)
                }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }
    }

    private static func githubMetadata(
        for app: any EnrichableApp
    ) async -> GitHubRepositoryLookup.Metadata? {
        let needsIcon = true
        return await GitHubRepositoryLookup.shared.metadata(
            for: app,
            needsIcon: needsIcon
        )
    }

    private static func withTimeout<T: Sendable>(
        seconds: UInt64,
        operation: @escaping @Sendable () async -> T
    ) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }
}
