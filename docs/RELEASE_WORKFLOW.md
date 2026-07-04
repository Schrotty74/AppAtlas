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
./Scripts/create-beta-from-dev.sh
```

Das Skript:

1. wechselt auf `dev`,
2. sichert den aktuellen lokalen Dev-Stand temporaer, auch uncommitted Dateien,
3. wechselt auf `beta`,
4. uebernimmt committed Dev-Aenderungen per Fast-Forward,
5. uebernimmt den lokalen Dev-Snapshot als neuen Beta-Commit,
6. baut das Xcode-Scheme `AppAtlas Beta`,
7. erzeugt ZIP, DMG und SHA256-Dateien fuer Beta,
8. pusht den Branch `beta` nach GitHub,
9. stellt den lokalen Dev-Arbeitsstand wieder her.

`dev` wird dabei nicht veraendert und nicht gepusht.

Wenn nur der Xcode-Build der Beta-Variante geprüft werden soll, ohne die
aktive Scheme in Xcode manuell umzuschalten:

```sh
./Scripts/build-xcode-beta.sh
```

Dieses Skript verwendet immer explizit `-scheme "AppAtlas Beta"` und
`-configuration Beta`. Es hängt nicht von der aktuell in Xcode ausgewählten
Scheme ab.

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
6. pusht den Branch `main` nach GitHub.

`beta` wird dabei nicht verändert.

## Schutzregel

Beide Übernahme-Skripte verwenden `git merge --ff-only`. Wenn die Branches
auseinanderlaufen, bricht das Skript ab, statt automatisch einen unsauberen
Mischstand zu erzeugen.

Ignorierte private Dateien werden nicht in den Beta-Snapshot aufgenommen.
