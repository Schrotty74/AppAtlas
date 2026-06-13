import AppKit
import SwiftUI

struct ScanImportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme
    @StateObject private var sourceBookmark = ScanSourceBookmark()

    @State private var result: ScanResult?
    @State private var selectedAppIDs = Set<UUID>()
    @State private var isScanning = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Ordner rein lesend scannen")
                    .font(.title2.bold())
                Text("AppAtlas sucht nach APP, DMG, PKG, ZIP, ISO, APK und EXE. Du bestimmst selbst, wo gesucht wird; der ausgewählte Ordner wird nicht verändert.")
                    .foregroundStyle(theme.mutedText)
                Text(
                    "Der Scan gleicht den Katalog mit dem vollständigen Inhalt "
                        + "dieses Ordners ab. Nicht mehr vorhandene oder nicht "
                        + "ausgewählte lokale Einträge werden aus dem Katalog "
                        + "entfernt; manuelle Einträge ohne Datei bleiben erhalten."
                )
                .font(.callout)
                .foregroundStyle(theme.mutedText)

                HStack {
                    Button("Quellordner auswählen …", action: chooseFolder)
                    Text(sourceBookmark.displayPath)
                        .foregroundStyle(theme.mutedText)
                        .lineLimit(1)
                        .textSelection(.enabled)
                }

                if let savedURL = sourceBookmark.selectedURL, result == nil, !isScanning {
                    Button("Gespeicherten Quellordner scannen") {
                        scan(savedURL)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if isScanning {
                    ProgressView("Dateien werden gelesen …")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let result {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("\(result.files.count) Dateien · \(result.apps.count) App-Vorschläge · \(selectedAppIDs.count) ausgewählt")
                                .font(.headline)
                            Spacer()
                            Button("Alle") {
                                selectedAppIDs = Set(result.apps.map(\.id))
                            }
                            .disabled(selectedAppIDs.count == result.apps.count)
                            Button("Keine") {
                                selectedAppIDs.removeAll()
                            }
                            .disabled(selectedAppIDs.isEmpty)
                        }

                        List(result.apps) { app in
                            HStack {
                                Button {
                                    toggleSelection(for: app.id)
                                } label: {
                                    Image(
                                        systemName: selectedAppIDs.contains(app.id)
                                            ? "checkmark.square.fill"
                                            : "square"
                                    )
                                    .foregroundStyle(
                                        selectedAppIDs.contains(app.id)
                                            ? theme.accent
                                            : theme.mutedText
                                    )
                                }
                                .buttonStyle(.plain)
                                .help(
                                    selectedAppIDs.contains(app.id)
                                        ? "Nicht in den Katalog aufnehmen"
                                        : "In den Katalog aufnehmen"
                                )

                                HStack(spacing: 10) {
                                    AppIconView(
                                        app: app,
                                        size: 38,
                                        cornerRadius: 9
                                    )
                                    VStack(alignment: .leading) {
                                        Text(app.name)
                                        Text(app.summary)
                                            .font(.caption)
                                            .foregroundStyle(theme.mutedText)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                Text("\(app.files.count)")
                                    .foregroundStyle(theme.mutedText)
                            }
                        }

                    }
                } else {
                    ContentUnavailableView(
                        "Bereit zum Scannen",
                        systemImage: "externaldrive.badge.magnifyingglass",
                        description: Text("Wähle einen beliebigen Ordner mit deinen Apps und Installern aus.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(24)
            .background(AppAtlasBackground())
            .foregroundStyle(theme.text)
            .navigationTitle("Apps scannen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Katalog mit \(selectedAppIDs.count) Apps abgleichen") {
                        if let result {
                            store.mergeScannedApps(
                                result.apps.filter {
                                    selectedAppIDs.contains($0.id)
                                }
                            )
                        }
                        dismiss()
                    }
                    .disabled(result == nil || isScanning)
                }
            }
            .alert(
                "Scan fehlgeschlagen",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .frame(minWidth: 760, minHeight: 620)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Auswählen und scannen"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }
        do {
            try sourceBookmark.save(url)
        } catch {
            errorMessage = "Der Quellordner konnte nicht dauerhaft gespeichert werden: \(error.localizedDescription)"
            return
        }
        scan(url)
    }

    private func scan(_ url: URL) {
        isScanning = true
        result = nil
        selectedAppIDs.removeAll()
        errorMessage = nil

        Task {
            let accessed = sourceBookmark.startAccessing(url)
            defer {
                sourceBookmark.stopAccessing(url, ifNeeded: accessed)
            }
            do {
                let scanResult = try await Task.detached {
                    try VolumeScanner().scan(url)
                }.value
                result = scanResult
                selectedAppIDs = Set(scanResult.apps.map(\.id))
            } catch {
                errorMessage = error.localizedDescription
            }
            isScanning = false
        }
    }

    private func toggleSelection(for id: UUID) {
        if selectedAppIDs.contains(id) {
            selectedAppIDs.remove(id)
        } else {
            selectedAppIDs.insert(id)
        }
    }
}
