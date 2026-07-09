# AppAtlas Anleitung

AppAtlas ist eine native macOS-App, mit der du deine persönliche App-Sammlung lokal erfassen, ordnen und sichern kannst. Die App arbeitet datenschutzorientiert: Ein Scan liest ausgewählte Ordner nur aus. Online-Daten werden nicht automatisch geladen, sondern erst, wenn du die Aktualisierung bewusst startest.

Diese Anleitung führt dich durch die erste Einrichtung und die wichtigsten Funktionen.

## 1. Voraussetzungen

- macOS 14 oder neuer.
- macOS 15 oder neuer, wenn du Apples lokale Übersetzungsfunktion nutzen möchtest.
- Für Entwicklerinnen und Entwickler: Swift 6.

## 2. App zum ersten Mal öffnen

Wenn macOS beim ersten Start eine Sicherheitswarnung zeigt, liegt das daran, dass AppAtlas nicht mit einem kostenpflichtigen Apple Developer Account notarisiert ist.

So öffnest du AppAtlas trotzdem:

1. Rechtsklick auf die App.
2. **Öffnen** wählen.
3. Im Dialog erneut **Öffnen** oder **Trotzdem öffnen** bestätigen.

Alternativ kannst du in **Systemeinstellungen → Datenschutz & Sicherheit** unten **Trotzdem öffnen** bestätigen.

## 3. Ersten Katalog erstellen

Beim ersten Start ist der Katalog leer. Du hast zwei Möglichkeiten:

### Ordner scannen

1. Klicke auf **Ordner scannen**.
2. Wähle einen lokalen Ordner aus, in dem deine Apps oder App-Dateien liegen.
3. AppAtlas liest den Ordner ein und erstellt daraus lokale Katalogeinträge.
4. Prüfe anschließend die gefundenen Apps.

Der Scan verändert den ausgewählten Ordner nicht. Dateien werden nur gelesen.

### Vorhandenen Katalog importieren

1. Klicke auf **Katalog importieren**.
2. Wähle eine AppAtlas-JSON-Datei aus.
3. Bei geschützten Exporten gib das passende Passwort ein.

Wichtig: Beim Import wird der vorhandene Katalog ersetzt.

## 4. Apps verwalten

Nach dem Scan kannst du deine Apps bearbeiten und ergänzen.

Typische Aufgaben:

- **App hinzufügen**: Einen Eintrag manuell erstellen.
- **Bearbeiten**: Name, Beschreibung, Kategorie, Link, Tags oder Icon anpassen.
- **Aus Katalog löschen**: Nur den Katalogeintrag entfernen.
- **Lokale Dateien in Papierkorb legen**: Zugeordnete lokale Dateien nach ausdrücklicher Bestätigung in den macOS-Papierkorb verschieben.

AppAtlas bietet kein dauerhaftes Löschen lokaler Dateien an. Wenn Dateien in den Papierkorb gelegt werden, kannst du sie dort wiederherstellen.

## 5. Suchen, filtern und Ansichten wechseln

AppAtlas bietet mehrere Wege, große Sammlungen übersichtlich zu halten:

- Suche nach Apps, Kategorien und Dateinamen.
- Filter über Tags und Sidebar.
- Hierarchische Kategorien und Unterordner.
- Verschiedene Layouts: klassische Ansicht, Fokusansicht, Kompaktansicht, Dashboard und Regale.
- Katalogstatistik mit Kategorien, Speicherbedarf und fehlenden Metadaten.

Nutze die Suche, wenn du schnell eine App finden willst. Nutze Kategorien und Tags, wenn du deine Sammlung dauerhaft strukturieren möchtest.

## 6. Online-Daten aktualisieren

AppAtlas kann fehlende Icons, Beschreibungen und Links ergänzen.

So funktioniert es:

1. Klicke auf **Online-Daten aktualisieren**.
2. AppAtlas sucht bewusst nach passenden Metadaten.
3. Unsichere Treffer landen mit Quellenangabe unter **Zu prüfen**.
4. Bestätige oder verwerfe die Vorschläge.

Das bloße Scannen oder Anzeigen deines Katalogs startet keine Online-Abfrage.

Bei Online-Abfragen können Suchbegriffe wie der normalisierte App-Name und ein allgemeiner Kategoriehinweis an Dienste wie iTunes, GitHub, Reddit r/macapps oder DuckDuckGo gesendet werden. Lokale Dateipfade, Katalogstruktur und Lizenzdaten werden dabei nicht übertragen.

## 7. App-Assistent verwenden

Der **App-Assistent** hilft dir, deinen lokalen Katalog zu befragen. Du kannst ihn zum Beispiel nutzen für:

- „Welche Apps haben noch keine Beschreibung?“
- „Welche Apps fehlen in einer Kategorie?“
- „Welche Einträge sollte ich prüfen?“
- „Welche Apps wirken doppelt oder ähnlich?“

Die normale Kataloganalyse läuft lokal. Wenn du die optionale Internetrecherche aktivierst, wird deine eingegebene Frage an die Reddit-Suche in r/macapps und r/macos gesendet. Dein Katalog, lokale Dateipfade und Lizenzdaten werden dabei nicht mitgesendet.

## 8. Lizenzdaten verwalten

