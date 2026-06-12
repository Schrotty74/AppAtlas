# Projektstruktur

AppAtlas ist als Swift-Package aufgebaut. Persönliche Katalogdaten sind kein
Bestandteil des Repositories.

```text
AppAtlas/
├── Sources/AppAtlas/
│   ├── Assistant/      Lokaler App-Assistent
│   ├── Import/         Import, Namensabgleich und Online-Metadaten
│   ├── Models/         Katalog-, Datei- und Vorschlagsmodelle
│   ├── Resources/      App-Logo, GitHub-Icons und Übersetzungen
│   ├── Scanner/        Rein lesender Ordnerscanner
│   ├── Store/          Lokaler Katalog, Icons, Export und Schlüsselbund
│   ├── Theme/          Theme-Format und Darstellung
│   └── Views/          SwiftUI-Oberfläche, Toolbar und Dialoge
├── Tests/AppAtlasTests/ Automatisierte Tests
├── Packaging/           App-Bundle-Konfiguration und Berechtigungen
├── Scripts/             Build-, Datenschutz- und Release-Helfer
├── docs/
│   ├── releases/        Release-Hinweise
│   └── themes/          Theme-Dokumentation, Vorlage und Beispiel
└── Designvorschlaege/   Frühe Layoutentwürfe
```

## Lokale Daten

Der persönliche Katalog, Icon-Cache und Einstellungen liegen außerhalb des
Repositories im lokalen Application-Support-Verzeichnis. Lizenzdaten liegen im
macOS-Schlüsselbund. Typische Katalog-, Export-, CSV-, TSV- und
Datenbankdateien werden durch Git-Regeln und Prüfungen vor Commit und Push
blockiert.

## Wichtige Einstiegspunkte

- `Sources/AppAtlas/AppAtlasApp.swift`: App- und Menüstart
- `Sources/AppAtlas/Store/CatalogStore.swift`: zentraler Katalogzustand
- `Sources/AppAtlas/Scanner/VolumeScanner.swift`: Ordnerscan
- `Sources/AppAtlas/Theme/ThemeSystem.swift`: Theme-Format
- `Sources/AppAtlas/Views/ContentView.swift`: Hauptoberfläche
- `Sources/AppAtlas/Views/ContentToolbar.swift`: Toolbar und App-Aktionsmenü
- `Sources/AppAtlas/Views/ContentPresentations.swift`: Sheets, Dateiimporte
  und Bestätigungsdialoge
- `docs/PRIVACY.md`: Datenschutzregeln
