# Release-Workflow

AppAtlas verwendet drei Stufen:

- `dev`: lokaler Arbeitsstand fuer taegliche Entwicklung
- `beta`: stabiler Teststand in Git
- `main`: veroeffentlichter Final-Stand in Git

Wichtig: `dev` bleibt lokal. Nicht jede Dev-Version wird committed oder
gepusht. Erst wenn aus dem aktuellen lokalen Dev-Stand eine Beta erstellt
wird, wird daraus ein Git-Commit auf `beta`.

Die Xcode-Schemes sind passend dazu eingerichtet:

- `AppAtlas Dev` baut `Dev`
- `AppAtlas Beta` baut `Beta`
- `AppAtlas Final` baut `Final`

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
3. baut das Xcode-Scheme `AppAtlas Beta`,
4. erzeugt ZIP, DMG und SHA256-Dateien fuer Beta,
5. speichert ZIP und DMG dauerhaft im Backup-Ordner,
6. erstellt aus dem aktuellen Dev-Arbeitsbaum einen Commit auf `beta`,
7. pusht `beta` automatisch nach GitHub.

Die Beta-Version wird als Parameter uebergeben. Ohne Parameter verwendet das
Skript die `MARKETING_VERSION` aus dem Projekt. Es wird keine lokale
`beta.local`-Version erzeugt.

`dev` wird dabei nicht veraendert und nicht gepusht.

## Beta als Final veröffentlichen

```sh
./Scripts/publish-beta-as-final.sh
```

Das Skript:

1. verlangt einen sauberen Git-Arbeitsstand,
2. wechselt auf `beta`,
3. übernimmt `beta` per Fast-Forward nach `main`,
4. baut das Xcode-Scheme `AppAtlas Final`,
5. erzeugt ZIP, DMG und SHA256-Dateien fuer Final,
6. speichert ZIP und DMG dauerhaft im Backup-Ordner,
7. pusht `main` automatisch nach GitHub.

`beta` wird dabei nicht verändert.

## Schutzregel

`create-beta-from-dev.sh` wechselt keine Branches und verwendet kein Stash oder
Merge. Der Beta-Commit wird direkt aus dem aktuellen Dev-Arbeitsbaum erstellt.

`publish-beta-as-final.sh` verwendet `git merge --ff-only`. Wenn `main` und
`beta` auseinanderlaufen, bricht das Skript ab, statt automatisch einen
unsauberen Mischstand zu erzeugen.

Ignorierte private Dateien werden nicht in den Beta-Snapshot aufgenommen.
