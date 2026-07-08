# Datenschutzaudit für AppAtlas 1.2.0

Dieses Audit dokumentiert den aktuellen lokalen Stand AppAtlas `1.2.0` vom
6. Juli 2026. Der öffentliche GitHub-Release `v1.2.0` wurde am 5. Juli 2026
veröffentlicht.

## Geprüft

- Quellcode und Dokumentation
- Aktueller Git-Status und aktuell verfolgte Dateien
- Öffentliche GitHub-Release-Metadaten für `v1.2.0`
- Datenschutzprüfung mit `Scripts/privacy-check.sh`
- Erweitertes Datenschutzaudit mit `Scripts/privacy-audit.sh`

## Ergebnis

- Die aktuelle Datenschutzprüfung war erfolgreich.
- Das erweiterte Datenschutzaudit war erfolgreich.
- In den aktuell verfolgten Dateien sind keine persönlichen Kataloge,
  Scanlisten, Lizenzexporte, Datenbanken, DMG-, ZIP- oder Backup-Artefakte
  enthalten.
- Bekannte ältere AppAtlas-Release-, Beta- und Backup-Artefakte unter den
  früheren `Backup/releases/...`-Pfaden werden im Historiencheck als
  öffentliche Release-Artefakte bewertet und blockieren das Audit nicht mehr.
- Der öffentliche GitHub-Release `v1.2.0` enthält die erwarteten Artefakte
  `AppAtlas-1.2.0-macos.dmg`, `AppAtlas-1.2.0-macos.zip` und die zugehörigen
  Prüfsummendateien.
- Die lokalen Release-Artefakte wurden in diesem Durchlauf nicht neu gebaut.

## Bewertung

Der aktuelle Arbeitsbaum ist nach der lokalen Datenschutzprüfung sauber. Das
erweiterte Audit bewertet alte öffentliche AppAtlas-Release-Artefakte in der
Git-Historie als bekannte Altlasten und blockiert weiterhin private Kataloge,
Scanlisten, Datenbanken, Lizenzexporte, persönliche Pfade und Geheimnisse.

## Hinweis

AppAtlas speichert Lizenzdaten weiterhin ausschließlich im macOS-Schlüsselbund.
Der Export nimmt Lizenzdaten nur nach ausdrücklicher Auswahl des Benutzers auf.

Dieses Dokument ist der ergänzende Prüfbericht zum aktuellen Stand.
