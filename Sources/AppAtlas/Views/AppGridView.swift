import SwiftUI

struct AppGridView: View {
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme

    private let columns = [
        GridItem(.adaptive(minimum: 122, maximum: 158), spacing: 14)
    ]

    var body: some View {
        Group {
            if store.filteredApps.isEmpty {
                ContentUnavailableView.search(text: store.searchText)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
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
                    .padding(14)
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
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme
    let app: AppEntry
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            AppIconView(app: app, size: 72, cornerRadius: 16)

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
        .padding(10)
        .frame(minHeight: 150, alignment: .top)
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
        .overlay(alignment: .bottomTrailing) {
            if store.isRefreshingApp(app.id) {
                ProgressView()
                    .controlSize(.small)
                    .padding(8)
                    .background(.thinMaterial, in: Circle())
                    .padding(8)
            }
        }
        .foregroundStyle(theme.text)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                Task {
                    await store.refreshApp(app)
                }
            } label: {
                Label("Diese App aktualisieren", systemImage: "arrow.clockwise")
            }
            .disabled(store.isRefreshingApp(app.id))
        }
    }
}
