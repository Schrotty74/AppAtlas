# Datenschutzaudit für AppAtlas 1.1.1

Dieses Audit dokumentiert den finalen Bugfix-Release AppAtlas `1.1.1` vom
17. Juni 2026.

## Geprüft

- Quellcode und Dokumentation
- Git-Status und veröffentlichbare Dateien
- Git-Historie auf sensible Dateinamen
- Release-Paket für Version 1.1.1

## Ergebnis

- Keine persönlichen Kataloge, Scanlisten oder Lizenzexporte im Repository.
- Keine lokalen Benutzer- oder Volume-Pfade im Quellcode oder Release-Paket.
- Keine Lizenzdaten, Seriennummern oder privaten Importdateien im Release.
- Build-Artefakte und Backups liegen außerhalb der Git-Verfolgung.

## Hinweis

AppAtlas speichert Lizenzdaten weiterhin ausschließlich im macOS-Schlüsselbund.
Der Export nimmt Lizenzdaten nur nach ausdrücklicher Auswahl des Benutzers auf.

Das Ergebnis gilt für AppAtlas 1.1.1 und die dazu veröffentlichten
Release-Dateien.
