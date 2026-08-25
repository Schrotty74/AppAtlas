# AppAtlas Projektkontext

AppAtlas ist eine native SwiftUI-App für macOS zur persönlichen Verwaltung
eines lokalen App-Katalogs.

Die allgemeinen Arbeits-, Git-, Veröffentlichungs- und Repository-Datenschutzregeln stehen verbindlich in `AGENTS.md`. Diese Datei enthält den projektspezifischen technischen und funktionalen Kontext.

## Technische Struktur

- AppAtlas ist ein Swift-Package mit Xcode-Projekt.
- `AppMetadataKit` ist ein internes SwiftPM-Target im selben Repository.
  Es gibt keine notwendige Abhängigkeit mehr auf einen benachbarten
  `../AppMetadataKit`-Ordner.
- Xcode bindet `AppMetadataKit` als lokales Paket aus dem AppAtlas-Repository
  ein. `swift build`, `swift test` und Xcode-Builds müssen daher ohne
  zusätzliches Schwester-Repository funktionieren.
- Wichtige Ordner: `Sources/AppAtlas/` fuer App-Code,
  `Sources/AppMetadataKit/` fuer das interne Modul, `Tests/` fuer Tests,
  `Packaging/` fuer Bundle-Konfiguration, `Scripts/` fuer Build- und
  Release-Helfer sowie `docs/` fuer oeffentliche Fach- und
  Veroeffentlichungsdokumentation. Details stehen in
  `docs/PROJECT_STRUCTURE.md`.
- Katalogimport und -export verwenden versionierte JSON-Formate; Themes
  verwenden `appatlas-theme`. Lokale Kataloge, Icons und Einstellungen sind
  keine Repository-Dateien.

## Build, Test und Release

- Fuer normale Entwicklungspruefungen ausschliesslich `swift build` und
  `swift test` verwenden. Sie erzeugen keine Release-Pakete und oeffnen die
  App nicht.
- Xcode und `Scripts/build-current-branch.sh` sind fuer den lokalen
  Dev-Build. Beta und Final werden ausschliesslich mit den bestehenden
  Release-Skripten erstellt.
- Eine Beta startet mit `Scripts/create-beta-from-dev.sh <beta-version>` auf
  `dev`. Ein Final startet mit
  `Scripts/publish-beta-as-final.sh <final-version>` aus dem sauberen
  Arbeitsstand. Die genaue, vor jedem Release zu lesende Anleitung steht in
  `docs/RELEASE_WORKFLOW.md`.
- Vor einem Final sind Datenschutzcheck, erweitertes Audit und ein neuer
  oeffentlicher Audit-Bericht Pflicht.

## Scanner-Stand

- Diese Scanner-Eigenschaften sind beabsichtigt und dürfen bei der weiteren
  Entwicklung nicht versehentlich zurückgebaut werden:
  - `VolumeScanner` verwendet `ScanExclusionPolicy`.
  - Verschachtelte Backup-Sammlungen, technische Ordner und typische
    Backup-Archive werden beim Scan ausgeschlossen.
  - Echte Backup-Anwendungen bleiben als App-Vorschläge erhalten.
  - `ScanImportView` zeigt die vollständige Vorschlagsliste.
  - Scanvorschläge können einzeln sowie über „Alle“ und „Keine“ ausgewählt
    werden.
  - Nur ausgewählte Vorschläge werden in den Katalog aufgenommen.
- Aktueller offizieller Release: `1.2.3`.
- Die lokale Homebrew-Katalogzuordnung verwendet für die Suche zusätzlich eine
  vorsichtige Namensvariante ohne rein numerischen Anhang, etwa
  `ExampleTool2` zu `ExampleTool`. Der sichtbare Katalogname bleibt dabei
  unveraendert.
- Fuer dieselbe lokale Suche werden zusammengezogene Dateinamen und reine
  Verpackungszusätze wie `Installer` oder `App` aufgetrennt beziehungsweise
  ignoriert. Das erweitert nur den Abgleich mit einem bereits gespeicherten
  Katalog und erzeugt keine Netzabfrage.
- Bei einer bewusst gestarteten Online-Aktualisierung fragt die App fuer echte
  App-Bundles zuerst den Mac App Store per lokaler Bundle-ID ab. Erst ohne
  exakten Treffer folgt die bestehende Namenssuche.
- Bereits bekannte GitHub-Projektadressen werden bei derselben normalen
  Online-Aktualisierung direkt verwendet. Die Suche nach unbekannten
  GitHub-Projekten bleibt wegen der öffentlichen GitHub-Suchgrenzen in der
  erweiterten Suche.

## Projektspezifischer Datenschutz

- Neue Benutzer starten mit einem leeren Katalog.
- Persönliche Katalogdaten liegen ausschließlich im lokalen
  Application-Support-Verzeichnis.
- Seriennummern und weitere private Lizenzdaten liegen im macOS-Schlüsselbund.
  Sie werden nur nach ausdrücklicher Auswahl des Benutzers unverschlüsselt
  oder passwortgeschützt exportiert.
