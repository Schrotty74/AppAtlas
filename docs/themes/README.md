# Benutzerdefinierte AppAtlas-Themes

AppAtlas verwendet ein eigenes, auf die Oberfläche der App zugeschnittenes
Themeformat:

```json
{
  "format": "appatlas-theme",
  "version": 1
}
```

## Eigenes Theme erstellen

1. [`appatlas-theme-template.json`](appatlas-theme-template.json)
   herunterladen oder kopieren.
2. Eine eindeutige `id` aus Kleinbuchstaben, Zahlen und Bindestrichen setzen.
3. Namen, Modus, Farben und optionale Effekte anpassen.
4. Die Datei als JSON speichern.
5. In AppAtlas das Theme-Menü öffnen und `Theme importieren` wählen.

Als Ausgangspunkt steht außerdem ein
[vollständiges Beispieltheme](example-custom-theme.json) bereit.

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

### Pflichtfelder

- `format`: muss `appatlas-theme` sein
- `version`: aktuell `1`
- `id`: eindeutige ID, beispielsweise `my-custom-theme`
- mindestens einer der Namen `name.de` oder `name.en`
- `mode`: `light` oder `dark`
- `colors.text`, `colors.background`, `colors.panel` und `colors.accent`

Eingebaute Theme-IDs wie `system`, `classic-light` oder `classic-dark` dürfen
nicht für eigene Themes verwendet werden.

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

## Datenschutz

Themes enthalten ausschließlich Darstellungswerte. App-Kataloge, lokale Pfade,
Icons, Lizenzdaten und andere persönliche Daten gehören nicht in Theme-Dateien.

## Fehlerbehebung

- Import nicht möglich: JSON-Syntax und Pflichtfelder prüfen.
- Theme-ID ungültig: ausschließlich Kleinbuchstaben, Zahlen und Bindestriche
  verwenden.
- Farbe ungültig: sechsstelligen Hex-Wert mit führendem `#` verwenden.
- Effekt ungültig: Wert zwischen `0` und `1` verwenden.

## Dateien

- `appatlas-theme-template.json`: Vorlage für ein eigenes Theme
- `example-custom-theme.json`: vollständiges Beispieltheme
