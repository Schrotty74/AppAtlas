import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct AssistantRecommendation: Identifiable, Sendable {
    let id: UUID
    let appID: AppEntry.ID
    let appName: String
    let reason: String
    let score: Int

    init(appID: AppEntry.ID, appName: String, reason: String, score: Int) {
        self.id = UUID()
        self.appID = appID
        self.appName = appName
        self.reason = reason
        self.score = score
    }
}

struct AssistantSource: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let url: URL
    let origin: String
}

struct AssistantAnswer: Sendable {
    let text: String
    let recommendations: [AssistantRecommendation]
    let sources: [AssistantSource]
    let engine: String
}

struct CatalogAssistant: Sendable {
    func localRecommendations(
        query: String,
        apps: [AppEntry]
    ) -> [AssistantRecommendation] {
        rank(query: query, apps: apps)
    }

    func answer(
        query: String,
        apps: [AppEntry],
        includeInternet: Bool
    ) async -> AssistantAnswer {
        let ranked = rank(query: query, apps: apps)
        let sources = includeInternet ? await searchReddit(query: query) : []

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *),
           SystemLanguageModel.default.isAvailable,
           let generated = try? await appleAnswer(
               query: query,
               recommendations: ranked,
               sources: sources
           ) {
            return AssistantAnswer(
                text: generated,
                recommendations: ranked,
                sources: sources,
                engine: "Apple Intelligence · lokal auf diesem Mac"
            )
        }
        #endif

        return AssistantAnswer(
            text: fallbackAnswer(query: query, recommendations: ranked, sources: sources),
            recommendations: ranked,
            sources: sources,
            engine: "Lokale Kataloganalyse"
        )
    }

    private func rank(query: String, apps: [AppEntry]) -> [AssistantRecommendation] {
        let terms = expandedTerms(for: query)

        return apps.compactMap { app in
            let searchable = app.searchableText.lowercased()
            let matches = terms.filter { searchable.contains($0) }
            var score = matches.count * 10

            if terms.contains(where: { app.category.lowercased().contains($0) }) {
                score += 8
            }
            if terms.contains(where: { app.subcategory.lowercased().contains($0) }) {
                score += 12
            }
            if terms.contains(where: { app.name.lowercased().contains($0) }) {
                score += 15
            }

            guard score > 0 else {
                return nil
            }

            let reason = matches.prefix(4).joined(separator: ", ")
            return AssistantRecommendation(
                appID: app.id,
                appName: app.name,
                reason: reason.isEmpty ? "Passende Kategorie" : "Treffer: \(reason)",
                score: score
            )
        }
        .sorted {
            if $0.score == $1.score {
                return $0.appName.localizedStandardCompare($1.appName) == .orderedAscending
            }
            return $0.score > $1.score
        }
        .prefix(6)
        .map { $0 }
    }

    private func expandedTerms(for query: String) -> Set<String> {
        let normalized = query
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
        var terms = Set(
            normalized
                .split { !$0.isLetter && !$0.isNumber }
                .map(String.init)
                .filter { $0.count > 2 }
        )

        let groups = [
            ["video", "videos", "film", "filme", "schneiden", "schnitt", "editing", "editor", "aufnahme"],
            ["screenshot", "screenshots", "bildschirmfoto", "capture", "screen", "snipping"],
            ["audio", "musik", "sound", "ton", "aufnahme", "recording"],
            ["foto", "fotos", "bild", "bilder", "grafik", "photo", "image"],
            ["programmieren", "entwicklung", "code", "coding", "developer", "ide"],
            ["backup", "sicherung", "wiederherstellung", "recovery"],
            ["download", "herunterladen", "youtube", "loader"],
            ["ki", "ai", "chatbot", "assistent"]
        ]

        for group in groups where group.contains(where: terms.contains) {
            terms.formUnion(group)
        }
        return terms
    }

    private func fallbackAnswer(
        query: String,
        recommendations: [AssistantRecommendation],
        sources: [AssistantSource]
    ) -> String {
        guard let first = recommendations.first else {
            return "Im aktuellen Katalog finde ich noch keine eindeutig passende App. Ergänze Beschreibungen und Stichwörter oder aktiviere die Internetrecherche."
        }

        var result = "Für „\(query)“ passt \(first.appName) anhand der vorhandenen Katalogdaten am besten."
        if recommendations.count > 1 {
            let alternatives = recommendations.dropFirst().prefix(2).map(\.appName).joined(separator: " und ")
            result += " Als Alternativen kommen \(alternatives) infrage."
        }
        if !sources.isEmpty {
            result += " Zusätzlich wurden passende Reddit-Beiträge gefunden; sie sind unten als externe Meinungen verlinkt."
        }
        return result
    }

    private func searchReddit(query: String) async -> [AssistantSource] {
        await withTaskGroup(of: [AssistantSource].self) { group in
            for subreddit in ["macapps", "macos"] {
                group.addTask {
                    await redditResults(query: query, subreddit: subreddit)
                }
            }

            var results: [AssistantSource] = []
            for await sources in group {
                results.append(contentsOf: sources)
            }
            return Array(results.prefix(6))
        }
    }

    private func redditResults(query: String, subreddit: String) async -> [AssistantSource] {
        var components = URLComponents(
            string: "https://www.reddit.com/r/\(subreddit)/search.json"
        )
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "restrict_sr", value: "on"),
            URLQueryItem(name: "sort", value: "relevance"),
            URLQueryItem(name: "limit", value: "3")
        ]
        guard let url = components?.url else {
            return []
        }

        var request = URLRequest(url: url)
        request.setValue(
            "AppAtlas/0.1 (private macOS catalog assistant)",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return []
            }
            let listing = try JSONDecoder().decode(RedditListing.self, from: data)
            return listing.data.children.compactMap { child in
                guard let url = URL(string: "https://www.reddit.com\(child.data.permalink)") else {
                    return nil
                }
                return AssistantSource(
                    title: child.data.title,
                    url: url,
                    origin: "Reddit r/\(subreddit)"
                )
            }
        } catch {
            return []
        }
    }

    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private func appleAnswer(
        query: String,
        recommendations: [AssistantRecommendation],
        sources: [AssistantSource]
    ) async throws -> String {
        let candidates = recommendations.map {
            "- \($0.appName): \($0.reason), Wertung \($0.score)"
        }.joined(separator: "\n")
        let sourceTitles = sources.map {
            "- \($0.origin): \($0.title)"
        }.joined(separator: "\n")

        let session = LanguageModelSession(instructions: """
            Du bist der private App-Berater einer macOS-Mediathek.
            Empfiehl nur Apps aus der Kandidatenliste. Begründe knapp auf Deutsch.
            Reddit-Titel sind externe Meinungen, keine gesicherten Fakten.
            Wenn die Katalogdaten nicht reichen, sage das offen.
            """)
        let response = try await session.respond(to: """
            Frage: \(query)

            Lokale Kandidaten:
            \(candidates.isEmpty ? "Keine eindeutigen Kandidaten." : candidates)

            Optionale externe Fundstellen:
            \(sourceTitles.isEmpty ? "Keine." : sourceTitles)
            """)
        return response.content
    }
    #endif
}

private struct RedditListing: Decodable {
    let data: RedditListingData
}

private struct RedditListingData: Decodable {
    let children: [RedditChild]
}

private struct RedditChild: Decodable {
    let data: RedditPost
}

private struct RedditPost: Decodable {
    let title: String
    let permalink: String
}
