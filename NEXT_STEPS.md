# Nächste Schritte

## Aktueller Stand

- Aktuelle Release-Serie: `1.2`.
- Aktueller offizieller Release: `1.2.0`.
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
- Bereits gespeicherte automatisch bezogene Beschreibungen werden nach einem
  bewussten Sprachwechsel für die lokale Apple-Übersetzung eingeplant,
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
- Import und Export, Theme-Dateien, Lizenzdateien und manuell gewählte Icons
  nutzen einen gemeinsamen geschützten Dateizugriff.
- Lizenzimporte werden vor dem Speichern in einer Vorschau geprüft. Angezeigt
  werden nur zugeordnete App-Namen und Summen, keine privaten Lizenzwerte.
- Dialoge, Dateiauswahlen und Bestätigungen der Hauptansicht werden über einen
  zentralen Zustand gesteuert; die fachlichen Import-/Exportabläufe sind aus
  der Hauptansicht in eigene Dienste ausgelagert.
- Die Katalogdatei wird vor und nach dem Schreiben validiert. Bei einer
  beschädigten Hauptdatei kann AppAtlas automatisch die letzte gültige
  Fassung wiederherstellen und bewahrt die beschädigte Datei zur Diagnose auf.
- Der Scan-Abgleich ist als eigener indexierter Dienst umgesetzt und schützt
  manuell gesetzte Metadaten. Feste Ablauf- und Leistungstests decken große
  Kataloge, Wiederherstellung und zentrale Benutzerabläufe ab.
- Die Sidebar verwendet ausschließlich echte gespeicherte Ordnerpfade und
  behandelt Dateinamen nicht mehr als Unterordner. Ordnerauswahlen setzen den
  Filter explizit, sodass Zähler und angezeigte Apps übereinstimmen.
- Der Lizenzimport erkennt Versions- und Verpackungszusätze zuverlässiger,
  führt doppelte Lizenzzeilen zusammen und kann fehlende App-Store- oder
  Lizenz-Apps nach bewusster Auswahl als manuelle Einträge unter „Lizenzen“
  anlegen. Private Lizenzwerte bleiben ausschließlich im Schlüsselbund.
- Ein vollständiger Scan gleicht neue, geänderte und entfernte lokale Dateien
  mit dem Katalog ab. Dateigröße und Änderungsdatum werden aktualisiert;
  manuelle Einträge ohne lokale Datei bleiben erhalten.
- Zusätzliche Ausschlussordner lassen sich in den Einstellungen als
  Ordnername oder relativer Pfad verwalten. Lokale Ordner können außerdem
  direkt ausgewählt werden und werden unabhängig von der Scanquelle ausgelassen.
- Eigene Dateiendungen können ebenfalls lokal vom Scan ausgeschlossen werden.
- Lokale `.app`-Icons werden direkt beim Scan gelesen. Bei einer bewussten
  Online-Aktualisierung werden zunächst eindeutig passende installierte Apps
  geprüft; Onlinebilder benötigen höhere Auflösung und icon-typische Pfade.
  Screenshots, Vorschauen und Banner werden abgewiesen.
- Eine gemeinsame Vertrauensbewertung für
  Apple, GitHub, Websuche und Reddit berücksichtigt Namen, Kategorie,
  Unterordner, Hersteller, Bundle-ID und bestätigte Quellen. Unsichere oder
  mehrdeutige Treffer werden nicht automatisch übernommen.
- Unter macOS 26 verwendet die Oberfläche für Sidebar-Auswahl, Kategorie-
  Elemente, Theme-Menü und App-Karten automatisch natives Liquid Glass.
  Ältere Systeme verwenden unverändert die bisherigen Theme-Flächen.

## Offene Aufgaben

- Rückmeldungen zu Version 1.2.0 sammeln und priorisieren.
- Metadaten-Zuordnungen mit unterschiedlich und ähnlich benannten Apps weiter
  praktisch prüfen.
- Scanner-Erkennung als nächster Schwerpunkt:
  schneller Scan bleibt lokal und darf nicht durch Online-Abfragen blockieren.
  Er soll aber weiter über eine lokale Wissensdatenbank ausgebaut werden,
  inklusive zusätzlicher bekannter App-Namen, Varianten und späterer
  Icon-Quellen.
- Die Trefferbewertung soll mit diesen Schwellen arbeiten:
  `automaticThreshold = 0.80`, `reviewThreshold = 0.65` und
  `minimumAutomaticMargin = 0.08`.
- Homebrew-Cask-Katalog nicht live im schnellen Scan abfragen, sondern bei
  bewusster Online-Aktualisierung herunterladen, lokal cachen und danach als
  schnelle strukturierte Wissensquelle verwenden. Der Cache wird beim
  bewussten Online-Lauf aktualisiert und danach lokal beim schnellen Abgleich
  genutzt.
- Weitere strukturierte Quellen wie Setapp, GitHub, App Store und gegebenenfalls
  MacUpdater-ähnliche Exportdaten nur gezielt und nach klarer Priorität nutzen:
  zuerst lokale und gecachte Quellen, danach Online-Quellen. Nicht blind pro App
  Websuche starten.
- Nachbearbeitung unklarer Apps weiter praktisch prüfen und bei Bedarf
  verfeinern.

## Verbindliche Regeln

- Datenschutz geht vor Funktionalität.
- Keine persönlichen Daten, App-Namen, Kataloge, Lizenzdaten oder lokalen
  Pfade in Git, Builds oder öffentlichen Dokumenten.
- Bei Datenschutzfragen vor der Umsetzung informieren und eine
  datensparsame Alternative vorschlagen.
- Keine Backups ohne ausdrückliche Anweisung.
- In iCloud maximal zwei AppAtlas-Backups behalten; nach einer erfolgreichen
  neuen Kopie ausschließlich das älteste AppAtlas-iCloud-Backup entfernen.
- Keine Release-ZIPs oder Prüfsummen ohne ausdrückliche Anweisung.
- AppAtlas bei Builds und Tests niemals automatisch öffnen oder in den
  Vordergrund bringen.
- Keine lokalen Benutzer- oder Volume-Pfade und keine Nutzerdaten in
  Quellcode, Binärdateien, Release-Pakete, Backups oder GitHub aufnehmen.
- Keine Pushes, Tags, GitHub-Releases oder neuen Beta-Builds ohne ausdrückliche
  Anweisung.
- Umfangreiches Datenschutzaudit und ergänzenden öffentlichen Prüfbericht bei
  jeder finalen Version erstellen, nicht bei Betas. Frühere Prüfberichte
  dauerhaft als chronologische Audit-Historie behalten.
