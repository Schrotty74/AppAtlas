# Release-Workflow

AppAtlas verwendet drei dauerhafte Git-Branches:

- `dev`: tägliche Entwicklung
- `beta`: stabiler Teststand
- `main`: veröffentlichter Final-Stand

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

## Beta aus Dev erstellen

```sh
./Scripts/create-beta-from-dev.sh
```

Das Skript:

1. verlangt einen sauberen Git-Arbeitsstand,
2. wechselt auf `dev`,
3. übernimmt `dev` per Fast-Forward nach `beta`,
4. baut das Xcode-Scheme `AppAtlas Beta`.

`dev` wird dabei nicht verändert.

## Beta als Final veröffentlichen

```sh
./Scripts/publish-beta-as-final.sh
```

Das Skript:

1. verlangt einen sauberen Git-Arbeitsstand,
2. wechselt auf `beta`,
3. übernimmt `beta` per Fast-Forward nach `main`,
4. baut das Xcode-Scheme `AppAtlas Final`.

`beta` wird dabei nicht verändert.

## Schutzregel

Beide Übernahme-Skripte verwenden `git merge --ff-only`. Wenn die Branches
auseinanderlaufen, bricht das Skript ab, statt automatisch einen unsauberen
Mischstand zu erzeugen.
