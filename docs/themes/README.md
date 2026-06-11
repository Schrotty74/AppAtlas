# Benutzerdefinierte AppAtlas-Themes

AppAtlas verwendet ein eigenes, auf die Oberfläche der App zugeschnittenes
Themeformat:

```json
{
  "format": "appatlas-theme",
  "version": 1
}
```

## Verwendete Felder

- `name`: deutscher und/oder englischer Anzeigename
- `mode`: `light` oder `dark`
- `colors.text`: normale Textfarbe
- `colors.mutedText`: zurückhaltende Textfarbe
- `colors.background`: Haupt-Hintergrund
- `colors.backgroundAlt`: zweite Hintergrundfarbe
- `colors.panel`: Karten und größere Flächen
- `colors.panelSoft`: zurückhaltende Flächen
- `colors.border`: Rahmen und Trennlinien
- `colors.accent`: Akzentfarbe
- `colors.accentText`: Text auf der Akzentfarbe
- `effects.glassOpacity`: Deckkraft von Flächen
- `effects.glassBorderOpacity`: Stärke transparenter Rahmen
- `effects.shadowOpacity`: Stärke der Schatten

Optionale Felder dürfen weggelassen werden. Farben werden als sechsstellige
Hex-Werte wie `#6F92FF` angegeben. Effektwerte liegen zwischen `0` und `1`.

## Import, Export und Löschen

Das Theme-Menü enthält:

- `Theme importieren`
- `Theme exportieren`
- `Theme löschen`

Eingebaute Themes können exportiert werden. Dabei entsteht eine bearbeitbare
Kopie mit eigener ID. Nur importierte Themes können gelöscht werden. Beim
erneuten Import derselben eigenen Theme-ID wird das vorhandene Theme ersetzt;
eingebaute IDs bleiben geschützt.

Ältere Theme-Dateien aus UroBilanz können importiert werden. AppAtlas übernimmt
dabei ausschließlich die oben beschriebenen allgemeinen Darstellungswerte und
speichert sie anschließend im eigenen `appatlas-theme`-Format.

## Dateien

- `appatlas-theme-template.json`: Vorlage für ein eigenes Theme
- `example-custom-theme.json`: vollständiges Beispieltheme