- Bei jeder neuen Funktion mit Datenschutzwirkung muss diese Wirkung vor der
  Umsetzung genannt und eine datensparsame Alternative vorgeschlagen werden.
- Vor Commit, Push und Release ist der vorhandene Datenschutzcheck auszuführen.
- Das umfangreiche Datenschutzaudit einschließlich Prüfung der Git-Historie,
  Release-Dateien und Netzwerkzugriffe wird ausschließlich bei jeder finalen
  Version durchgeführt, nicht bei Betas.
- Für jede finale Version wird der bestehende öffentliche Datenschutzbericht
  um einen neuen chronologischen Prüfbericht ergänzt. Frühere Berichte bleiben
  erhalten und werden nicht ersetzt.

## Veröffentlichungs- und Backup-Besonderheiten

- Normale Entwicklungsprüfungen verwenden ausschließlich `swift build` und
  `swift test`. Dabei werden weder AppAtlas geöffnet noch ZIP-Dateien,
  Prüfsummen, Backups oder iCloud-Kopien erzeugt.
- AppAtlas wird bei Änderungen und Tests niemals automatisch geöffnet,
  aktiviert oder in den Vordergrund gebracht.
- Beta-Veröffentlichungen benötigen den normalen Datenschutzcheck, aber kein
  umfangreiches Datenschutzaudit und keinen neuen öffentlichen Prüfbericht.
- Vor jeder finalen Veröffentlichung sind das umfangreiche Datenschutzaudit
  und ein ergänzender öffentlicher Prüfbericht verpflichtend.
- Das erweiterte Datenschutzaudit bewertet bekannte ältere AppAtlas-DMG-/ZIP-
  Artefakte unter früheren `Backup/releases/...`-Pfaden als öffentliche
  Release-Artefakte. Private Kataloge, Scanlisten, Datenbanken,
  Lizenzexporte, persönliche Pfade und Geheimnisse bleiben weiterhin
  blockierende Audit-Funde.
- Im festgelegten iCloud-Ordner bleiben höchstens zwei AppAtlas-Backups
  erhalten. Nach einer erfolgreich geprüften neuen Kopie wird dort
  ausschließlich das älteste `AppAtlas-Backup-*.zip` entfernt. Lokale Backups
  und Sicherungen anderer Projekte bleiben unverändert.
- Die beiden Release-Skriptkorrekturen nach `1.2.3` liegen nur auf `dev` und
  sind nicht Bestandteil des veröffentlichten Final-Standes. Sie werden erst
  mit einer ausdrücklich freigegebenen nächsten Version veröffentlicht.

## Produktregeln

- Ordner werden nur nach bewusster Auswahl rein lesend gescannt.
- Der Scanner überspringt technische Unterordner, Datensammlungen und typische
  Backup-Archive. Echte Backup-Anwendungen bleiben als App-Vorschläge erhalten.
- Scanvorschläge werden vor der Aufnahme einzeln ausgewählt; kein Vorschlag
  wird außerhalb der vollständigen Prüfliste ungefragt importiert.
- Bei `.app`-Bundles wird neben Bundle-ID und Hersteller auch der offizielle
  App-Name aus dem Bundle gelesen. Dieser hat fuer die lokale Erkennung Vorrang
  vor einem ungenauen Ordner- oder Dateinamen. Produkteditionen wie `Pro`,
  `Lite`, `Plus`, `HD` und `Air` bleiben voneinander getrennt; ein unklarer
  Treffer wird nicht automatisch als Grundversion uebernommen.
- Quelldateien werden nicht verändert.
- Online-Anreicherung läuft ausschließlich nach einem bewussten Klick auf
  „Katalog aktualisieren“ und überschreibt keine vorhandenen Metadaten.
- Der Homebrew-Cask- und der Setapp-Katalog werden ausschließlich bei dieser
  bewussten Aktualisierung abgerufen und danach getrennt lokal gespeichert.
  Der schnelle Scan nutzt nur diese lokalen Caches und startet keine
  Netzwerkabfrage. Setapp ergänzt bei eindeutigem Mac-App-Treffer eine
  Kurzbeschreibung und bei fehlendem Download-Link die Setapp-Appseite; die
  offizielle Hersteller-Homepage bleibt unverändert.
- Katalogimport und -export verwenden versionierte JSON-Formate. Der
  Standardexport enthält keine Lizenzdaten; geschützte Lizenzexporte
  verwenden PBKDF2-HMAC-SHA256 und AES-256-GCM.
- Der datensparsame Standardexport enthält keine Schlüsselbunddaten.
- Import, Export und manuell gewählte Dateien verwenden einen gemeinsamen
  Security-Scoped-Dateizugriff. Lizenzimporte zeigen vor dem Speichern nur die
  eindeutig zugeordneten App-Namen, niemals die privaten Lizenzwerte.
- Die Katalogspeicherung prüft Kennungen und Dateipfade vor dem Schreiben,
  validiert eine Schreibkopie und hält die letzte gültige Fassung zur
  automatischen Wiederherstellung bereit.
