# Nächste Schritte

## Aktueller Stand

- Aktuelle Release-Serie: `1.0`.
- Aktueller offizieller Beta-Release: `1.0.0-beta.1`.
- Alle danach umgesetzten Änderungen sind unveröffentlicht und bleiben für
  eine spätere, ausdrücklich freigegebene Version erhalten.
- Native SwiftUI-App mit leerem Erststart.
- Lokaler Katalog, freie Ordnerauswahl, manuelle Bearbeitung und Löschung.
- Scanner mit Ausschlussregeln für technische Daten und Backup-Archive sowie
  vollständiger Einzelauswahl vor der Katalogaufnahme.
- JSON-Katalogimport und -export wahlweise ohne Lizenzdaten, unverschlüsselt
  mit Lizenzdaten oder passwortgeschützt mit Lizenzdaten.
- Bewusst ausgelöste Online-Anreicherung für fehlende Icons, Beschreibungen
  und Links über iTunes, GitHub, Reddit r/macapps, eine Suche nach offiziellen
  Herstellerseiten sowie bereits gespeicherte Homepages.
- Review-Bereich für unsichere Treffer, Quellenangaben, bestätigte URLs und
  lokale Übersetzung fremdsprachiger Beschreibungen.
- Private Lizenzdaten ausschließlich im macOS-Schlüsselbund.
- Theme-System, mehrere Layouts, Icons und lokale Suche.
- Deutsche und englische Oberfläche mit manueller Sprachwahl. Die automatische
  Auswahl verwendet Deutsch für DACH und Englisch für alle anderen Regionen.
- Bereits gespeicherte automatisch bezogene Beschreibungen werden beim Laden
  und nach einem Sprachwechsel für die lokale Apple-Übersetzung eingeplant,
  sofern sie nicht der gewählten Sprache entsprechen. Deutsch ist die
  Zielsprache für DACH beziehungsweise manuell Deutsch, Englisch für alle
  anderen Regionen beziehungsweise manuell Englisch. Manuell gepflegte
  Beschreibungen bleiben geschützt.
- Katalogweite, trennzeichenunabhängige Suche über Namen, Beschreibungen,
  Kategorien, Unterordner und lokale Pfade.
- Die Namenssuche toleriert kleine Tippfehler und fehlende Buchstaben, ohne
  unscharfe Beschreibungstreffer als vermeintliche App-Namen anzuzeigen.
- Aufklappbare Unterkategorien in der Sidebar; das Dashboard öffnet
  App-Details per Klick statt in einer dauerhaften rechten Leiste.
- Die Sidebar bildet beliebig tiefe Quellordner hierarchisch ab. Übergeordnete
  Ordner zeigen auch Apps aus tieferen Ebenen; ein erneuter Scan aktualisiert
  ältere verkürzte Unterkategorien ohne doppelte Katalogeinträge.
- Katalogansichten und Icon-Ladevorgänge reagieren sofort auf Scan-Importe,
  Metadatenänderungen und manuell gewechselte Grafiken, ohne einen Wechsel der
  Ansicht zu erfordern.
- Website-Rückfragen können pro App dauerhaft ausgeschlossen werden. Die
  verwaltbare Website-Ausschlussliste erlaubt spätere Bearbeitung und erneute
  Freigabe der Rückfrage.
- Der Katalogexport öffnet nach der Auswahl des Datenschutzumfangs zuverlässig
  den macOS-Speichern-Dialog zur Auswahl von Dateiname und Zielordner.
- Jede zulässige gefundene Datei bleibt im Katalog vertreten. Unterschiedliche
  Apps mit ähnlichen oder gleichen Namen werden über Ordnergrenzen hinweg
  nicht mehr versehentlich zusammengelegt; mehrere Formate derselben App im
  selben Ordner können weiterhin gemeinsam verwaltet werden.
- Erneute Scans trennen außerdem ältere, fälschlich zusammengeführte
  Katalogeinträge anhand ihrer tatsächlichen Dateipfade wieder auf.
- „Alle Apps“ setzt den Kategorie-Filter zuverlässig zurück. Einzelne Apps
  können direkt aus ihrer Detailansicht aus dem Katalog gelöscht werden.

## Offene Aufgaben

- Scanner-Abgleich für neue, geänderte und entfernte Dateien.
- Optional frei konfigurierbare Ausschlussordner für den Scanner ergänzen.
- Icon-Erkennung weiter verbessern. Sie findet inzwischen mehr passende Icons,
  ist bei einigen Apps aber weiterhin unzuverlässig.
- Rückmeldungen aus der ersten offiziellen Beta sammeln und priorisieren.

## Verbindliche Regeln

- Datenschutz geht vor Funktionalität.
- Keine persönlichen Daten, App-Namen, Kataloge, Lizenzdaten oder lokalen
  Pfade in Git, Builds oder öffentlichen Dokumenten.
- Bei Datenschutzfragen vor der Umsetzung informieren und eine
  datensparsame Alternative vorschlagen.
- Keine Backups ohne ausdrückliche Anweisung.
- Keine Pushes, Tags, GitHub-Releases oder neuen Beta-Builds ohne ausdrückliche
  Anweisung.
