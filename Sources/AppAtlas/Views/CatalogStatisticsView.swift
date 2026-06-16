import SwiftUI

struct CatalogStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme

    var body: some View {
        let statistics = store.statistics

        NavigationStack {
            List {
                Section("Übersicht") {
                    LabeledContent("Apps gesamt", value: "\(statistics.totalApps)")
                    LabeledContent(
                        "Lokale Dateien gesamt",
                        value: ByteCountFormatter.string(
                            fromByteCount: statistics.totalSizeInBytes,
                            countStyle: .file
                        )
                    )
                    LabeledContent(
                        "Apps mit Lizenzdaten",
                        value: "\(statistics.appsWithLicenseData)"
                    )
                }

                Section("Fehlende Angaben") {
                    LabeledContent(
                        "Ohne Beschreibung",
                        value: "\(statistics.appsWithoutDescription)"
                    )
                    LabeledContent(
                        "Ohne Icon",
                        value: "\(statistics.appsWithoutIcon)"
                    )
                    LabeledContent(
                        "Ohne Homepage",
                        value: "\(statistics.appsWithoutHomepage)"
                    )
                }

                Section("Kategorien") {
                    ForEach(statistics.appsPerCategory, id: \.category) { item in
                        LabeledContent(item.category, value: "\(item.count)")
                    }
                }
            }
            .navigationTitle("Katalogstatistik")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppAtlasBackground())
            .foregroundStyle(theme.text)
        }
        .frame(width: 520, height: 620)
    }
}
