# Nächste Schritte

## Aktueller Stand

Stand: 10. August 2026.

- Der öffentliche Final-Stand ist `1.2.3`.
- Die aktuelle App-Funktionalität, Architektur und projektspezifischen Regeln stehen in `PROJECT_CONTEXT.md`; diese Datei wiederholt sie bewusst nicht.
- Die allgemeinen Arbeits-, Git-, Veröffentlichungs- und Repository-Datenschutzregeln stehen in `AGENTS.md`.
- Homebrew-Cask, Setapp, App-Store-Links und die CI-Prüfung sind bereits umgesetzt und keine offenen Aufgaben.
- Die lokale Erkennung liest bei `.app`-Bundles den offiziellen Bundle-Namen; Produkteditionen bleiben getrennt und werden nicht mehr stillschweigend als Grundversion behandelt.
- Lokale Homebrew-Katalogtreffer erkennen nun auch harmlose numerische Namensanhänge.
- Der lokale Katalogabgleich behandelt zusammengezogene Namen sowie Installationszusätze als Suchvariante, ohne den sichtbaren App-Namen zu verändern.
- Die normale Online-Aktualisierung nutzt für App-Bundles nun eine exakte Bundle-ID-Abfrage beim Mac App Store vor der Namenssuche.
- Bereits bekannte GitHub-Projekte werden in der normalen Online-Aktualisierung ergänzt; unbekannte Projekte bleiben der erweiterten Suche vorbehalten.

## Offene Aufgaben

Zurzeit keine. AppAtlas `1.2.3` ist der abgeschlossene Final-Stand.
Neue Aufgaben entstehen erst durch eine ausdrückliche weitere Anweisung oder
einen nachvollziehbar gemeldeten Fehler.

Bei größeren Änderungen diese Liste aktualisieren. Unbestätigte Ideen werden nicht als offene Aufgabe aufgenommen.
