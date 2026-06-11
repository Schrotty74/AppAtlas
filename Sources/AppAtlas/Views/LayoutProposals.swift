import SwiftUI

enum AppLayout: String, CaseIterable, Identifiable {
    case classic
    case focus
    case compact
    case dashboard
    case shelves

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: AppLocalization.text("1 · Klassisch")
        case .focus: AppLocalization.text("2 · Fokus")
        case .compact: AppLocalization.text("3 · Kompakt")
        case .dashboard: AppLocalization.text("4 · Dashboard")
        case .shelves: AppLocalization.text("5 · Regale")
        }
    }

    var systemImage: String {
        switch self {
        case .classic: "sidebar.left"
        case .focus: "rectangle.inset.filled"
        case .compact: "list.bullet.rectangle"
        case .dashboard: "rectangle.3.group"
        case .shelves: "books.vertical"
        }
    }
}

struct ClassicLibraryLayout: View {
    @EnvironmentObject private var store: CatalogStore

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } content: {
            AppGridView()
                .navigationSplitViewColumnWidth(min: 440, ideal: 650)
        } detail: {
            LibraryDetailOrPlaceholder()
        }
    }
}

struct FocusLibraryLayout: View {
    @EnvironmentObject private var store: CatalogStore
    @State private var presentedApp: AppEntry?

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let selected = store.selectedApp ?? store.filteredApps.first {
                        FocusHero(app: selected) {
                            presentedApp = selected
                        }
                    }

                    LayoutSectionHeader(
                        title: store.selectedCollectionTitle,
                        subtitle: "\(store.filteredApps.count) Apps"
                    )

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 180, maximum: 230), spacing: 18)],
                        spacing: 18
                    ) {
                        ForEach(store.filteredApps) { app in
                            LibraryPosterCard(
                                app: app,
                                height: 128
                            ) {
                                presentedApp = app
                            }
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Fokus")
        }
        .sheet(item: $presentedApp) { app in
            AppDetailWindow(app: app)
        }
    }
}

struct CompactLibraryLayout: View {
    @EnvironmentObject private var store: CatalogStore

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 210)
        } content: {
            List(store.filteredApps, selection: $store.selectedAppID) { app in
                CompactAppRow(app: app)
                    .tag(app.id)
            }
            .navigationTitle(store.selectedCollectionTitle)
            .navigationSplitViewColumnWidth(min: 360, ideal: 450)
        } detail: {
            LibraryDetailOrPlaceholder()
        }
    }
}

struct DashboardLibraryLayout: View {
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme
    @State private var presentedApp: AppEntry?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AppAtlas")
                            .font(.largeTitle.bold())
                        Text("Lokaler Softwarekatalog")
                            .foregroundStyle(theme.mutedText)
                    }

                    Spacer()

                    StatusPill(
                        title: "\(store.apps.count) Apps",
                        systemImage: "checkmark.circle"
                    )
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        CategoryChip(
                            title: "Alle",
                            count: store.apps.count,
                            isSelected: store.selectedCategory == nil
                        ) {
                            store.selectedCategory = nil
                        }

                        ForEach(store.categories, id: \.name) { category in
                            CategoryChip(
                                title: category.name,
                                count: category.count,
                                isSelected: store.selectedCategory == category.name
                            ) {
                                store.selectedCategory = category.name
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    LayoutSectionHeader(
                        title: store.selectedCollectionTitle,
                        subtitle: "\(store.filteredApps.count) Treffer"
                    )

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(store.filteredApps) { app in
                            LibrarySquareCard(app: app) {
                                presentedApp = app
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Dashboard")
        .sheet(item: $presentedApp) { app in
            AppDetailWindow(app: app)
        }
    }
}

struct ShelvesLibraryLayout: View {
    @EnvironmentObject private var store: CatalogStore
    @State private var presentedApp: AppEntry?

    private var groupedApps: [(String, [AppEntry])] {
        Dictionary(grouping: store.filteredApps, by: \.category)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.0.localizedStandardCompare($1.0) == .orderedAscending }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 210)
        } detail: {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 30) {
                    ForEach(groupedApps, id: \.0) { category, apps in
                        VStack(alignment: .leading, spacing: 12) {
                            LayoutSectionHeader(
                                title: category,
                                subtitle: "\(apps.count) Apps"
                            )

                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(apps) { app in
                                        LibraryPosterCard(
                                            app: app,
                                            height: 112
                                        ) {
                                            presentedApp = app
                                        }
                                            .frame(width: 180)
                                    }
                                }
                                .padding(.bottom, 4)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Regale")
        }
        .sheet(item: $presentedApp) { app in
            AppDetailWindow(app: app)
        }
    }
}

