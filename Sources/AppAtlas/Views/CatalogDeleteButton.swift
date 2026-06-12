import SwiftUI

struct CatalogDeleteButton: View {
    @EnvironmentObject private var store: CatalogStore
    @State private var showConfirmation = false
    @State private var errorMessage: String?

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
            if !app.files.isEmpty {
                Button("Lokale Dateien in Papierkorb legen", role: .destructive) {
                    moveLocalFilesToTrash()
                }
            }
        } message: {
            Text("Du kannst „\(app.name)“ nur aus AppAtlas entfernen oder alle zugeordneten lokalen Dateien in den macOS-Papierkorb legen.")
        }
        .alert(
            "Lokale Dateien konnten nicht gelöscht werden",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func moveLocalFilesToTrash() {
        do {
            try LocalAppTrashService().moveFilesToTrash(for: app)
            store.delete(app)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
