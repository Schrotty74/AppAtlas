# AppAtlas Projektkontext

AppAtlas ist eine native SwiftUI-App für macOS zur persönlichen Verwaltung
eines lokalen App-Katalogs.

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
- Aktueller offizieller Release: `1.0.1`.

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
- Backups und iCloud-Kopien werden ausschließlich nach einer ausdrücklichen
  Anweisung des Benutzers erstellt.
- Im festgelegten iCloud-Ordner bleiben höchstens zwei AppAtlas-Backups
  erhalten. Nach einer erfolgreich geprüften neuen Kopie wird dort
  ausschließlich das älteste `AppAtlas-Backup-*.zip` entfernt. Lokale Backups
  und Sicherungen anderer Projekte bleiben unverändert.
- Änderungen nach `1.0.1` bleiben als unveröffentlichter
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
  Automatische Übernahmen benötigen mindestens `0,90` sowie `0,12` Abstand
  zum zweitbesten Treffer. Werte ab `0,75` werden ausschließlich zur Prüfung
  vorgeschlagen; schwächere Treffer werden verworfen.
- Bestätigte Domains, GitHub-Repositories und Apple-Store-IDs werden nur lokal
  in den Benutzereinstellungen gelernt und niemals exportiert.
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
- AppAtlas steht unter GPLv3.
- Backups werden nur auf ausdrückliche Anweisung erstellt.
