# App-Assistent

Stand: 2026-06-08

## Ziel

Der Assistent beantwortet Fragen zum eigenen Katalog, zum Beispiel:

- Mit welcher meiner Apps kann ich Videos erstellen?
- Welche App eignet sich für Screenshots?
- Welche Programme habe ich für Backups?

## Arbeitsweise

1. Die App durchsucht und bewertet immer zuerst nur den lokalen Katalog.
2. Auf macOS 26 kann optional Apples lokales Foundation-Models-Framework
   verwendet werden, sofern Apple Intelligence auf dem Gerät verfügbar und
   aktiviert ist.
3. Auf ausdrücklichen Wunsch sucht die App zusätzlich in Reddit `r/macapps`
   und `r/macos`.
4. Externe Beiträge werden als subjektive Quellen gekennzeichnet und verlinkt.
5. Wenn Apple Intelligence nicht verfügbar ist, bleibt die lokale
   regelbasierte Kataloganalyse funktionsfähig.

## Datenschutz

- Katalogdaten werden standardmäßig lokal verarbeitet.
- Reddit wird nur abgefragt, wenn die Internetoption für die jeweilige Frage
  aktiviert ist.
- Es werden keine lokalen Dateiinhalte oder Dateipfade an Reddit gesendet.
- Die Suchfrage wird für die Reddit-Suche übertragen.

## Grenzen

- Empfehlungen hängen von der Qualität der lokalen Beschreibungen und
  Stichwörter ab.
- Reddit-Beiträge können ungenau, subjektiv oder veraltet sein.
- Das Apple-Modell benötigt unterstützte Hardware, macOS 26 und aktivierte
  Apple Intelligence.
- Eine allgemeine Websuche über weitere Anbieter ist noch nicht integriert.

## Release-Workflow für Codex

- Dev bleibt lokal. Nicht jede Dev-Version committen oder pushen.
- Erst wenn der Benutzer schreibt „Erstelle Beta aus Dev“, wird der aktuelle
  lokale Dev-Stand als Beta übernommen und als Git-Commit auf `beta`
  gespeichert.
- Erst `beta` und `main` werden in Git/GitHub übernommen.
- Wenn der Benutzer schreibt „Erstelle Beta aus Dev“, führe
  `./Scripts/create-beta-from-dev.sh` aus.
- Wenn der Benutzer schreibt „Veröffentliche Beta als Final“, führe
  `./Scripts/publish-beta-as-final.sh` aus.
- Wenn auf einem der Branches `dev`, `beta` oder `main` gebaut werden soll,
  kann `./Scripts/build-current-branch.sh` verwendet werden.
- Vor einem Push bleibt die ausdrückliche Benutzerfreigabe erforderlich.