AppAtlas kann Lizenzinformationen zu Apps speichern.

Mögliche Lizenzdaten sind zum Beispiel:

- Seriennummern.
- registrierte E-Mail-Adressen.
- Lizenztypen.
- private Notizen.

Private Lizenzdaten werden im macOS-Schlüsselbund gespeichert. Beim normalen Katalogexport sind Schlüsselbunddaten nicht enthalten. Du kannst Lizenzdaten bewusst importieren oder beim Export ausdrücklich mit aufnehmen.

Lizenzdaten können aus JSON- oder CSV-Dateien importiert werden. Die Importdatei wird nicht in AppAtlas gespeichert und nicht an Onlinedienste übertragen.

## 9. Katalog exportieren und sichern

Du solltest deinen Katalog regelmäßig exportieren, damit deine lokalen Daten gesichert sind.

So exportierst du deinen Katalog:

1. Öffne **App-Aktionen**.
2. Wähle **Katalog exportieren …**.
3. Entscheide, ob Lizenzdaten enthalten sein sollen.
4. Wähle bei Bedarf einen passwortgeschützten Export.
5. Speichere die JSON-Datei an einem sicheren Ort.

Exportoptionen:

- ohne Lizenzdaten,
- mit Lizenzdaten unverschlüsselt,
- mit Lizenzdaten passwortgeschützt.

Der passwortgeschützte Export verwendet AES-256-GCM. Unverschlüsselte Exporte mit Lizenzdaten sollten nur verwendet werden, wenn du die Datei wirklich sicher ablegst.

AppAtlas kann dich an regelmäßige Katalogexporte erinnern.

## 10. Themes verwenden

AppAtlas unterstützt eigene Themes.

Du kannst:

- Themes importieren,
- das aktuell ausgewählte Theme exportieren,
- eigene Themes löschen,
- mitgelieferte Beispielthemes als Vorlage nutzen.

Ab macOS 26 nutzt AppAtlas native Liquid-Glass-Effekte für Bedienelemente und Karten. Auf älteren macOS-Versionen bleibt die Darstellung kompatibel.

## 11. Website-Ausschlussliste

Wenn AppAtlas bei bestimmten Apps nicht mehr nach einer Website fragen soll, kannst du die **Website-Ausschlussliste** verwenden.

Das ist praktisch, wenn:

- eine App keine sinnvolle Website hat,
- ein Treffer dauerhaft falsch ist,
- du bestimmte Webseiten bewusst nicht zuordnen möchtest.

## 12. Fehler melden

AppAtlas enthält einen datensparsamen Fehlerbericht.

So nutzt du ihn:

1. Öffne **App-Aktionen**.
2. Wähle **Fehler melden**.
3. Kopiere den Bericht in eine E-Mail oder in Codex.

Fehlerberichte und Fragen können an **appatlas@mailbox.org** gesendet werden.

## 13. Datenschutz kurz erklärt

AppAtlas ist auf lokale Nutzung ausgelegt.

Wichtig:

- Persönliche Kataloge liegen lokal im Application-Support-Verzeichnis der macOS-Sandbox.
- Icons und Vorschaubilder werden lokal gespeichert.
- Scan-Ordner werden beim Scannen nur gelesen.
- Lizenzdaten liegen im macOS-Schlüsselbund.
- Standardexporte enthalten keine Schlüsselbunddaten.
- Online-Abfragen passieren nur nach bewusster Aktion.
- Eine absolute Aussage „AppAtlas sendet niemals irgendetwas“ wäre falsch, weil bewusst gestartete Online-Aktualisierungen, Internetrecherchen und Webseitenaufrufe Netzwerkverbindungen benötigen.

## 14. Empfohlener Einstieg

Wenn du AppAtlas zum ersten Mal nutzt, ist dieser Ablauf sinnvoll:

1. App öffnen.
2. **Ordner scannen** wählen.
3. Gefundene Apps kurz prüfen.
4. Wichtige Apps mit Tags und Kategorien versehen.
5. Fehlende Daten bewusst über **Online-Daten aktualisieren** ergänzen.
6. Unsichere Treffer unter **Zu prüfen** kontrollieren.
7. Lizenzdaten nur bei Bedarf ergänzen.
8. Katalog exportieren und sicher ablegen.

## 15. Hilfe mit KI

Du kannst diese Anleitung auch in ChatGPT, Claude, Gemini oder eine andere KI einfügen und dir den Einstieg erklären lassen.

Beispiel-Prompt:

```text
Ich nutze AppAtlas auf macOS. Bitte erkläre mir diese Anleitung kurz und praktisch.

Hilf mir besonders bei:
1. erster Einrichtung,
2. Ordner-Scan,
3. Online-Daten aktualisieren,
4. Lizenzdaten,
5. Katalogexport und Backup.

Antworte Schritt für Schritt und ohne Marketing-Sprache.
```

## 16. Weitere Dokumentation

- [README](README.de.md)
- [Theme-Dokumentation](docs/themes/README.md)
- [Projektstruktur](docs/PROJECT_STRUCTURE.md)
- [Datenschutzdetails](docs/PRIVACY.md)
- [Release-Workflow](docs/RELEASE_WORKFLOW.md)
