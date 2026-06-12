import SwiftUI

struct CatalogDeleteButton: View {
    @EnvironmentObject private var store: CatalogStore
    @State private var showConfirmation = false

    let app: AppEntry

    var body: some View {
        Button(role: .destructive) {
            showConfirmation = true
        } label: {
            Image(systemName: "trash.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .red)
        }
        .buttonStyle(.borderless)
        .help("Aus Katalog löschen")
        .alert(
            "App aus dem Katalog löschen?",
            isPresented: $showConfirmation
        ) {
            Button("Abbrechen", role: .cancel) {}
            Button("Nur aus Katalog löschen", role: .destructive) {
                store.delete(app)
            }
        } message: {
            Text("„\(app.name)“ wird nur aus AppAtlas entfernt. Zugehörige Dateien auf Datenträgern werden nicht verändert.")
        }
    }
}
