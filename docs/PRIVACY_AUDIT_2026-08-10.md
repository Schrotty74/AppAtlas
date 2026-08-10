# Datenschutzaudit für AppAtlas 1.2.3

Dieses Audit dokumentiert den finalen Release AppAtlas `1.2.3` vom
10. August 2026.

## Geprüft

- Quellcode und Dokumentation
- Aktueller Git-Status und aktuell verfolgte Dateien
- Datenschutzprüfung mit `Scripts/privacy-check.sh`
- Erweitertes Datenschutzaudit mit `Scripts/privacy-audit.sh`
- Signatur, ZIP- und DMG-Prüfsummen des veröffentlichten Final-Pakets
- GitHub-Final-Release mit ZIP, DMG und den zugehörigen Prüfsummen

## Ergebnis

- Die aktuelle Datenschutzprüfung war erfolgreich.
- Das erweiterte Datenschutzaudit einschließlich Git-Historie war erfolgreich.
- Die 135 automatisierten Tests waren erfolgreich.
- Die Signatur des Final-App-Bundles sowie die Prüfsummen von ZIP und DMG
  wurden erfolgreich geprüft.
- Der GitHub-Release `v1.2.3` ist veröffentlicht, kein Entwurf und kein
  Pre-Release. Er enthält ZIP, DMG und beide SHA-256-Prüfsummen.
- In den aktuell verfolgten Dateien sind keine persönlichen Kataloge,
  Scanlisten, Lizenzexporte, Datenbanken, DMG-, ZIP- oder Backup-Artefakte
  enthalten.

## Bewertung

Der Final-Stand erfüllt die dokumentierten Datenschutzregeln. Das erweiterte
Audit blockiert weiterhin private Kataloge, Scanlisten, Datenbanken,
Lizenzexporte, persönliche Pfade und Geheimnisse.

## Hinweis

AppAtlas speichert Lizenzdaten weiterhin ausschließlich im macOS-Schlüsselbund.
Der Export nimmt Lizenzdaten nur nach ausdrücklicher Auswahl des Benutzers auf.
