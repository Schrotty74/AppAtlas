import Foundation

struct AppEntry: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var developer: String?
    var summary: String
    var details: String
    var category: String
    var subcategory: String
    var keywords: [String]
    var homepage: URL?
    var downloadURL: URL?
    var githubURL: URL?
    var iconFileName: String?
    var iconData: Data?
    var files: [LocalAppFile]
    var reviewStatus: ReviewStatus
    var sourceStatus: SourceStatus
    var reviewSuggestions: [CatalogSuggestion]?
    var userCustomizations: UserCustomizations?
    var metadataSources: [String]?
    var iconOrigin: IconOrigin?
    var websitePromptSuppressed: Bool?

    init(
        id: UUID = UUID(),
        name: String,
        developer: String? = nil,
        summary: String = "",
        details: String = "",
        category: String,
        subcategory: String,
        keywords: [String] = [],
        homepage: URL? = nil,
        downloadURL: URL? = nil,
        githubURL: URL? = nil,
        iconFileName: String? = nil,
        iconData: Data? = nil,
        files: [LocalAppFile],
        reviewStatus: ReviewStatus = .needsReview,
        sourceStatus: SourceStatus = .localImport,
        reviewSuggestions: [CatalogSuggestion]? = nil,
        userCustomizations: UserCustomizations? = nil,
        metadataSources: [String]? = nil,
        iconOrigin: IconOrigin? = nil,
        websitePromptSuppressed: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.developer = developer
        self.summary = summary
        self.details = details
        self.category = category
        self.subcategory = subcategory
        self.keywords = keywords
        self.homepage = homepage
        self.downloadURL = downloadURL
        self.githubURL = githubURL
        self.iconFileName = iconFileName
        self.iconData = iconData
        self.files = files
        self.reviewStatus = reviewStatus
        self.sourceStatus = sourceStatus
        self.reviewSuggestions = reviewSuggestions
        self.userCustomizations = userCustomizations
        self.metadataSources = metadataSources
        self.iconOrigin = iconOrigin
        self.websitePromptSuppressed = websitePromptSuppressed
    }

    var versions: [String] {
        Array(Set(files.compactMap(\.detectedVersion))).sorted()
    }

    var totalSizeInBytes: Int64 {
        files.reduce(0) { $0 + $1.sizeInBytes }
    }

    var hasIcon: Bool {
        iconFileName != nil || iconData != nil
    }

    var suggestions: [CatalogSuggestion] {
        reviewSuggestions ?? []
    }

    var customizations: UserCustomizations {
        userCustomizations ?? UserCustomizations()
    }

    var suppressesWebsitePrompt: Bool {
        websitePromptSuppressed == true
    }

    var searchableText: String {
        [
            name,
            developer ?? "",
            summary,
            details,
            category,
            subcategory,
            keywords.joined(separator: " "),
            files.map(\.fileName).joined(separator: " "),
            files.map(\.relativePath).joined(separator: " ")
        ]
        .joined(separator: " ")
        .normalizedForCatalogSearch
    }

    func matchesSearch(_ query: String) -> Bool {
        let normalizedQuery = query.normalizedForCatalogSearch
        let terms = normalizedQuery
            .split(whereSeparator: \.isWhitespace)
        if terms.allSatisfy({ searchableText.contains($0) }) {
            return true
        }
        let compactQuery = normalizedQuery.filter {
            $0.isLetter || $0.isNumber
        }
        let compactSearchableText = searchableText.filter {
            $0.isLetter || $0.isNumber
        }
        if !compactQuery.isEmpty && compactSearchableText.contains(compactQuery) {
            return true
        }
        guard compactQuery.count >= 4 else {
            return false
        }
        let compactName = name.normalizedForCatalogSearch.filter {
            $0.isLetter || $0.isNumber
        }
        let threshold = compactQuery.count <= 5 ? 0.8 : 0.82
        if AppNameMatcher.similarity(compactQuery, compactName) >= threshold {
            return true
        }
        return name.normalizedForCatalogSearch
            .split(whereSeparator: \.isWhitespace)
            .contains {
                AppNameMatcher.similarity(compactQuery, String($0)) >= threshold
            }
    }
}

extension String {
    var normalizedForCatalogSearch: String {
        let folded = folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
        .lowercased()
        let separated = String(
            folded.map { $0.isLetter || $0.isNumber ? $0 : " " }
        )
        return separated
        .split(whereSeparator: \.isWhitespace)
        .map(String.init)
        .joined(separator: " ")
    }
}

enum IconOrigin: String, Hashable, Codable, Sendable {
    case localBundle
    case iTunes
    case github
    case website
    case manual
}

enum ReviewStatus: String, CaseIterable, Hashable, Codable, Sendable {
    case needsReview = "Zu prüfen"
    case confirmed = "Bestätigt"
}

enum SourceStatus: String, CaseIterable, Hashable, Codable, Sendable {
    case localImport = "Lokaler TSV-Import"
    case locallyInspected = "Lokal geprüft"
    case communityCatalog = "Homebrew-Cask-Katalog"
    case officialSource = "Offizielle Quelle"
    case manual = "Manuell angelegt"
}
