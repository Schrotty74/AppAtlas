# AppAtlas Projektkontext

AppAtlas ist eine native SwiftUI-App für macOS zur persönlichen Verwaltung
eines lokalen App-Katalogs.

## Technische Struktur

- AppAtlas ist ein Swift-Package mit Xcode-Projekt.
- `AppMetadataKit` ist ein internes SwiftPM-Target im selben Repository.
  Es gibt keine notwendige Abhängigkeit mehr auf einen benachbarten
  `../AppMetadataKit`-Ordner.
- Xcode bindet `AppMetadataKit` als lokales Paket aus dem AppAtlas-Repository
  ein. `swift build`, `swift test` und Xcode-Builds müssen daher ohne
  zusätzliches Schwester-Repository funktionieren.

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
- Aktueller offizieller Release: `1.2.0`.

## Datenschutz hat Vorrang

- Das Git-Repository und öffentliche Builds enthalten niemals persönliche
  Kataloge, Scanlisten, App-Namen, Lizenzdaten oder lokale Benutzerpfade.
- Neue Benutzer starten mit einem leeren Katalog.
- Persönliche Katalogdaten liegen ausschließlich im lokalen
  Application-Support-Verzeichnis.
- Seriennummern und weitere private Lizenzdaten liegen im macOS-Schlüsselbund.
  Sie werden nur nach ausdrücklicher Auswahl des Benutzers unverschlüsselt
  oder passwortgeschützt exportiert.
- Bei jeder neuen Funktion mit Datenschutzwirkung muss diese Wirkung vor der
  Umsetzung genannt und eine datensparsame Alternative vorgeschlagen werden.
- Vor jedem Commit, Push und Release muss ein Datenschutzcheck erfolgen.
- Das umfangreiche Datenschutzaudit einschließlich Prüfung der Git-Historie,
  Release-Dateien und Netzwerkzugriffe wird ausschließlich bei jeder finalen
  Version durchgeführt, nicht bei Betas.
- Für jede finale Version wird der bestehende öffentliche Datenschutzbericht
  um einen neuen chronologischen Prüfbericht ergänzt. Frühere Berichte bleiben
  erhalten und werden nicht ersetzt.

## Veröffentlichungs- und Backup-Regeln

- Normale Entwicklungsprüfungen verwenden ausschließlich `swift build` und
  `swift test`. Dabei werden weder AppAtlas geöffnet noch ZIP-Dateien,
  Prüfsummen, Backups oder iCloud-Kopien erzeugt.
- AppAtlas wird bei Änderungen und Tests niemals automatisch geöffnet,
  aktiviert oder in den Vordergrund gebracht.
- Lokale Release-Pakete und ZIP-Dateien werden ausschließlich nach einer
  ausdrücklichen Benutzeranweisung erstellt.
- Lokale Benutzerpfade, Volume-Pfade, Kataloge, App-Namen, Lizenzdaten und
  andere Nutzerdaten dürfen weder in Quellcode noch in Binärdateien,
  Release-Pakete, Backups oder GitHub gelangen.

- Änderungen dürfen lokal umgesetzt, getestet und dokumentiert werden.
- Git-Pushes, GitHub-Releases, Tags und andere Veröffentlichungen erfolgen
  ausschließlich nach einer ausdrücklichen Anweisung des Benutzers.
- Neue Beta-Builds oder Beta-Versionsnummern werden ausschließlich nach einer
  ausdrücklichen Anweisung des Benutzers erstellt.
- Beta-Veröffentlichungen benötigen den normalen Datenschutzcheck, aber kein
  umfangreiches Datenschutzaudit und keinen neuen öffentlichen Prüfbericht.
- Vor jeder finalen Veröffentlichung sind das umfangreiche Datenschutzaudit
  und ein ergänzender öffentlicher Prüfbericht verpflichtend.
- Das erweiterte Datenschutzaudit bewertet bekannte ältere AppAtlas-DMG-/ZIP-
  Artefakte unter früheren `Backup/releases/...`-Pfaden als öffentliche
  Release-Artefakte. Private Kataloge, Scanlisten, Datenbanken,
  Lizenzexporte, persönliche Pfade und Geheimnisse bleiben weiterhin
  blockierende Audit-Funde.
