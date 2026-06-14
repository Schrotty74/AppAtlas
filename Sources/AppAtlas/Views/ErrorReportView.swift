import AppKit
import SwiftUI

struct ErrorReportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var steps = ""
    @State private var expectedBehavior = ""
    @State private var copied = false
    @State private var emailError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fehler melden")
                .font(.title2.bold())

            Text(
                "Beschreibe den Fehler. AppAtlas fügt nur technische "
                    + "Basisangaben hinzu, niemals Katalog-, Lizenz- oder Pfaddaten."
            )
            .foregroundStyle(.secondary)

            Form {
                TextField("Kurzer Titel", text: $title)
                reportEditor("Was ist passiert?", text: $description)
                reportEditor("Schritte zum Nachstellen", text: $steps)
                reportEditor("Erwartetes Verhalten", text: $expectedBehavior)
            }
            .formStyle(.grouped)

            HStack {
                Link(
                    ErrorReport.emailAddress,
                    destination: URL(
                        string: "mailto:\(ErrorReport.emailAddress)"
                    )!
                )

                Spacer()

                Button(copied ? "Für Codex kopiert" : "Für Codex kopieren") {
                    copyForCodex()
                }

                Button("E-Mail erstellen") {
                    composeEmail()
                }
                .keyboardShortcut(.defaultAction)

                Button("Schließen") {
                    dismiss()
                }
            }
        }
        .padding(24)
        .frame(width: 680, height: 620)
        .alert(
            "E-Mail konnte nicht erstellt werden",
            isPresented: Binding(
                get: { emailError != nil },
                set: { if !$0 { emailError = nil } }
            )
        ) {
            Button("OK") {
                emailError = nil
            }
        } message: {
            Text(emailError ?? "")
        }
    }

    private func reportEditor(
        _ title: LocalizedStringKey,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            TextEditor(text: text)
                .font(.body)
                .frame(minHeight: 72)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor))
                }
        }
    }

    private var report: ErrorReport {
        ErrorReport.current(
            title: title,
            description: description,
            steps: steps,
            expectedBehavior: expectedBehavior
        )
    }

    private func copyForCodex() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(report.text, forType: .string)
        copied = true
    }

    private func composeEmail() {
        guard let service = NSSharingService(
            named: .composeEmail
        ) else {
            emailError =
                "Auf diesem Mac ist kein E-Mail-Programm eingerichtet. "
                + "Kopiere den Bericht stattdessen für Codex oder sende ihn "
                + "manuell an \(ErrorReport.emailAddress)."
            return
        }

        service.recipients = [ErrorReport.emailAddress]
        service.subject = report.subject
        service.perform(withItems: [report.text])
    }
}