private struct LibraryDetailOrPlaceholder: View {
    @EnvironmentObject private var store: CatalogStore

    var body: some View {
        if let app = store.selectedApp {
            AppDetailView(app: app)
        } else {
            ContentUnavailableView(
                "Keine App ausgewählt",
                systemImage: "square.grid.2x2",
                description: Text("Wähle eine App aus der Mediathek.")
            )
        }
    }
}

private struct FocusHero: View {
    @Environment(\.appAtlasTheme) private var theme
    let app: AppEntry
    let openDetails: () -> Void

    var body: some View {
        HStack(spacing: 22) {
            AppIconView(app: app, size: 112, cornerRadius: 26)

            VStack(alignment: .leading, spacing: 8) {
                Text("IM FOKUS")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accent)
                Text(app.name)
                    .font(.system(size: 32, weight: .bold))
                Text(app.summary)
                    .font(.title3)
                    .foregroundStyle(theme.mutedText)
                    .lineLimit(2)
                Label("\(app.category) · \(app.subcategory)", systemImage: "folder")
                    .font(.callout)
                    .foregroundStyle(theme.mutedText)
            }

            Spacer()
        }
        .padding(24)
        .themedPanel(cornerRadius: 24)
        .contentShape(Rectangle())
        .onTapGesture(perform: openDetails)
    }
}

private struct CompactAppRow: View {
    @Environment(\.appAtlasTheme) private var theme
    let app: AppEntry

    var body: some View {
        HStack(spacing: 12) {
            AppIconView(app: app, size: 42, cornerRadius: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .fontWeight(.medium)
                Text(app.summary)
                    .font(.caption)
                    .foregroundStyle(theme.mutedText)
                    .lineLimit(1)
            }

            Spacer()

            Text(app.files.count, format: .number)
                .foregroundStyle(theme.mutedText)
                .monospacedDigit()
                .help("Lokale Dateien")
        }
        .padding(.vertical, 3)
    }
}

private struct LibraryPosterCard: View {
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme
    let app: AppEntry
    let height: CGFloat
    let openDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.accent.opacity(0.38),
                                theme.accent.opacity(0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: height)

                AppIconView(app: app, size: 62, cornerRadius: 15)
                    .padding(14)
            }

            Text(app.name)
                .font(.headline)
                .lineLimit(1)
            Text(app.summary)
                .font(.caption)
                .foregroundStyle(theme.mutedText)
                .lineLimit(2)
        }
        .padding(10)
        .background(
            theme.panel,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    store.selectedAppID == app.id
                        ? theme.accent
                        : theme.border.opacity(0.70),
                    lineWidth: store.selectedAppID == app.id ? 2 : 1
                )
        }
        .foregroundStyle(theme.text)
        .contentShape(Rectangle())
        .onTapGesture {
            store.selectedAppID = app.id
            openDetails()
        }
    }
}

private struct LibrarySquareCard: View {
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme
    let app: AppEntry
    let openDetails: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            AppIconView(app: app, size: 72, cornerRadius: 17)
            Text(app.name)
                .font(.headline)
                .lineLimit(1)
            Text(app.summary)
                .font(.caption)
                .foregroundStyle(theme.mutedText)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            store.selectedAppID == app.id
                ? theme.accent.opacity(0.20)
                : theme.panel,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.border.opacity(0.65), lineWidth: 1)
        }
        .foregroundStyle(theme.text)
        .contentShape(Rectangle())
        .onTapGesture {
            store.selectedAppID = app.id
            openDetails()
        }
    }
}

private struct CategoryChip: View {
    @Environment(\.appAtlasTheme) private var theme
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Text(count, format: .number)
                    .foregroundStyle(
                        isSelected ? theme.accentText : theme.mutedText
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isSelected ? theme.accent : theme.panelSoft,
                in: Capsule()
            )
            .foregroundStyle(isSelected ? theme.accentText : theme.text)
        }
        .buttonStyle(.plain)
    }
}

private struct StatusPill: View {
    @Environment(\.appAtlasTheme) private var theme
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.callout.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(theme.panelSoft, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(theme.border.opacity(0.7), lineWidth: 1)
            }
    }
}

private struct LayoutSectionHeader: View {
    @Environment(\.appAtlasTheme) private var theme
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title2.bold())
            Spacer()
            Text(subtitle)
                .foregroundStyle(theme.mutedText)
        }
    }
}
