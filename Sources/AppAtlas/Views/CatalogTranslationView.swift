import SwiftUI
#if canImport(Translation)
@preconcurrency import Translation
#endif

struct CatalogTranslationView: View {
    @EnvironmentObject private var store: CatalogStore

    var body: some View {
        Group {
            if #available(macOS 15.0, *),
               let pending = store.pendingTranslation
            {
                TranslationTaskView(pending: pending)
                    .environmentObject(store)
            }
        }
        .frame(width: 1, height: 1)
        .opacity(0.001)
        .accessibilityHidden(true)
    }
}

#if canImport(Translation)
@available(macOS 15.0, *)
private struct TranslationTaskView: View {
    @EnvironmentObject private var store: CatalogStore
    let pending: PendingTranslation

    var body: some View {
        Color.clear
            .id(pending.id)
            .translationTask(configuration) { session in
                do {
                    let response = try await session.translate(pending.text)
                    store.completeTranslation(
                        response.targetText,
                        for: pending
                    )
                } catch {
                    store.completeTranslation(nil, for: pending)
                }
            }
    }

    private var configuration: TranslationSession.Configuration {
        TranslationSession.Configuration(
            source: Locale.Language(identifier: pending.sourceLanguage),
            target: Locale.Language(identifier: pending.targetLanguage)
        )
    }
}
#endif