- Scan-Ergebnisse werden in einem eigenen, indexierten Abgleichsdienst mit dem
  Katalog zusammengeführt. Ein vollständiger Scan ersetzt den lokalen
  Dateistand: neue und geänderte Dateien werden übernommen, entfernte Dateien
  werden aus dem Katalog gelöscht. Manuelle Einträge ohne Datei sowie manuelle
  Icons und Beschreibungen bleiben geschützt.
- Frei konfigurierbare Scanner-Ausschlussordner liegen ausschließlich in den
  lokalen Benutzereinstellungen und können als Ordnername oder relativer Pfad
  hinterlegt werden. Direkt ausgewählte lokale Ordner werden als
  Security-Scoped Bookmarks nur auf dem jeweiligen Mac gespeichert.
- Zusätzlich lassen sich einzelne Dateiendungen lokal vom Scan ausschließen.
- Lokale `.app`-Icons haben Vorrang. Danach werden eindeutig passende
  installierte Apps geprüft. Onlinebilder müssen mindestens 128 Pixel groß,
  nahezu quadratisch und als Icon oder Logo erkennbar sein; Screenshots,
  Vorschauen, Banner und Dokumentationsbilder werden abgewiesen.
- Online-Metadatenquellen verwenden eine gemeinsame Vertrauensbewertung aus
  Name, Kategorie, Unterordner, Hersteller, bestätigter Domain und Bundle-ID.
  Automatische Übernahmen benötigen mindestens `0,80` sowie `0,08` Abstand
  zum zweitbesten Treffer. Werte ab `0,65` werden ausschließlich zur Prüfung
  vorgeschlagen; schwächere Treffer werden verworfen.
- Der Homebrew-Cask-Katalog wird nur bei einer bewusst ausgelösten
  Online-Aktualisierung geladen und lokal zwischengespeichert. Schnelle Scans
  verwenden ausschließlich diesen lokalen Cache und starten keine
  Homebrew-Netzwerkanfrage.
- Bestätigte Domains, GitHub-Repositories und Apple-Store-IDs werden nur lokal
  in den Benutzereinstellungen gelernt und niemals exportiert.
- Bestätigte Website-URLs werden bei der Nachbearbeitung strukturiert
  ausgewertet: GitHub-Release-URLs werden als Repository und Download-Link
  getrennt gespeichert, direkte `.dmg`-/`.pkg`-/`.zip`-Links als Download mit
  Hersteller-Host als Homepage. GitHub-Projekte können anschließend
  Beschreibung, Icon, Homepage und Release-Link ergänzen.
- Die Hauptansicht verwendet einen zentralen Zustand für Dialoge, Importe und
  Bestätigungen. Import-/Exportformate liegen in getrennten Diensten.
- Sidebar-Ordner stammen aus den gespeicherten Quell-Unterordnern; Dateinamen
  dürfen niemals als Ordner erscheinen. Ein Ordnerfilter muss dieselben Apps
  liefern, die sein Zähler umfasst.
- Der Lizenzimport normalisiert Versions- und Verpackungszusätze, führt
  doppelte Lizenzzeilen zusammen und bietet für wirklich fehlende Einträge
  optional private manuelle Katalogeinträge ohne lokale Datei an.
- Lokale Icons liegen separat als Originale und 256-Pixel-Vorschaubilder in
  Application Support. Der lokale Katalog enthält nur Icon-Referenzen;
  portable Exporte enthalten weiterhin die Originalicons.
- Themes verwenden das Format `appatlas-theme`.
- Der leere Erststart-Bildschirm bietet einen Link zum öffentlichen Handbuch.
  Dieser öffnet je nach eingestellter App-Sprache das deutsche oder englische
  PDF-Handbuch auf GitHub. Bei jeder neuen Funktion oder sichtbaren
  Verhaltensänderung müssen beide Handbücher vor dem zugehörigen Commit
  aktualisiert und erneut als PDFs erzeugt werden.
  Eine feste, datensparsame AppAtlas-Einführungsfrage kann in die
  Zwischenablage kopiert und anschließend in ChatGPT, Google Gemini oder
  Claude eingefügt werden. Die Schaltflächen verwenden lokal eingebundene
  offizielle Dienstlogos. Die kurze Einführungsfrage verweist lediglich auf
  das öffentliche Handbuch; dessen Inhalt wird nicht in den Prompt kopiert.
  Persönliche Katalogdaten, lokale Pfade und Lizenzdaten werden nicht
  übergeben.
- AppAtlas steht unter GPLv3.

## Arbeitsregeln

Die allgemeinen Regeln für Arbeitsweise, verständliche Erklärungen, Änderungen, Tests, Git-Aktionen, Veröffentlichungen und Repository-Datenschutz stehen ausschließlich in `AGENTS.md`.

## Bekannte Grenzen

- Metadaten und Icons koennen bei seltenen oder aehnlich benannten Apps weiter
  eine manuelle Pruefung benoetigen.
- Der schnelle Scan bleibt absichtlich offline; neue Online-Quellen duerfen
  ihn nicht blockieren.
- Die optionale lokale Apple-Intelligence-Unterstuetzung braucht kompatible
  Hardware, macOS 26 und eine aktivierte Apple-Intelligence-Installation.
