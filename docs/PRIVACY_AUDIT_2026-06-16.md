# Datenschutzaudit für AppAtlas 1.1.0

Dieses Audit dokumentiert den finalen Release AppAtlas `1.1.0` vom
16. Juni 2026 und ergänzt die bisherigen Prüfberichte.

## Ergebnis

Die Prüfung war erfolgreich:

- Keine persönlichen Kataloge, Scanlisten oder Importdateien
- Keine lokalen Benutzer- oder Volume-Pfade
- Keine realen Seriennummern, Lizenzschlüssel oder Passwörter
- Keine persönlichen App-Listen oder Datenbankdateien
- Keine Backups oder lokalen Release-Artefakte im Git-Repository
- Tags, Backup-Erinnerung und Statistik werden lokal verarbeitet
- Private Lizenzwerte bleiben ausschließlich im macOS-Schlüsselbund
- Die Katalogstatistik liest keine Lizenzwerte aus dem Schlüsselbund

## Geprüfte Bereiche

- Veröffentlichter Quellcode und vollständige erreichbare Git-Historie
- Kompilierte App, DMG und ZIP für Version 1.1.0
- App-Binary und Paketinhalt auf persönliche Pfade und sensible Dateitypen
- Bundle-Version, Ad-hoc-Signatur und SHA-256-Prüfsummen

## Geltungsbereich

Das Ergebnis gilt für AppAtlas 1.1.0 und die dazu veröffentlichten
Release-Dateien. Jede weitere finale Version erhält einen ergänzenden
chronologischen Prüfbericht.
