import Foundation

struct FastOnlineResult: Sendable {
    let appID: AppEntry.ID
    let apple: AppleArtworkLookup.Metadata?
    let appleIconData: Data?
    let website: WebMetadataLookup.Metadata?
}

struct SlowOnlineResult: Sendable {
    let appID: AppEntry.ID
    let homepage: URL?
    let github: GitHubRepositoryLookup.Metadata?
    let reddit: RedditDescriptionLookup.Result?
}

enum OnlineEnrichmentLookup {
    static func fastResults(for apps: [AppEntry]) async -> [FastOnlineResult] {
        await withTaskGroup(of: FastOnlineResult.self) { group in
            for app in apps {
                group.addTask {
                    async let apple = AppleArtworkLookup.shared.metadata(
                        for: app.name,
                        category: app.category,
                        subcategory: app.subcategory
                    )
                    async let website: WebMetadataLookup.Metadata? = {
                        guard let homepage = app.homepage,
                              !app.hasIcon
                                || AppMetadataEnricher.needsDescriptionExpansion(
                                    app.details
                                )
                        else {
                            return nil
                        }
                        return await WebMetadataLookup.shared.metadata(
                            for: homepage,
                            needsIcon: !app.hasIcon
                        )
                    }()
                    let appleMetadata = await apple
                    let appleIconData: Data?
                    if !app.hasIcon,
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
                }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }
    }

    static func slowResults(for apps: [AppEntry]) async -> [SlowOnlineResult] {
        await withTaskGroup(of: SlowOnlineResult.self) { group in
            for app in apps {
                group.addTask {
                    async let homepage: URL? = {
                        guard app.homepage == nil else {
                            return nil
                        }
                        return await OfficialWebsiteLookup.shared.homepage(
                            for: app.name,
                            category: app.category,
                            subcategory: app.subcategory
                        )
                    }()
                    async let github = githubMetadata(for: app)
                    async let reddit: RedditDescriptionLookup.Result? = {
                        guard AppMetadataEnricher.needsDescriptionExpansion(
                            app.details
                        ), !app.customizations.description else {
                            return nil
                        }
                        return await RedditDescriptionLookup.shared.description(
                            for: app.name
                        )
                    }()
                    return await SlowOnlineResult(
                        appID: app.id,
                        homepage: homepage,
                        github: github,
                        reddit: reddit
                    )
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
        if let sourceURL = app.githubURL ?? app.homepage,
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
            forAppNamed: app.name,
            category: app.category,
            subcategory: app.subcategory,
            needsIcon: needsIcon
        )
    }
}
