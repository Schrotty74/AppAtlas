import Foundation

struct AppCatalogBuilder: Sendable {
    func buildEntries(from files: [LocalAppFile]) -> [AppEntry] {
        let appFiles = files.filter(CatalogEntryFilter().shouldInclude)
        let grouped = Dictionary(grouping: appFiles) {
            AppNameNormalizer.catalogIdentityKey(
                name: $0.fileName,
                category: $0.sourceCategory,
                subcategory: $0.sourceSubcategory
            )
        }

        return grouped.values.map(makeEntry).sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private func makeEntry(files: [LocalAppFile]) -> AppEntry {
        let sortedFiles = files.sorted {
            $0.relativePath.localizedStandardCompare($1.relativePath) == .orderedAscending
        }
        let representative = sortedFiles[0]
        let name = AppNameNormalizer.displayName(for: representative.fileName)
        let category = representative.sourceCategory
        let subcategory = representative.sourceSubcategory
        let fileTypes = Array(Set(sortedFiles.map(\.fileType))).sorted()
        let metadata = AppMetadataEnricher()

        return metadata.enrich(AppEntry(
            name: name,
            developer: sortedFiles.compactMap(\.bundleDeveloper).first,
            summary: metadata.summary(
                name: name,
                category: category,
                subcategory: subcategory,
                fileTypes: fileTypes
            ),
            details: metadata.details(
                name: name,
                category: category,
                subcategory: subcategory,
                fileTypes: fileTypes
            ),
            category: category,
            subcategory: subcategory,
            keywords: fileTypes,
            iconData: sortedFiles.compactMap(\.iconData).first,
            files: sortedFiles,
            iconOrigin: sortedFiles.contains(where: { $0.iconData != nil })
                ? .localBundle
                : nil
        ))
    }
}
