import SwiftUI

struct AppDetailWindow: View {
    @Environment(\.dismiss) private var dismiss
    let app: AppEntry

    var body: some View {
        NavigationStack {
            AppDetailView(app: app)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Schließen") {
                            dismiss()
                        }
                    }
                }
        }
        .frame(minWidth: 620, minHeight: 680)
    }
}

struct AppDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CatalogStore
    @Environment(\.appAtlasTheme) private var theme
    @State private var showEditor = false
    @State private var showDeleteConfirmation = false
    @State private var licenseRecord: AppLicenseRecord?
    @State private var revealSerial = false
    let app: AppEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                LabeledContent("Kategorie", value: "\(displayedApp.category) / \(displayedApp.subcategory)")
                LabeledContent("Prüfstatus", value: displayedApp.reviewStatus.rawValue)
                LabeledContent("Quelle", value: displayedApp.sourceStatus.rawValue)
                if let sources = displayedApp.metadataSources,
                   !sources.isEmpty
                {
                    LabeledContent(
                        "Metadatenquellen",
                        value: sources.joined(separator: ", ")
                    )
                }

                if displayedApp.reviewStatus == .needsReview {
                    Divider()
                    CatalogReviewSection(
                        app: displayedApp,
                        edit: { showEditor = true }
                    )
                }

                if !displayedApp.versions.isEmpty {
                    LabeledContent("Versionen", value: displayedApp.versions.joined(separator: ", "))
                }

                Divider()
                links

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Beschreibung")
                        .font(.headline)
                    Text(displayedDetails)
                        .foregroundStyle(theme.mutedText)
                }

                if let licenseRecord, !licenseRecord.isEmpty {
                    Divider()
                    licenseSection(licenseRecord)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Lokale Dateien")
                        .font(.headline)

                    ForEach(displayedApp.files) { file in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(file.fileName)
                                .fontWeight(.medium)
                            Text(file.relativePath)
                                .font(.caption)
                                .foregroundStyle(theme.mutedText)
                                .textSelection(.enabled)
                            if file.sizeInBytes > 0 {
                                Text(ByteCountFormatter.string(fromByteCount: file.sizeInBytes, countStyle: .file))
                                    .font(.caption)
                                    .foregroundStyle(theme.mutedText.opacity(0.72))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 600, alignment: .leading)
        }
        .background(AppAtlasBackground())
        .foregroundStyle(theme.text)
        .navigationTitle(displayedApp.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showEditor = true
                } label: {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Aus Katalog löschen", systemImage: "trash")
                }
            }
        }
        .alert("App aus dem Katalog löschen?", isPresented: $showDeleteConfirmation) {
            Button("Abbrechen", role: .cancel) {}
            Button("Nur aus Katalog löschen", role: .destructive) {
                store.delete(displayedApp)
                dismiss()
            }
        } message: {
            Text("„\(displayedApp.name)“ wird nur aus AppAtlas entfernt. Zugehörige Dateien auf Datenträgern werden nicht verändert.")
        }
        .sheet(isPresented: $showEditor) {
            AppEditorView(existingApp: displayedApp) { updatedApp in
                store.update(updatedApp)
            }
        }
        .onChange(of: showEditor) { _, isPresented in
            if !isPresented {
                licenseRecord = LicenseKeychainStore.shared.load(
                    for: app.id
                )
            }
        }
        .task(id: app.id) {
            licenseRecord = LicenseKeychainStore.shared.load(for: app.id)
        }
    }

    private func licenseSection(
        _ record: AppLicenseRecord
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Private Lizenzdaten", systemImage: "key.fill")
                .font(.headline)
            if !record.licenseType.isEmpty {
                LabeledContent("Lizenztyp", value: record.licenseType)
            }
            if !record.registeredEmail.isEmpty {
                LabeledContent(
                    "Registrierte E-Mail",
                    value: record.registeredEmail
                )
            }
            if !record.serialNumber.isEmpty {
                HStack {
                    Text("Seriennummer")
                    Spacer()
                    if revealSerial {
                        Text(record.serialNumber)
                            .textSelection(.enabled)
                    } else {
                        Text(String(repeating: "•", count: 16))
                    }
                    Button {
                        revealSerial.toggle()
                    } label: {
                        Image(systemName: revealSerial ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }
            }
            if !record.notes.isEmpty {
                Text(record.notes)
                    .foregroundStyle(theme.mutedText)
            }
        }
    }

    private var links: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Links")
                .font(.headline)

            if let homepage = displayedHomepage,
               !isDuplicate(homepage, of: [
                    displayedDownloadURL,
                    displayedApp.githubURL
               ])
            {
                Link("Homepage öffnen", destination: homepage)
            } else {
                missingLink("Homepage fehlt")
            }
            if let downloadURL = displayedDownloadURL,
               !isDuplicate(downloadURL, of: [displayedApp.githubURL])
            {
                Link("Download öffnen", destination: downloadURL)
            } else {
                missingLink("Download-Link fehlt")
            }
            if let githubURL = displayedApp.githubURL {
                Link("GitHub-Projekt öffnen", destination: githubURL)
            }

            Button("Beschreibung und Links bearbeiten") {
                showEditor = true
            }
            .padding(.top, 4)
        }
    }

    private var displayedDetails: String { displayedApp.details }

    private var displayedHomepage: URL? {
        displayedApp.homepage
    }

    private var displayedDownloadURL: URL? {
        displayedApp.downloadURL
    }

    private var displayedApp: AppEntry {
        store.apps.first { $0.id == app.id } ?? app
    }

    private func isDuplicate(_ url: URL, of others: [URL?]) -> Bool {
        others.contains {
            URLRedirectResolver.equivalent(url, $0)
        }
    }

    private func missingLink(_ title: String) -> some View {
        Label(title, systemImage: "exclamationmark.circle")
            .foregroundStyle(theme.mutedText)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            AppIconView(app: displayedApp, size: 96, cornerRadius: 20)

            VStack(alignment: .leading, spacing: 6) {
                Text(displayedApp.name)
                    .font(.largeTitle.bold())
                Text(displayedApp.summary)
                    .foregroundStyle(theme.mutedText)
            }
        }
    }
}
