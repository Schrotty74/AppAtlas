import Foundation

public protocol EnrichableApp: Sendable {
    var name: String { get }
    var bundleIdentifiers: [String] { get }
    var developer: String? { get }
    var homepage: URL? { get }
    var category: String { get }
}

public extension EnrichableApp {
    var bundleIdentifiers: [String] { [] }
    var developer: String? { nil }
    var homepage: URL? { nil }
    var category: String { "" }
}

public struct BasicEnrichableApp: EnrichableApp {
    public let name: String
    public let bundleIdentifiers: [String]
    public let developer: String?
    public let homepage: URL?
    public let category: String

    public init(
        name: String,
        bundleIdentifiers: [String] = [],
        developer: String? = nil,
        homepage: URL? = nil,
        category: String = ""
    ) {
        self.name = name
        self.bundleIdentifiers = bundleIdentifiers
        self.developer = developer
        self.homepage = homepage
        self.category = category
    }
}

public protocol MetadataConfirmationProviding: Sendable {
    func domainScore(appName: String, candidateURL: URL) -> Double
    func isConfirmed(appName: String, appleTrackID: Int) -> Bool
    func isRejected(appName: String, appleTrackID: Int) -> Bool
}

public struct EmptyMetadataConfirmationProvider: MetadataConfirmationProviding {
    public init() {}

    public func domainScore(appName: String, candidateURL: URL) -> Double {
        0
    }

    public func isConfirmed(appName: String, appleTrackID: Int) -> Bool {
        false
    }

    public func isRejected(appName: String, appleTrackID: Int) -> Bool {
        false
    }
}

public enum MetadataDescriptionHeuristics {
    public static func needsDescriptionExpansion(_ text: String) -> Bool {
        isPlaceholderDescription(text)
            || (
                text.count < 220
                    && !text.contains("Typische Funktionen:")
            )
    }

    private static func isPlaceholderDescription(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            || trimmed.contains("Metadaten und Beschreibung müssen")
            || trimmed.contains("wurde dem Bereich")
            || trimmed.contains("Herstellerangaben, offizielle Links")
            || trimmed.contains("genaue Produktfunktion wird noch")
            || trimmed.contains("Sie dient zum Anzeigen, Bearbeiten")
            || trimmed.contains(
                "Beschreibung und offizielle Links können lokal ergänzt"
            )
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
