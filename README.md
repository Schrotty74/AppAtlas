# AppAtlas

<p align="center">
  <img src="Sources/AppAtlas/Resources/AppIcon.png" width="180" alt="AppAtlas Logo">
</p>

AppAtlas is a native, privacy-focused SwiftUI app for macOS. It organizes
personal app collections from user-selected folders and manages icons,
descriptions, links, tags, license information, and local catalog exports.

> Current release: **AppAtlas 1.1.0**

[Download AppAtlas 1.1.0](https://github.com/Schrotty74/AppAtlas/releases/download/v1.1.0/AppAtlas-1.1.0-macos.dmg)

## Key Features

- scan freely selected folders in read-only mode and filter out technical data
  and typical backup archives
- permanently exclude local folders and custom file extensions from scans
- compare new, changed, and removed files with the catalog on repeated scans
- manually add, edit, and delete app entries
- tag apps and filter them through the sidebar or search
- move local app files to the Trash only after explicit confirmation
- manage descriptions, links, and high-quality icons
- update missing metadata manually through "Update Catalog"
- review uncertain matches with source labels before accepting or rejecting them
- configure online lookups, parallel processing, and extended search locally
- manage per-app website prompts through an exclusion list
- translate foreign-language descriptions locally before saving them
- store icons locally as original files and fast thumbnails
- search apps by name, description, category, folder, and tags
- use hierarchical categories and subfolders
- use an app assistant with optional Reddit research
- import, export, and delete themes
- use native Liquid Glass effects for controls and cards on macOS 26 and later,
  with compatible rendering on older macOS versions
- export and import the catalog as JSON, optionally without license data,
  unencrypted, or password-protected with AES-256-GCM
- configure backup reminders for regular catalog exports
- view catalog statistics with categories, storage usage, and missing metadata
- import license data from JSON and CSV files
- store private license data in the macOS Keychain
- delete individual apps or the complete catalog
- create privacy-conscious bug reports for email or Codex
- use the interface in English or German

## Screenshots

No final app screenshots are currently stored in the repository. The existing
design drafts are available here:

- [Classic Light](Designvorschlaege/01-Klassisch-Hell.png)
- [Focus Dark](Designvorschlaege/02-Fokus-Dunkel.png)
- [Dashboard Light](Designvorschlaege/03-Dashboard-Hell.png)
- [Shelf Dark](Designvorschlaege/04-Regale-Dunkel.png)

## Requirements

- macOS 14 or later
- macOS 15 or later for Apple's local translation feature
- Swift 6

## Build and Install

Download the current release:
[AppAtlas 1.1.0](https://github.com/Schrotty74/AppAtlas/releases/download/v1.1.0/AppAtlas-1.1.0-macos.dmg)

When opening AppAtlas for the first time, macOS may display a warning because
the app is not notarized with a paid Apple Developer account.

To open the app anyway:

1. Right-click the app file.
2. Select **Open**.
3. Click **Open** or **Open Anyway** in the dialog that appears.

Alternatively, open **System Settings -> Privacy & Security** and confirm
**Open Anyway** at the bottom of the page.

For development checks:

```sh
swift test
swift build
```

For a manually launchable development build without beta, ZIP, or backup:

```sh
./Scripts/build-development.sh
```

The app is created at `dist/AppAtlas-Development/AppAtlas.app` and is not
opened automatically.

The release script may only be run after explicit approval:

```sh
APPATLAS_ALLOW_RELEASE_PACKAGE=YES ./Scripts/build-beta.sh
```

Build artifacts in `dist/` are not tracked by Git. Backups are created only on
explicit request. Local Git checks before every commit and push help prevent
typical catalog, export, and database files from being added.

## Documentation

- [Theme documentation](docs/themes/README.md)
- [Template for custom themes](docs/themes/appatlas-theme-template.json)
- [Complete example theme](docs/themes/example-custom-theme.json)
- [Example theme Autumn Ember](docs/themes/example-autumn-ember.json)
- [Example theme Winter Frost](docs/themes/example-winter-frost.json)
- [Project structure](docs/PROJECT_STRUCTURE.md)
- [Privacy details](docs/PRIVACY.md)
- [Privacy audit for AppAtlas 1.1.0](docs/PRIVACY_AUDIT_2026-06-16.md)

## Transparency

AppAtlas was designed and developed together with OpenAI Codex. The name
**AppAtlas** also came from a Codex suggestion. The app logo was created with
Codex as well.

## Report Issues

Bug reports and questions can be sent to
[appatlas@mailbox.org](mailto:appatlas@mailbox.org). AppAtlas also includes a
bug report dialog that creates a privacy-conscious report for email or for
pasting into Codex.

## License

AppAtlas is licensed under the GNU General Public License Version 3.

---

# AppAtlas

<p align="center">
  <img src="Sources/AppAtlas/Resources/AppIcon.png" width="180" alt="AppAtlas Logo">
</p>

AppAtlas ist eine native, datenschutzorientierte SwiftUI-App für macOS. Sie
ordnet persönliche App-Sammlungen aus frei wählbaren Ordnern und verwaltet
Icons, Beschreibungen, Links, Tags, Lizenzinformationen und lokale
Katalogexporte.

> Aktueller Release: **AppAtlas 1.1.0**

[AppAtlas 1.1.0 herunterladen](https://github.com/Schrotty74/AppAtlas/releases/download/v1.1.0/AppAtlas-1.1.0-macos.dmg)

## Funktionen

- frei wählbare Ordner rein lesend scannen und technische Daten sowie typische
  Backup-Archive herausfiltern
- lokale Ordner und selbst definierte Dateiendungen dauerhaft vom Scan
  ausschließen
- neue, geänderte und entfernte Dateien bei erneuten Scans mit dem Katalog
  abgleichen
- Apps manuell hinzufügen, bearbeiten und löschen
- Apps mit eigenen Tags markieren und über die Sidebar oder Suche filtern
- lokale App-Dateien nur nach ausdrücklicher Bestätigung in den Papierkorb
  legen
- Beschreibungen, Links und hochwertige Icons verwalten
- fehlende Metadaten bewusst über „Katalog aktualisieren“ ergänzen
- unsichere Treffer mit Quellenangabe unter „Zu prüfen“ bestätigen oder
  verwerfen
- Online-Abfragen, Parallelität und erweiterte Suche lokal konfigurieren
- Website-Rückfragen pro App über eine Ausschlussliste verwalten
- fremdsprachige Beschreibungen vor dem Speichern lokal übersetzen
- Icons lokal als separate Originale und schnelle Vorschaubilder speichern
- Apps über Namen, Beschreibungen, Kategorien, Ordner und Tags durchsuchen
- hierarchische Kategorien und Unterordner verwenden
- App-Assistent mit optionaler Reddit-Recherche
- Themes importieren, exportieren und löschen
- native Liquid-Glass-Effekte für Bedienelemente und Karten ab macOS 26 mit
  kompatibler Darstellung auf älteren macOS-Versionen
- Katalog als JSON exportieren und importieren, wahlweise ohne Lizenzdaten,
  unverschlüsselt oder passwortgeschützt mit AES-256-GCM
- konfigurierbare Backup-Erinnerung für regelmäßige Katalogexporte
- Katalogstatistik mit Kategorien, Speicherbedarf und fehlenden Metadaten
- Lizenzdaten aus JSON- und CSV-Dateien importieren
- private Lizenzdaten im macOS-Schlüsselbund speichern
- einzelne Apps oder den gesamten Katalog löschen
- datensparsamen Fehlerbericht für E-Mail oder Codex erstellen
- deutsche und englische Oberfläche

## Screenshots

Aktuell sind keine finalen App-Screenshots im Repository abgelegt. Die
vorhandenen Designvorschläge sind hier verfügbar:

- [Klassisch Hell](Designvorschlaege/01-Klassisch-Hell.png)
- [Fokus Dunkel](Designvorschlaege/02-Fokus-Dunkel.png)
- [Dashboard Hell](Designvorschlaege/03-Dashboard-Hell.png)
- [Regale Dunkel](Designvorschlaege/04-Regale-Dunkel.png)

## Voraussetzungen

- macOS 14 oder neuer
- macOS 15 oder neuer für Apples lokale Übersetzungsfunktion
- Swift 6

## Build und Installation

Aktuellen Release herunterladen:
[AppAtlas 1.1.0](https://github.com/Schrotty74/AppAtlas/releases/download/v1.1.0/AppAtlas-1.1.0-macos.dmg)

Beim ersten Öffnen zeigt macOS möglicherweise eine Warnung, da AppAtlas nicht
mit einem kostenpflichtigen Apple Developer Account notarisiert ist.

So öffnest du die App trotzdem:

1. Rechtsklick auf die App-Datei.
2. „Öffnen“ wählen.
3. Im erscheinenden Dialog erneut „Öffnen“ beziehungsweise „Trotzdem öffnen“
   anklicken.

Alternativ kannst du unter **Systemeinstellungen -> Datenschutz & Sicherheit**
ganz unten **Trotzdem öffnen** bestätigen.

Für Entwicklungsprüfungen:

```sh
swift test
swift build
```

Für einen manuell startbaren Entwicklungsstand ohne Beta, ZIP oder Backup:

```sh
./Scripts/build-development.sh
```

Die App liegt anschließend unter `dist/AppAtlas-Development/AppAtlas.app` und
wird nicht automatisch geöffnet.

Das Release-Skript darf nur nach ausdrücklicher Freigabe ausgeführt werden:

```sh
APPATLAS_ALLOW_RELEASE_PACKAGE=YES ./Scripts/build-beta.sh
```

Build-Artefakte unter `dist/` werden nicht von Git verfolgt. Backups werden
nur auf ausdrückliche Anweisung erstellt. Lokale Git-Prüfungen vor jedem
Commit und Push verhindern zusätzlich die Aufnahme typischer Katalog-,
Export- und Datenbankdateien.

## Dokumentation

- [Theme-Dokumentation](docs/themes/README.md)
- [Vorlage für eigene Themes](docs/themes/appatlas-theme-template.json)
- [Vollständiges Beispieltheme](docs/themes/example-custom-theme.json)
- [Beispieltheme Herbstglut](docs/themes/example-autumn-ember.json)
- [Beispieltheme Winterfest](docs/themes/example-winter-frost.json)
- [Projektstruktur](docs/PROJECT_STRUCTURE.md)
- [Details zum Datenschutz](docs/PRIVACY.md)
- [Datenschutzaudit für AppAtlas 1.1.0](docs/PRIVACY_AUDIT_2026-06-16.md)

## Transparenz

AppAtlas wurde gemeinsam mit OpenAI Codex konzipiert und programmiert. Auch
der Name **AppAtlas** entstand aus einem Vorschlag von Codex. Das App-Logo
wurde ebenfalls mit Codex erstellt.

## Fehler Melden

Fehlerberichte und Rückfragen können an
[appatlas@mailbox.org](mailto:appatlas@mailbox.org) gesendet werden. AppAtlas
enthält außerdem einen Fehlerbericht-Dialog, der einen datensparsamen Bericht
für eine E-Mail oder zum Einfügen in Codex erstellt.

## Lizenz

AppAtlas steht unter der GNU General Public License Version 3.
