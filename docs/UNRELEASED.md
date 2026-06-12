# Unveröffentlichte Änderungen seit AppAtlas 1.0.0-beta.1

Dieser Entwicklungsstand verbessert Katalognavigation, Einzellöschung und die
Trennung ähnlich benannter oder nummerierter Apps. Er ist noch kein Release
und erhält erst nach ausdrücklicher Freigabe eine Versionsnummer.

## Änderungen

- „Alle Apps“ setzt den Kategorie-Filter nun zuverlässig zurück.
- Apps können direkt aus ihrer Detailansicht aus dem Katalog gelöscht werden.
- Jede App-Karte und Listenzeile zeigt eine direkt sichtbare Löschaktion mit
  Bestätigung.
- Ein erneuter Scan trennt ältere, fälschlich zusammengeführte App-Ausgaben
  anhand ihrer tatsächlichen Dateipfade wieder auf.
- Bereits zusammengeführte Einträge werden nun zusätzlich beim App-Start
  automatisch getrennt; ein erneuter Scan ist dafür nicht mehr erforderlich.
- Theme-Dokumentation, Theme-Vorlage, Beispieltheme und Projektstruktur sind
  direkt auf der GitHub-Startseite verlinkt.
- Die Theme-Dokumentation enthält nun eine Schritt-für-Schritt-Anleitung,
  Pflichtfelder, Datenschutzregeln und Fehlerbehebung.

## Hinweis für bestehende Kataloge

Führe einmal einen erneuten Scan des gewählten App-Ordners durch. Dadurch
werden ältere zusammengeführte Einträge mit unterschiedlichen Dateien wieder
getrennt. Quelldateien werden dabei nicht verändert.

## Datenschutz

Der Release enthält keine persönlichen Kataloge, lokalen Pfade, Scanlisten
oder Lizenzdaten.
