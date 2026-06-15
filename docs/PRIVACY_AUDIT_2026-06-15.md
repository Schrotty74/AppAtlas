# Datenschutzaudit für AppAtlas 1.0.1

Dieses Audit dokumentiert den finalen Bugfix-Release AppAtlas `1.0.1` vom
15. Juni 2026 und ergänzt die bisherigen Prüfberichte.

## Ergebnis

Die Prüfung war erfolgreich:

- Keine persönlichen Kataloge, Scanlisten oder Importdateien
- Keine lokalen Benutzer- oder Volume-Pfade
- Keine realen Seriennummern, Lizenzschlüssel oder Passwörter
- Keine persönlichen App-Listen oder Datenbankdateien
- Keine Backups oder lokalen Release-Artefakte im Git-Repository
- Private Lizenzwerte bleiben in der App ausschließlich im
  macOS-Schlüsselbund
- Tests verwenden für Lizenzdaten einen isolierten Arbeitsspeicher

## Geprüfte Bereiche

- Veröffentlichter Quellcode und vollständige erreichbare Git-Historie
- Kompilierte App und DMG für Version 1.0.1
- App-Binary und Paketinhalt auf persönliche Pfade und sensible Dateitypen
- Bundle-Version, Ad-hoc-Signatur und SHA-256-Prüfsumme

## Geltungsbereich

Das Ergebnis gilt für AppAtlas 1.0.1 und die dazu veröffentlichten
Release-Dateien. Jede weitere finale Version erhält einen ergänzenden
chronologischen Prüfbericht.