- Backups und iCloud-Kopien werden ausschließlich nach einer ausdrücklichen
  Anweisung des Benutzers erstellt.
- Im festgelegten iCloud-Ordner bleiben höchstens zwei AppAtlas-Backups
  erhalten. Nach einer erfolgreich geprüften neuen Kopie wird dort
  ausschließlich das älteste `AppAtlas-Backup-*.zip` entfernt. Lokale Backups
  und Sicherungen anderer Projekte bleiben unverändert.
- Änderungen nach `1.2.0` bleiben als unveröffentlichter
  Entwicklungsstand erhalten, bis ihre Veröffentlichung ausdrücklich
  freigegeben wird.

## Produktregeln

- Ordner werden nur nach bewusster Auswahl rein lesend gescannt.
- Der Scanner überspringt technische Unterordner, Datensammlungen und typische
  Backup-Archive. Echte Backup-Anwendungen bleiben als App-Vorschläge erhalten.
- Scanvorschläge werden vor der Aufnahme einzeln ausgewählt; kein Vorschlag
  wird außerhalb der vollständigen Prüfliste ungefragt importiert.
- Quelldateien werden nicht verändert.
- Online-Anreicherung läuft ausschließlich nach einem bewussten Klick auf
  „Katalog aktualisieren“ und überschreibt keine vorhandenen Metadaten.
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
  Eine feste, datensparsame AppAtlas-Einführungsfrage kann in die
  Zwischenablage kopiert und anschließend in ChatGPT, Google Gemini oder
  Claude eingefügt werden. Die Schaltflächen verwenden lokal eingebundene
  offizielle Dienstlogos. Die kurze Einführungsfrage verweist lediglich auf
  das öffentliche Handbuch; dessen Inhalt wird nicht in den Prompt kopiert.
  Persönliche Katalogdaten, lokale Pfade und Lizenzdaten werden nicht
  übergeben.
- AppAtlas steht unter GPLv3.
- Backups werden nur auf ausdrückliche Anweisung erstellt.

## Zusätzliche Zusammenarbeit

- Der Nutzer kann nicht coden und kennt sich mit technischen
  Fehlermeldungen, Logs und Build-Ausgaben nicht aus.
- Harte Auslöse-Regel: Eine Frage des Nutzers ist nur als Frage zu
  beantworten. Bei Fragen darf Codex keine Dateien ändern, keine Tests
  ausführen, keinen Build starten und keine App öffnen.
- Codeänderungen, Tests, Builds oder App-Starts sind nur erlaubt, wenn der
  Nutzer eindeutig einen Arbeitsbefehl gibt, z. B. `fix das`, `setz das um`,
  `teste das`, `mach dev build` oder `baue das`.
- Bei gemischten oder unklaren Nachrichten muss Codex zuerst fragen, ob nur
  erklärt oder tatsächlich umgesetzt werden soll.
- Bei Problemen soll Codex die technische Analyse und Umsetzung selbst
  übernehmen, soweit Zugriff darauf besteht.
- Wenn Informationen vom Nutzer nötig sind, soll Codex in einfachen Worten
  fragen und genau erklären, wo geklickt oder was kopiert werden soll.
- Möglichst fokussiert arbeiten und die kleinste sinnvolle Änderung umsetzen.
  Keine unnötigen Umbauten, Designänderungen oder neuen Funktionen.
- Wenn der Chat oder Kontext zu schwer oder alt wird, soll Codex darauf
  hinweisen, dass ein neuer Chat sinnvoll wäre, und dafür eine kurze
  Übergabe-Zusammenfassung geben.
- Wenn mehrere Lösungen möglich sind, soll Codex die einfache und robuste
  Variante wählen. Wenn etwas riskant wird oder größere Änderungen nötig
  wären, soll Codex vorher kurz Bescheid sagen.
- Soweit sinnvoll möglich testen, ob die Änderung funktioniert.
- Am Ende kurz in normaler Sprache erklären, was geändert wurde und ob noch
  etwas offen ist.
