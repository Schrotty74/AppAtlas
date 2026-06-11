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
- Erster offizieller Beta-Release: `1.0.0-beta.1`.

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
- Lokale Icons liegen separat als Originale und 256-Pixel-Vorschaubilder in
  Application Support. Der lokale Katalog enthält nur Icon-Referenzen;
  portable Exporte enthalten weiterhin die Originalicons.
- Themes verwenden das Format `appatlas-theme`.
- AppAtlas steht unter GPLv3.
- Backups werden nur auf ausdrückliche Anweisung erstellt.
