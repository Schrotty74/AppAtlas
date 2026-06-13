import SwiftUI

struct LicenseImportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var createMissingEntries = false

    let plan: LicenseImportPlan
    let importLicenses: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Lizenzimport prüfen")
                .font(.title2.bold())

            Text(
                "Es werden keine Seriennummern in dieser Vorschau angezeigt. "
                    + "Nur eindeutig zugeordnete Einträge werden gespeichert."
            )
            .foregroundStyle(.secondary)

            summary

            if !plan.matches.isEmpty
                || !plan.unmatchedNames.isEmpty
                || !plan.ambiguousNames.isEmpty
            {
                List {
                    Section("Sicher zugeordnet") {
                        ForEach(plan.matches, id: \.appID) { match in
                            Label(
                                match.appName,
                                systemImage: "checkmark.circle"
                            )
                        }
                    }
                    if !plan.unmatchedNames.isEmpty {
                        Section("Ohne Katalogeintrag") {
                            ForEach(plan.unmatchedNames, id: \.self) { name in
                                Label(name, systemImage: "plus.circle")
                            }
                        }
                    }
                    if !plan.ambiguousNames.isEmpty {
                        Section("Nicht eindeutig") {
                            ForEach(plan.ambiguousNames, id: \.self) { name in
                                Label(
                                    name,
                                    systemImage: "questionmark.circle"
                                )
                            }
                        }
                    }
                }
                .frame(minHeight: 180)
            }

            if !plan.unmatchedNames.isEmpty {
                Toggle(
                    "Fehlende Lizenz-Apps als manuelle Katalogeinträge anlegen",
                    isOn: $createMissingEntries
                )
                Text(
                    "Diese Einträge enthalten keine lokale Datei und werden "
                        + "unter „Lizenzen“ zur späteren Prüfung angelegt."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Abbrechen", role: .cancel) {
                    dismiss()
                }
                Button("Lizenzdaten importieren") {
                    importLicenses(createMissingEntries)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(plan.matches.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 620, height: 560)
    }

    private var summary: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
            GridRow {
                Text("Sicher zugeordnet")
                Text("\(plan.matches.count)")
            }
            GridRow {
                Text("Ohne Katalogeintrag")
                Text("\(plan.unmatchedNames.count)")
            }
            GridRow {
                Text("Nicht eindeutig")
                Text("\(plan.ambiguousNames.count)")
            }
        }
    }
}
