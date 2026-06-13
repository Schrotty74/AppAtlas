import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct AppEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appAtlasTheme) private var theme

    let existingApp: AppEntry?
    let onSave: (AppEntry) -> Void
    private let entryID: UUID

    @State private var name: String
    @State private var developer: String
    @State private var summary: String
    @State private var details: String
    @State private var category: String
    @State private var subcategory: String
    @State private var keywords: String
    @State private var homepage: String
    @State private var downloadURL: String
    @State private var githubURL: String
    @State private var reviewStatus: ReviewStatus
    @State private var iconData: Data?
    @State private var iconFileName: String?
    @State private var iconWasChanged = false
    @State private var iconURL: String = ""
    @State private var showIconImporter = false
    @State private var isLoadingIcon = false
    @State private var isTargetedForIconDrop = false
    @State private var licenseRecord = AppLicenseRecord()
    @State private var revealSerial = false
    @State private var licenseError: String?

    init(existingApp: AppEntry?, onSave: @escaping (AppEntry) -> Void) {
        self.existingApp = existingApp
        self.onSave = onSave
        self.entryID = existingApp?.id ?? UUID()
        _name = State(initialValue: existingApp?.name ?? "")
        _developer = State(initialValue: existingApp?.developer ?? "")
        _summary = State(initialValue: existingApp?.summary ?? "")
        _details = State(initialValue: existingApp?.details ?? "")
        _category = State(initialValue: existingApp?.category ?? "Sonstiges")
        _subcategory = State(initialValue: existingApp?.subcategory ?? "")
        _keywords = State(initialValue: existingApp?.keywords.joined(separator: ", ") ?? "")
        _homepage = State(initialValue: existingApp?.homepage?.absoluteString ?? "")
        _downloadURL = State(initialValue: existingApp?.downloadURL?.absoluteString ?? "")
        _githubURL = State(initialValue: existingApp?.githubURL?.absoluteString ?? "")
        _reviewStatus = State(initialValue: existingApp?.reviewStatus ?? .needsReview)
        _iconData = State(initialValue: existingApp?.iconData)
        _iconFileName = State(initialValue: existingApp?.iconFileName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("App") {
                    iconDropArea

                    HStack {
                        Button("Icon-Datei auswählen") {
                            showIconImporter = true
                        }
                        Button("Bild aus Zwischenablage einfügen") {
                            pasteIcon()
                        }
                        if iconData != nil {
                            Button("Icon entfernen", role: .destructive) {
                                iconData = nil
                                iconFileName = nil
                                iconWasChanged = true
                            }
                        }
                    }
                    HStack {
                        TextField("Direkte Bild-URL für App-Icon", text: $iconURL)
                        Button("Icon laden") {
                            loadIconFromURL()
                        }
                        .disabled(
                            iconURL.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ).isEmpty || isLoadingIcon
                        )
                    }
                    if isLoadingIcon {
                        ProgressView("Icon wird geladen …")
                    }
                    TextField("Name", text: $name)
                    TextField("Hersteller", text: $developer)
                    TextField("Kurzbeschreibung", text: $summary)
                    TextField("Kategorie", text: $category)
                    TextField("Unterkategorie", text: $subcategory)
                    TextField("Stichwörter, durch Kommas getrennt", text: $keywords)
                    Picker("Prüfstatus", selection: $reviewStatus) {
                        ForEach(ReviewStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                Section("Beschreibung") {
                    TextEditor(text: $details)
                        .frame(minHeight: 110)
                }

                Section("Links") {
                    TextField("Homepage", text: $homepage)
                    TextField("Download", text: $downloadURL)
                    TextField("GitHub", text: $githubURL)
                }

                Section("Private Lizenzdaten") {
                    Text("Diese Angaben werden nur im macOS-Schlüsselbund dieses Benutzers gespeichert und sind kein Bestandteil des App-Katalogs.")
                        .font(.caption)
                        .foregroundStyle(theme.mutedText)
                    HStack {
                        if revealSerial {
                            TextField(
                                "Seriennummer oder Lizenzschlüssel",
                                text: $licenseRecord.serialNumber
                            )
                        } else {
                            SecureField(
                                "Seriennummer oder Lizenzschlüssel",
                                text: $licenseRecord.serialNumber
                            )
                        }
                        Button {
                            revealSerial.toggle()
                        } label: {
                            Image(
                                systemName: revealSerial
                                    ? "eye.slash"
                                    : "eye"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    TextField(
                        "Registrierte E-Mail-Adresse",
                        text: $licenseRecord.registeredEmail
                    )
                    TextField(
                        "Lizenztyp",
                        text: $licenseRecord.licenseType
                    )
                    TextEditor(text: $licenseRecord.notes)
                        .frame(minHeight: 70)
                }

                if let existingApp, !existingApp.files.isEmpty {
                    Section("Lokale Dateien") {
                        Text("Die zugeordneten Dateien bleiben beim Bearbeiten unverändert.")
                            .foregroundStyle(theme.mutedText)
                        ForEach(existingApp.files) { file in
                            Text(file.relativePath)
                                .font(.caption)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(AppAtlasBackground())
            .foregroundStyle(theme.text)
            .navigationTitle(existingApp == nil ? "App hinzufügen" : "App bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 560, minHeight: 620)
        .fileImporter(
            isPresented: $showIconImporter,
            allowedContentTypes: [
                .image,
                UTType(filenameExtension: "icns") ?? .data
            ]
        ) { result in
            importIcon(result)
        }
        .task(id: entryID) {
            licenseRecord = LicenseKeychainStore.shared.load(
                for: entryID
            ) ?? AppLicenseRecord()
            if iconData == nil, let iconFileName {
                let data = await Task.detached {
                    IconStore.shared.data(
                        fileName: iconFileName,
                        thumbnail: false
                    )
                }.value
                iconData = data
            }
        }
        .alert(
            "Lizenzdaten konnten nicht gespeichert werden",
            isPresented: Binding(
                get: { licenseError != nil },
                set: { if !$0 { licenseError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(licenseError ?? "")
        }
    }

    private func makeEntry() -> AppEntry {
        AppEntry(
            id: entryID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            developer: nilIfEmpty(developer),
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            subcategory: subcategory.trimmingCharacters(in: .whitespacesAndNewlines),
            keywords: keywords
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty },
            homepage: url(homepage),
            downloadURL: url(downloadURL),
            githubURL: url(githubURL),
            iconFileName: iconWasChanged
                ? nil
                : existingApp?.iconFileName,
            iconData: iconWasChanged ? iconData : nil,
            files: existingApp?.files ?? [],
            reviewStatus: reviewStatus,
            sourceStatus: existingApp?.sourceStatus ?? .manual,
            reviewSuggestions: existingApp?.reviewSuggestions,
            userCustomizations: existingApp?.userCustomizations,
            metadataSources: existingApp?.metadataSources,
            iconOrigin: iconWasChanged
                ? .manual
                : existingApp?.iconOrigin,
            websitePromptSuppressed: existingApp?.websitePromptSuppressed
        )
    }

    private func nilIfEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func url(_ value: String) -> URL? {
        guard let value = nilIfEmpty(value) else {
            return nil
        }
        if let url = URL(string: value), url.scheme != nil {
            return url
        }
        return URL(string: "https://\(value)")
    }

    @ViewBuilder
    private var editorIcon: some View {
        if let iconData, let image = NSImage(data: iconData) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: 38))
                .frame(width: 64, height: 64)
                .foregroundStyle(theme.mutedText)
        }
    }

    private var iconDropArea: some View {
        HStack(spacing: 16) {
            editorIcon
            VStack(alignment: .leading, spacing: 4) {
                Text("App-Icon hier hineinziehen")
                    .font(.headline)
                Text("Oder ein kopiertes Bild aus der Zwischenablage einfügen.")
                    .font(.caption)
                    .foregroundStyle(theme.mutedText)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isTargetedForIconDrop
                        ? theme.accent.opacity(0.20)
                        : theme.panelSoft
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isTargetedForIconDrop ? theme.accent : theme.border,
                    style: StrokeStyle(
                        lineWidth: isTargetedForIconDrop ? 2 : 1,
                        dash: [6, 4]
                    )
                )
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else {
                return false
            }
            return importIcon(from: url)
        } isTargeted: {
            isTargetedForIconDrop = $0
        }
    }

    private func importIcon(_ result: Result<URL, Error>) {
        guard let url = try? result.get() else {
            return
        }
        _ = importIcon(from: url)
    }

    private func loadIconFromURL() {
        guard let url = url(iconURL) else {
            return
        }
        isLoadingIcon = true
        Task {
            if let data = await OnlineIconLoader.shared.iconData(from: url) {
                iconData = data
                iconWasChanged = true
            }
            isLoadingIcon = false
        }
    }

    private func importIcon(from url: URL) -> Bool {
        guard let sourceData = try? SecurityScopedFileAccess.readData(from: url),
              let png = IconImageConverter.compactPNG(from: sourceData)
        else {
            return false
        }
        iconData = png
        iconWasChanged = true
        return true
    }

    private func pasteIcon() {
        let pasteboard = NSPasteboard.general
        if let image = NSImage(pasteboard: pasteboard),
           let data = image.tiffRepresentation,
           let png = IconImageConverter.compactPNG(from: data)
        {
            iconData = png
            iconWasChanged = true
            return
        }
        if let url = pasteboard.readObjects(
            forClasses: [NSURL.self]
        )?.first as? URL {
            _ = importIcon(from: url)
        }
    }

    private func save() {
        do {
            try LicenseKeychainStore.shared.save(
                licenseRecord,
                for: entryID
            )
            onSave(makeEntry())
            dismiss()
        } catch {
            licenseError = error.localizedDescription
        }
    }
}
