import Testing
import Foundation
import AppMetadataKit

@Test func publicAPIIsImportable() async throws {
    let app = BasicEnrichableApp(
        name: "Cinebench2024.dmg",
        bundleIdentifiers: ["com.maxon.cinebench"],
        category: "Benchmark"
    )
    let candidate = MetadataMatchCandidate(
        name: "Cinebench 2024",
        contextText: "benchmark cpu gpu performance",
        developer: "Maxon",
        url: URL(string: "https://cinebench.net/"),
        bundleIdentifier: "com.maxon.cinebench",
        sourceReliability: 0.95
    )

    #expect(AppNameNormalizer.displayName(for: app.name) == "Cinebench")
    #expect(
        MetadataMatchScorer.score(app: app, candidate: candidate) >= 0.80
    )
}
