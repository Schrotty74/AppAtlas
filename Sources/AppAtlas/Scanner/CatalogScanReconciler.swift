import Foundation

struct CatalogScanReconcileResult: Sendable {
    let apps: [AppEntry]
    let matchedExistingIDs: Set<AppEntry.ID>
}

struct CatalogScanReconciler: Sendable {
    func reconcile(
        existingApps: [AppEntry],
        scannedApps: [AppEntry]
    ) -> CatalogScanReconcileResult {
        var apps = existingApps
        let scannedPaths = Set(
            scannedApps.flatMap(\.files).map(\.relativePath)
        )
        let originalPathOwners = Dictionary(
            uniqueKeysWithValues: apps.map {
                ($0.id, Set($0.files.map(\.relativePath)))
            }
        )

        for index in apps.indices {
            apps[index].files.removeAll {
                scannedPaths.contains($0.relativePath)
            }
        }

        var identityIndices = [String: [Int]]()
        var pathOwnerIndices = [String: [Int]]()
        for (index, app) in apps.enumerated() {
            identityIndices[identityKey(for: app), default: []].append(index)
            for path in originalPathOwners[app.id] ?? [] {
                pathOwnerIndices[path, default: []].append(index)
            }
        }

        var claimedExistingIDs = Set<AppEntry.ID>()
        for scannedApp in scannedApps {
            let scannedKey = identityKey(for: scannedApp)
            let appPaths = Set(scannedApp.files.map(\.relativePath))
            let identityIndex = identityIndices[scannedKey]?.first {
                !claimedExistingIDs.contains(apps[$0].id)
            }
            let pathOwnerIndex = appPaths
                .flatMap { pathOwnerIndices[$0] ?? [] }
                .filter { !claimedExistingIDs.contains(apps[$0].id) }
                .min()

            if let index = identityIndex ?? pathOwnerIndex {
                merge(
                    scannedApp,
                    into: &apps[index],
                    matchedByPath: pathOwnerIndex == index
                )
                claimedExistingIDs.insert(apps[index].id)
            } else {
                var newApp = AppMetadataEnricher().enrich(scannedApp)
                if newApp.hasIcon && newApp.iconOrigin == nil {
                    newApp.iconOrigin = .localBundle
                }
                apps.append(newApp)
                let index = apps.index(before: apps.endIndex)
                identityIndices[scannedKey, default: []].append(index)
            }
        }

        let scannedOriginalIDs = Set(originalPathOwners.compactMap {
            $0.value.isDisjoint(with: scannedPaths) ? nil : $0.key
        })
        apps.removeAll {
            scannedOriginalIDs.contains($0.id)
                && !claimedExistingIDs.contains($0.id)
                && $0.files.isEmpty
        }

        return CatalogScanReconcileResult(
            apps: apps,
            matchedExistingIDs: claimedExistingIDs
        )
    }

    private func merge(
        _ scannedApp: AppEntry,
        into existingApp: inout AppEntry,
        matchedByPath: Bool
    ) {
        let existingPaths = Set(existingApp.files.map(\.relativePath))
        existingApp.files.append(
            contentsOf: scannedApp.files.filter {
                !existingPaths.contains($0.relativePath)
            }
        )
        if matchedByPath {
            existingApp.name = scannedApp.name
            existingApp.category = scannedApp.category
            existingApp.subcategory = scannedApp.subcategory
        }
        if !existingApp.hasIcon, let iconData = scannedApp.iconData {
            existingApp.iconData = iconData
            existingApp.iconOrigin = scannedApp.iconOrigin ?? .localBundle
        }
        existingApp = AppMetadataEnricher().enrich(existingApp)
    }

    private func identityKey(for app: AppEntry) -> String {
        AppNameNormalizer.catalogIdentityKey(
            name: app.name,
            category: app.category,
            subcategory: app.subcategory
        )
    }
}
