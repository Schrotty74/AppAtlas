import Foundation

struct FastOnlineResult: Sendable {
    let appID: AppEntry.ID
    let apple: AppleArtworkLookup.Metadata?
    let appleIconData: Data?
    let website: WebMetadataLookup.Metadata?
}

struct SlowOnlineResult: Sendable {
    let appID: AppEntry.ID
    let homepage: OfficialWebsiteLookup.Result?
    let website: WebMetadataLookup.Metadata?
    let github: GitHubRepositoryLookup.Metadata?
    let reddit: RedditDescriptionLookup.Result?
}

enum OnlineEnrichmentLookup {
    static func fastResult(for app: AppEntry) async -> FastOnlineResult {
        await withTimeout(seconds: 8) {
            let needsIcon = !hasValidIcon(app)
            async let apple = AppleArtworkLookup.shared.metadata(for: app)
            async let website: WebMetadataLookup.Metadata? = {
                guard let metadataURL = metadataSourceURL(for: app),
                      needsIcon
                        || AppMetadataEnricher.needsDescriptionExpansion(
                            app.details
                        )
                else {
                    return nil
                }
                return await WebMetadataLookup.shared.metadata(
                    for: metadataURL,
                    needsIcon: needsIcon
                )
            }()
            let appleMetadata = await apple
            let appleIconData: Data?
            if needsIcon,
               let artworkURL = appleMetadata?.artworkURL
            {
                appleIconData = await OnlineIconLoader.shared.iconData(
                    from: artworkURL
                )
            } else {
                appleIconData = nil
            }
            return FastOnlineResult(
                appID: app.id,
                apple: appleMetadata,
                appleIconData: appleIconData,
                website: await website
            )
        } ?? FastOnlineResult(
            appID: app.id,
            apple: nil,
            appleIconData: nil,
            website: nil
        )
    }

    static func fastResults(for apps: [AppEntry]) async -> [FastOnlineResult] {
        await withTaskGroup(of: FastOnlineResult.self) { group in
            for app in apps {
                group.addTask {
                    await fastResult(for: app)
                }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }
    }

    static func slowResult(for app: AppEntry) async -> SlowOnlineResult {
        await withTimeout(seconds: 12) {
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
                guard AppMetadataEnricher.needsDescriptionExpansion(
                    app.details
                ), !app.customizations.description else {
                    return nil
                }
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
               !app.hasIcon
                || AppMetadataEnricher.needsDescriptionExpansion(app.details)
            {
                website = await WebMetadataLookup.shared.metadata(
                    for: metadataURL,
                    needsIcon: !app.hasIcon
                )
            } else {
                website = nil
            }
            return await SlowOnlineResult(
                appID: app.id,
                homepage: homepage,
                website: website,
                github: github,
                reddit: reddit
            )
        } ?? SlowOnlineResult(
            appID: app.id,
            homepage: nil,
            website: nil,
            github: nil,
            reddit: nil
        )
    }

    private static func metadataSourceURL(for app: AppEntry) -> URL? {
        app.homepage ?? app.downloadURL
    }

    private static func shouldDiscoverHomepage(for app: AppEntry) -> Bool {
        app.homepage == nil && !app.customizations.links
    }

    private static func hasValidIcon(_ app: AppEntry) -> Bool {
        if let iconData = app.iconData {
            return IconQualityInspector.isLikelyAppIcon(iconData)
        }
        guard let fileName = app.iconFileName,
              let data = IconStore.shared.data(fileName: fileName, thumbnail: false)
        else {
            return false
        }
        return IconQualityInspector.isLikelyAppIcon(data)
    }

    static func slowResults(for apps: [AppEntry]) async -> [SlowOnlineResult] {
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
        for app: AppEntry
    ) async -> GitHubRepositoryLookup.Metadata? {
        let needsIcon = !app.customizations.icon
            && app.iconOrigin != .manual
            && (!app.hasIcon || app.iconOrigin == .iTunes)
        if let sourceURL = app.githubURL,
           let metadata = await GitHubRepositoryLookup.shared.metadata(
                for: sourceURL,
                category: app.category,
                subcategory: app.subcategory,
                needsIcon: needsIcon
           )
        {
            return metadata
        }
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
