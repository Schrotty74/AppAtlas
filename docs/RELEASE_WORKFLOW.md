# Release-Workflow

AppAtlas verwendet drei Stufen:

- `dev`: lokaler Arbeitsstand fuer taegliche Entwicklung
- `beta`: stabiler Teststand in Git
- `main`: veroeffentlichter Final-Stand in Git

Wichtig: Nicht jede Dev-Aenderung wird committed oder gepusht. Erst wenn aus
dem aktuellen Dev-Stand eine Beta erstellt wird, wird daraus ein Git-Commit
auf `beta`.

Xcode wird fuer die taegliche Dev-Arbeit verwendet. Beta und Final laufen ueber
die Release-Skripte:

- `AppAtlas Dev` baut `Dev`
- `create-beta-from-dev.sh` baut und veroeffentlicht Beta
- `publish-beta-as-final.sh` baut und veroeffentlicht Final

Nach einem Final-Release bleibt `Final` auf der veroeffentlichten Version. `Dev`
und `Beta` werden auf die naechste geplante Version erhoeht. Der eigenstaendige
Dev-Build ergaenzt diese Versionsnummer um `-development`; die erste Beta nutzt
`-beta.1` und das Final dieselbe Versionsnummer ohne Zusatz.

Die Varianten haben getrennte Bundle Identifier und dadurch getrennte
macOS-Container, Einstellungen und AppAtlas-Datenordner:

- Final: `at.schrotty.appatlas` -> `Application Support/AppAtlas`
- Beta: `at.schrotty.appatlas.beta` -> `Application Support/AppAtlas-Beta`
- Dev: `at.schrotty.appatlas.dev` -> `Application Support/AppAtlas-Dev`

## Tägliche Entwicklung

```sh
git switch dev
./Scripts/build-current-branch.sh
```

Lokale Aenderungen auf `dev` duerfen uncommitted bleiben. Das ist der normale
Arbeitsmodus.

## Beta aus Dev erstellen

```sh
./Scripts/create-beta-from-dev.sh 1.2.0-beta.3
```

Das Skript:

1. verlangt, dass der aktuelle Branch `dev` ist,
2. bleibt auf `dev` und wechselt keine Branches,
3. baut das Beta-Paket ueber die Release-Skriptlogik,
4. erzeugt ZIP, DMG und SHA256-Dateien fuer Beta,
5. speichert ZIP, DMG, SHA256 und Release Notes unter
   `Backup/releases/beta/<version>/`,
6. erstellt aus dem aktuellen Dev-Arbeitsbaum einen Commit auf `beta`,
7. pusht `beta` automatisch nach GitHub,
8. schreibt englische Release Notes ohne technische Metadaten in eine Datei,
   liest dafuer Commit-Bodies seit dem letzten Beta-Tag und sortiert die
   Eintraege automatisch in `New`, `Fixed`, `Improved` und `Privacy`,
9. erstellt den GitHub-Prerelease automatisch mit ZIP, DMG, SHA256-Dateien
   und den Release Notes.

Die Beta-Version wird als Parameter uebergeben. Ohne Parameter verwendet das
Skript die `MARKETING_VERSION` aus dem Projekt. Es wird keine lokale
`beta.local`-Version erzeugt.

`dev` wird dabei nicht veraendert und nicht gepusht.

## Beta als Final veröffentlichen

```sh
./Scripts/publish-beta-as-final.sh <final-version>
```

Das Skript:

1. verlangt einen sauberen Git-Arbeitsstand,
2. wechselt auf `beta`,
3. übernimmt `beta` per Fast-Forward nach `main`,
4. baut das Final-Paket ueber die Release-Skriptlogik,
5. erzeugt ZIP, DMG und SHA256-Dateien fuer Final,
6. speichert ZIP, DMG und SHA256 unter
   `Backup/releases/final/<version>/`,
7. pusht `main` automatisch nach GitHub.

`beta` wird dabei nicht verändert.

Die Final-Version immer explizit uebergeben. Dadurch bleibt das Final-Paket
unabhaengig davon korrekt, ob die Xcode-Konfiguration fuer Final noch die
zuletzt veroeffentlichte Version anzeigt.

## Schutzregel

`create-beta-from-dev.sh` wechselt keine Branches und verwendet kein Stash oder
Merge. Der Beta-Commit wird direkt aus dem aktuellen Dev-Arbeitsbaum erstellt.

`publish-beta-as-final.sh` verwendet `git merge --ff-only`. Wenn `main` und
`beta` auseinanderlaufen, bricht das Skript ab, statt automatisch einen
unsauberen Mischstand zu erzeugen.

Ignorierte private Dateien werden nicht in den Beta-Snapshot aufgenommen.
