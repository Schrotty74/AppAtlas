import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme
    @State private var expandedCategories = Set<String>()

    var body: some View {
        List {
            Section("Mediathek") {
                Button {
                    store.selectedCategory = nil
                } label: {
                    Label {
                        HStack {
                            Text("Alle Apps")
                            Spacer()
                            Text(store.apps.count, format: .number)
                                .foregroundStyle(theme.mutedText)
                        }
                    } icon: {
                        Image(systemName: "square.grid.2x2")
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    store.selectedCategory == nil
                        ? theme.accent.opacity(0.18)
                        : Color.clear
                )

                Label {
                    HStack {
                        Text("Zu prüfen")
                        Spacer()
                        Text(store.needsReviewCount, format: .number)
                            .foregroundStyle(theme.mutedText)
                    }
                } icon: {
                    Image(systemName: "checklist")
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    store.selectedCategory = CatalogStore.needsReviewFilter
                }
                .listRowBackground(
                    store.selectedCategory == CatalogStore.needsReviewFilter
                        ? theme.accent.opacity(0.18)
                        : Color.clear
                )
            }

            Section("Kategorien") {
                ForEach(store.categories, id: \.name) { category in
                    let folders = store.folderTree(for: category.name)
                    if folders.isEmpty {
                        categoryLabel(category.name, count: category.count)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                store.selectedCategory = category.name
                            }
                            .listRowBackground(
                                store.selectedCategory == category.name
                                    ? theme.accent.opacity(0.18)
                                    : Color.clear
                            )
                    } else {
                        DisclosureGroup(
                            isExpanded: expansionBinding(for: category.name)
                        ) {
                            ForEach(folders) { folder in
                                SidebarFolderNode(
                                    category: category.name,
                                    folder: folder
                                )
                            }
                        } label: {
                            categoryLabel(category.name, count: category.count)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.selectedCategory = category.name
                                }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(theme.panelSoft)
        .foregroundStyle(theme.text)
        .navigationTitle("AppAtlas")
    }

    private func categoryLabel(_ category: String, count: Int) -> some View {
        Label {
            HStack {
                Text(category)
                Spacer()
                Text(count, format: .number)
                    .foregroundStyle(theme.mutedText)
            }
        } icon: {
            Image(systemName: iconName(for: category))
        }
    }

    private func expansionBinding(for category: String) -> Binding<Bool> {
        Binding {
            expandedCategories.contains(category)
        } set: { isExpanded in
            if isExpanded {
                expandedCategories.insert(category)
            } else {
                expandedCategories.remove(category)
            }
        }
    }

    private func iconName(for category: String) -> String {
        switch category {
        case "Entwicklung": "hammer"
        case "Grafik": "paintpalette"
        case "Multimedia": "play.rectangle"
        case "System": "gearshape.2"
        case "Sicherheit": "lock.shield"
        case "Browser": "globe"
        case "Gaming": "gamecontroller"
        case "Office": "doc.text"
        default: "folder"
        }
    }
}

private struct SidebarFolderNode: View {
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme
    let category: String
    let folder: CatalogStore.FolderNode

    var body: some View {
        if folder.children.isEmpty {
            folderLabel
                .contentShape(Rectangle())
                .onTapGesture {
                    store.selectedCategory = filterValue
                }
                .listRowBackground(
                    store.selectedCategory == filterValue
                        ? theme.accent.opacity(0.18)
                        : Color.clear
                )
        } else {
            DisclosureGroup {
                ForEach(folder.children) { child in
                    SidebarFolderNode(category: category, folder: child)
                }
            } label: {
                folderLabel
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.selectedCategory = filterValue
                    }
            }
        }
    }

    private var filterValue: String {
        CatalogStore.subcategoryFilter(
            category: category,
            subcategory: folder.path
        )
    }

    private var folderLabel: some View {
        Label {
            HStack {
                Text(folder.name)
                Spacer()
                Text(folder.count, format: .number)
                    .foregroundStyle(theme.mutedText)
            }
        } icon: {
            Image(systemName: "folder")
        }
    }
}
