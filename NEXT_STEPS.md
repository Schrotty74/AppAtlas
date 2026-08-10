# Nächste Schritte

## Aktueller Stand

Stand: 10. August 2026.

- Der oeffentliche Final-Stand ist `1.2.3`.
- Die aktuelle App-Funktionalitaet, Architektur und verbindlichen Regeln
  stehen in `PROJECT_CONTEXT.md`; diese Datei wiederholt sie bewusst nicht.
- Homebrew-Cask, Setapp, App-Store-Links und die CI-Pruefung sind bereits
  umgesetzt und keine offenen Aufgaben.
- Die lokale Erkennung liest bei `.app`-Bundles den offiziellen Bundle-Namen;
  Produkteditionen bleiben getrennt und werden nicht mehr stillschweigend als
  Grundversion behandelt.
- Lokale Homebrew-Katalogtreffer erkennen nun auch harmlose numerische
  Namensanhaenge.
- Der lokale Katalogabgleich behandelt zusammengezogene Namen sowie
  Installationszusätze als Suchvariante, ohne den sichtbaren App-Namen zu
  veraendern.
- Die normale Online-Aktualisierung nutzt fuer App-Bundles nun eine exakte
  Bundle-ID-Abfrage beim Mac App Store vor der Namenssuche.
- Bereits bekannte GitHub-Projekte werden in der normalen Online-Aktualisierung
  ergänzt; unbekannte Projekte bleiben der erweiterten Suche vorbehalten.

## Offene Aufgaben

Zurzeit keine. AppAtlas `1.2.3` ist der abgeschlossene Final-Stand.
Neue Aufgaben entstehen erst durch eine ausdrückliche weitere Anweisung oder
einen nachvollziehbar gemeldeten Fehler.

Bei groesseren Aenderungen diese Liste aktualisieren. Unbestaetigte Ideen
werden nicht als offene Aufgabe aufgenommen.

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
