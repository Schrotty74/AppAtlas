import SwiftUI

enum CatalogExportChoice: String, CaseIterable, Identifiable {
    case withoutLicenses
    case licensesEncrypted
    case licensesPlaintext

    var id: String { rawValue }

    var title: String {
        switch self {
        case .withoutLicenses:
            "Ohne Lizenzdaten"
        case .licensesEncrypted:
            "Mit Lizenzdaten, passwortgeschützt"
        case .licensesPlaintext:
            "Mit Lizenzdaten, unverschlüsselt"
        }
    }
}

struct CatalogExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var choice = CatalogExportChoice.withoutLicenses
    @State private var password = ""
    @State private var confirmation = ""

    let export: (CatalogExportProtection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Katalog exportieren")
                .font(.title2.bold())

            Picker("Lizenzdaten", selection: $choice) {
                ForEach(CatalogExportChoice.allCases) { choice in
                    Text(choice.title).tag(choice)
                }
            }
            .pickerStyle(.radioGroup)

            if choice == .licensesEncrypted {
                SecureField("Passwort", text: $password)
                    .textFieldStyle(.roundedBorder)
                SecureField("Passwort wiederholen", text: $confirmation)
                    .textFieldStyle(.roundedBorder)

                Text("Mindestens 12 Zeichen. Das Passwort kann nicht wiederhergestellt werden. Verwende ein langes, einzigartiges Passwort und bewahre es sicher auf.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else if choice == .licensesPlaintext {
                Label(
                    "Die Exportdatei enthält Seriennummern und weitere private Lizenzdaten frei lesbar.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.orange)
            } else {
                Text("Seriennummern und andere Schlüsselbunddaten werden nicht exportiert.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Abbrechen", role: .cancel) {
                    dismiss()
                }
                Button("Exportieren") {
                    export(protection)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canExport)
            }
        }
        .padding(24)
        .frame(width: 520)
    }

    private var canExport: Bool {
        choice != .licensesEncrypted
            || (password.count >= 12 && password == confirmation)
    }

    private var protection: CatalogExportProtection {
        switch choice {
        case .withoutLicenses:
            .withoutLicenses
        case .licensesEncrypted:
            .licensesEncrypted(password: password)
        case .licensesPlaintext:
            .licensesPlaintext
        }
    }
}

struct CatalogImportPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""

    let importCatalog: (String) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Geschützten Katalog importieren")
                .font(.title2.bold())
            Text("Gib das Passwort ein, mit dem dieser Export geschützt wurde.")
                .foregroundStyle(.secondary)
            SecureField("Passwort", text: $password)
                .textFieldStyle(.roundedBorder)
                .onSubmit(submit)

            HStack {
                Spacer()
                Button("Abbrechen", role: .cancel) {
                    dismiss()
                }
                Button("Importieren") {
                    submit()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(password.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private func submit() {
        guard !password.isEmpty else {
            return
        }
        if importCatalog(password) {
            dismiss()
        }
    }
}
