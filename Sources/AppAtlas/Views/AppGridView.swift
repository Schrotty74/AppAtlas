import SwiftUI

struct AppGridView: View {
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 190), spacing: 16)
    ]

    var body: some View {
        Group {
            if store.filteredApps.isEmpty {
                ContentUnavailableView.search(text: store.searchText)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(store.filteredApps) { app in
                            AppCardView(
                                app: app,
                                isSelected: store.selectedAppID == app.id
                            )
                            .onTapGesture {
                                store.selectedAppID = app.id
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(navigationTitle)
    }

    private var navigationTitle: String {
        store.selectedCollectionTitle
    }
}

private struct AppCardView: View {
    @Environment(\.appAtlasTheme) private var theme
    let app: AppEntry
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            AppIconView(app: app, size: 88, cornerRadius: 19)

            VStack(spacing: 4) {
                Text(app.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(app.summary)
                    .font(.caption)
                    .foregroundStyle(theme.mutedText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(12)
        .frame(minHeight: 174, alignment: .top)
        .frame(maxWidth: .infinity)
        .appAtlasGlassSurface(
            in: RoundedRectangle(cornerRadius: 14),
            fallbackColor: isSelected
                ? theme.accent.opacity(0.20)
                : theme.panel,
            tint: isSelected ? theme.accent.opacity(0.20) : nil,
            interactive: true
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isSelected ? theme.accent : theme.border.opacity(0.65),
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .overlay(alignment: .topTrailing) {
            CatalogDeleteButton(app: app)
                .padding(8)
        }
        .foregroundStyle(theme.text)
        .contentShape(Rectangle())
    }
}
