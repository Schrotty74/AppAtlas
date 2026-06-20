import Foundation

struct CatalogSuggestion: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var kind: CatalogSuggestionKind
    var value: String
    var sourceLabel: String
    var sourceURL: URL?
    var sourceIdentifier: String?
    var detectedLanguage: String?
    var needsTranslation: Bool

    init(
        id: UUID = UUID(),
        kind: CatalogSuggestionKind,
        value: String,
        sourceLabel: String,
        sourceURL: URL? = nil,
        sourceIdentifier: String? = nil,
        detectedLanguage: String? = nil,
        needsTranslation: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.value = value
        self.sourceLabel = sourceLabel
        self.sourceURL = sourceURL
        self.sourceIdentifier = sourceIdentifier
        self.detectedLanguage = detectedLanguage
        self.needsTranslation = needsTranslation
    }
}

enum CatalogSuggestionKind: String, Hashable, Codable, Sendable {
    case description
    case homepage
    case download
    case github
    case icon

    var title: String {
        switch self {
        case .description: "Beschreibung"
        case .homepage: "Homepage"
        case .download: "Download-Link"
        case .github: "GitHub-Projekt"
        case .icon: "App-Icon"
        }
    }
}

struct UserCustomizations: Hashable, Codable, Sendable {
    var icon = false
    var description = false
    var links = false
}

struct PendingTranslation: Identifiable, Sendable {
    let id: UUID
    let appID: AppEntry.ID
    let suggestionID: CatalogSuggestion.ID
    let text: String
    let sourceLanguage: String
    let targetLanguage: String
}

struct PendingWebsitePrompt: Identifiable, Sendable {
    let id = UUID()
    let appID: AppEntry.ID
    let appName: String
}

struct WebsiteReviewSummary: Identifiable, Sendable {
    let id = UUID()
    let foundCount: Int
    let unresolvedCount: Int
}
