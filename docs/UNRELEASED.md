# Unveröffentlichte Änderungen seit AppAtlas 1.0.0-beta.1

Dieser Entwicklungsstand verbessert Katalognavigation, Einzellöschung und die
Trennung ähnlich benannter oder nummerierter Apps. Er ist noch kein Release
und erhält erst nach ausdrücklicher Freigabe eine Versionsnummer.

## Änderungen

- „Alle Apps“ setzt den Kategorie-Filter nun zuverlässig zurück.
- Apps können direkt aus ihrer Detailansicht aus dem Katalog gelöscht werden.
- Jede App-Karte und Listenzeile zeigt eine direkt sichtbare Löschaktion mit
  Bestätigung.
- Beim Löschen kann der Benutzer wählen, ob nur der Katalogeintrag entfernt
  oder dessen zugeordnete lokale Dateien in den macOS-Papierkorb gelegt werden.
  Lokale Dateien werden niemals ohne ausdrückliche Bestätigung verändert.
- Lizenzdaten aus LicenseManager-Exporten können getrennt vom Katalog aus JSON
  oder CSV importiert werden. Sicher zugeordnete Daten landen ausschließlich
  im macOS-Schlüsselbund; unklare Treffer werden übersprungen.
- Der Lizenzimport meldet nun die tatsächlich im Schlüsselbund gespeicherten
  Einträge und einzelne Speicherfehler. Geöffnete Detailansichten aktualisieren
  ihre Lizenzanzeige unmittelbar nach einem erfolgreichen Import.
- Lokale Release-Pakete werden vor Abschluss zusätzlich auf eingebettete
  Benutzer- und Volume-Pfade geprüft. Das Ressourcenpaket wird vollständig in
  die App eingebettet und benötigt keinen lokalen Build-Ordner mehr.
- Die zuvor sehr große `ContentView` wurde in getrennte Komponenten für
  Toolbar, Sheets, Dateiimporte und Bestätigungsdialoge aufgeteilt. Das
  sichtbare Design bleibt unverändert; Kompilierung, Wartbarkeit und
  Erweiterbarkeit werden dadurch stabiler.
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
