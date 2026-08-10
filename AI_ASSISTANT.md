# App-Assistent

Hinweis: Dieses Dokument beschreibt nur die App-Funktion. Fuer den aktuellen
Projektstand zuerst `PROJECT_CONTEXT.md` und `NEXT_STEPS.md` lesen.

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

## Weiterer Projektkontext

Der verbindliche Build- und Release-Ablauf steht ausschliesslich in
`docs/RELEASE_WORKFLOW.md`. Datenschutz- und Veroeffentlichungsregeln stehen
in `docs/PRIVACY.md` und `PROJECT_CONTEXT.md`.
