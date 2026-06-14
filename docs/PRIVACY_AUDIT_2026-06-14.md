# Datenschutzaudit für AppAtlas 1.0.0

Dieses Audit dokumentiert den finalen Release AppAtlas `1.0.0` vom
14. Juni 2026 und ergänzt den Prüfbericht vom 13. Juni 2026.

## Ergebnis

Die Prüfung war erfolgreich:

- Keine persönlichen Kataloge, Scanlisten oder Importdateien in Git oder im
  Release-Paket
- Keine lokalen Benutzer- oder Volume-Pfade im Quellcode, App-Binary oder DMG
- Keine realen Seriennummern, Lizenzschlüssel oder Passwörter
- Keine persönlichen App-Listen, Katalogdateien, CSV-, TSV- oder
  Datenbankdateien
- Keine Backups oder lokalen Release-Artefakte im Git-Repository
- Private Lizenzwerte bleiben ausschließlich im macOS-Schlüsselbund
- Neue Benutzer starten mit einem leeren Katalog

Öffentliche Theme-JSON-Dateien enthalten ausschließlich allgemeine
Darstellungswerte. Tests verwenden nur künstliche Testdaten.

## Geprüfte Bereiche

- Alle veröffentlichten und für Version 1.0.0 vorgesehenen Dateien
- Vollständige erreichbare Git-Historie
- Kompilierte App und signiertes DMG
- Dateinamen, App-Binary und Paketinhalt auf persönliche Pfade und sensible
  Dateitypen
- Direkte Netzwerkzugriffe und deren dokumentierte Auslöser
- Prüfsumme, Signatur und Bundle-Version des Release-Pakets

## Netzwerkzugriffe

AppAtlas besitzt keinen eigenen Server, kein Benutzerkonto, keine Telemetrie
und keine Analysefunktion. Netzwerkzugriffe erfolgen ausschließlich nach
bewussten Aktionen:

| Aktion | Ziel | Übertragene Anwendungsdaten |
| --- | --- | --- |
| „Katalog aktualisieren“ | Apple, GitHub, Reddit und DuckDuckGo | normalisierter App-Name und gegebenenfalls allgemeiner Kategoriehinweis |
| Gespeicherte Webseite prüfen | bestätigte Herstellerseite | normaler Webseitenaufruf ohne Katalog- oder Lizenzdaten |
| Assistent mit Internetrecherche | Reddit r/macapps und r/macos | eingegebene Frage |
| Link öffnen | ausgewählte Webseite | normaler Browseraufruf |

Lokale Dateipfade, vollständige Kataloge und Lizenzwerte werden dabei nicht
übertragen. Technisch notwendige Verbindungsdaten wie die IP-Adresse sind bei
Netzwerkaufrufen für den jeweiligen Anbieter sichtbar.

## Technische Schutzmaßnahmen

- Persönliche Datenformate, Builds und Backups werden durch `.gitignore`
  ausgeschlossen.
- Datenschutzprüfungen blockieren persönliche Pfade und sensible Dateien vor
  Commit, Push und Release.
- Das erweiterte Audit prüft zusätzlich die Git-Historie.
- Der Release-Build entfernt private Toolchain-Pfade und verweigert Pakete mit
  lokalen Benutzer- oder Volume-Pfaden.
- Kataloge und Icons werden ausschließlich im lokalen Application Support
  gespeichert; Lizenzwerte liegen im Schlüsselbund.

## Geltungsbereich

Das Ergebnis gilt für AppAtlas 1.0.0 und die dazu veröffentlichten
Release-Dateien. Absolute Sicherheit für spätere Änderungen oder externe
Dienste kann nicht zugesichert werden. Jede weitere finale Version erhält
einen ergänzenden chronologischen Prüfbericht.
