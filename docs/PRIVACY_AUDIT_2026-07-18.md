# Datenschutzaudit für AppAtlas 1.2.2

Dieses Audit dokumentiert den finalen Release AppAtlas `1.2.2` vom
18. Juli 2026.

## Geprüft

- Quellcode und Dokumentation
- Aktueller Git-Status und aktuell verfolgte Dateien
- Datenschutzprüfung mit `Scripts/privacy-check.sh`
- Erweitertes Datenschutzaudit mit `Scripts/privacy-audit.sh`

## Ergebnis

- Die aktuelle Datenschutzprüfung war erfolgreich.
- Das erweiterte Datenschutzaudit einschließlich Git-Historie war erfolgreich.
- In den aktuell verfolgten Dateien sind keine persönlichen Kataloge,
  Scanlisten, Lizenzexporte, Datenbanken, DMG-, ZIP- oder Backup-Artefakte
  enthalten.
- Der neue Setapp-Katalog wird ausschließlich nach dem bewussten Start von
  „Online-Daten aktualisieren“ geladen. Er enthält nur öffentliche
  Katalogmetadaten und wird getrennt im lokalen Application-Support-Ordner
  gespeichert.
- Der schnelle Scan verwendet ausschließlich diesen lokalen Cache und startet
  keine Setapp-Netzwerkabfrage.
- Der Final-Release-Workflow führt vor Veröffentlichung zusätzlich den
  Datenschutzcheck für das erzeugte Release-Paket aus.

## Bewertung

Der Release-Arbeitsbaum ist nach der lokalen Datenschutzprüfung sauber.
Das erweiterte Audit blockiert weiterhin private Kataloge, Scanlisten,
Datenbanken, Lizenzexporte, persönliche Pfade und Geheimnisse.

## Hinweis

AppAtlas speichert Lizenzdaten weiterhin ausschließlich im macOS-Schlüsselbund.
Der Export nimmt Lizenzdaten nur nach ausdrücklicher Auswahl des Benutzers auf.
