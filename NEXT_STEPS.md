# Nächste Schritte

## Aktueller Stand

Stand: 23. Juli 2026.

- Der oeffentliche Final-Stand ist `1.2.2`.
- Die aktuelle App-Funktionalitaet, Architektur und verbindlichen Regeln
  stehen in `PROJECT_CONTEXT.md`; diese Datei wiederholt sie bewusst nicht.
- Homebrew-Cask, Setapp, App-Store-Links und die CI-Pruefung sind bereits
  umgesetzt und keine offenen Aufgaben.

## Offene Aufgaben

- **Prioritaet 1:** Rueckmeldungen zum aktuellen Final sammeln und nur
  nachvollziehbare Probleme priorisieren.
- **Prioritaet 2:** Metadaten-Zuordnungen bei unterschiedlich oder aehnlich
  benannten Apps praktisch pruefen und unklare Treffer im Review-Bereich
  verfeinern.
- **Prioritaet 3:** Die lokale Scanner-Erkennung mit weiteren bekannten
  App-Namen und Varianten ausbauen, ohne den schnellen Offline-Scan durch
  Netzwerkzugriffe zu blockieren.
- **Prioritaet 4:** Die bestehende Vertrauensbewertung praktisch pruefen:
  automatische Uebernahme ab `0.80`, Review ab `0.65` und Mindestabstand
  `0.08` zum zweitbesten Treffer.

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
