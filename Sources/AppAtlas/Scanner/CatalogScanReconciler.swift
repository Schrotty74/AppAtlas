import Foundation

struct CatalogScanReconcileResult: Sendable {
    let apps: [AppEntry]
    let matchedExistingIDs: Set<AppEntry.ID>
    let removedApps: [AppEntry]
}

struct CatalogScanReconciler: Sendable {
    func reconcile(
        existingApps: [AppEntry],
        scannedApps: [AppEntry]
    ) -> CatalogScanReconcileResult {
        var apps = existingApps
        let originalPathOwners = Dictionary(
            uniqueKeysWithValues: apps.map {
                ($0.id, Set($0.files.map(\.relativePath)))
            }
        )

        for index in apps.indices {
            apps[index].files.removeAll()
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
            let pathOwnerIndex = appPaths
                .flatMap { pathOwnerIndices[$0] ?? [] }
                .filter { !claimedExistingIDs.contains(apps[$0].id) }
                .min()
            let identityIndex = identityIndices[scannedKey]?.first {
                !claimedExistingIDs.contains(apps[$0].id)
            }

            if let index = pathOwnerIndex ?? identityIndex {
                merge(
                    scannedApp,
                    into: &apps[index],
                    preservesIdentity: true
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

        let removedApps = apps.filter {
            !(originalPathOwners[$0.id] ?? []).isEmpty
                && !claimedExistingIDs.contains($0.id)
        }
        let removedIDs = Set(removedApps.map(\.id))
        apps.removeAll { removedIDs.contains($0.id) }

        return CatalogScanReconcileResult(
            apps: apps,
            matchedExistingIDs: claimedExistingIDs,
            removedApps: removedApps
        )
    }

    private func merge(
        _ scannedApp: AppEntry,
        into existingApp: inout AppEntry,
        preservesIdentity: Bool
    ) {
        existingApp.files = scannedApp.files
        if preservesIdentity {
            existingApp.name = scannedApp.name
            existingApp.category = scannedApp.category
            existingApp.subcategory = scannedApp.subcategory
            if existingApp.developer == nil {
                existingApp.developer = scannedApp.developer
            }
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
            subcategory: app.subcategory,
            preservesAttachedYear: true
        )
    }
}
