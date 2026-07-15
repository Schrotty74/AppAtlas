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
3. AppAtlas sucht nach APP, DMG, PKG, ZIP, ISO, APK und EXE.
4. Prüfe anschließend alle Vorschläge. Du kannst einzelne Apps auswählen sowie
   **Alle** oder **Keine** verwenden.
5. Übernimm die Auswahl mit **Katalog mit … Apps abgleichen**.

Der Scan verändert den ausgewählten Ordner nicht. Dateien werden nur gelesen.
Icons aus echten `.app`-Paketen können direkt lokal übernommen werden.
Typische technische Ordner und Backup-Archive werden automatisch ausgelassen.

> **Wichtig:** Ein erneuter vollständiger Scan gleicht den Katalog mit dem
> aktuellen Inhalt des gewählten Ordners ab. Nicht mehr vorhandene oder in der
> Prüfliste abgewählte lokale Einträge können dabei aus dem Katalog entfernt
> werden. Manuell angelegte Einträge ohne Datei bleiben erhalten.

Der zuletzt gewählte Quellordner kann später erneut gescannt werden.

### Vorhandenen Katalog importieren

1. Klicke auf **Katalog importieren**.
2. Wähle eine AppAtlas-JSON-Datei aus.
3. Bei geschützten Exporten gib das passende Passwort ein.

Wichtig: Beim Import wird der vorhandene Katalog ersetzt.

Auf dem leeren Startbildschirm kannst du außerdem das **Handbuch öffnen** oder
ChatGPT, Google Gemini oder Claude wählen. Vor dem Öffnen weist AppAtlas darauf
hin, dass eine vorbereitete AppAtlas-Frage samt öffentlichem PDF-Handbuch-Link in
die Zwischenablage kopiert wird. Füge sie anschließend im gewählten KI-Dienst
mit `⌘V` ein und sende sie mit Return. Dein Katalog, lokale Dateipfade und
Lizenzdaten werden nicht in diese Frage eingefügt. AppAtlas fügt das
Handbuch nicht in die Anfrage ein, sondern verweist am Ende lediglich auf den
öffentlichen Link.

## 4. Apps verwalten

Nach dem Scan kannst du deine Apps bearbeiten und ergänzen.

Typische Aufgaben:

- **App hinzufügen**: Einen Eintrag manuell erstellen.
- **Bearbeiten**: Name, Beschreibung, Kategorie, Link, Tags oder Icon anpassen.
- **Aus Katalog löschen**: Nur den Katalogeintrag entfernen.
- **Lokale Dateien in Papierkorb legen**: Zugeordnete lokale Dateien nach ausdrücklicher Bestätigung in den macOS-Papierkorb verschieben.

AppAtlas bietet kein dauerhaftes Löschen lokaler Dateien an. Wenn Dateien in den Papierkorb gelegt werden, kannst du sie dort wiederherstellen.

Ein eigenes Icon kannst du als Bilddatei auswählen, in die App ziehen, aus der
Zwischenablage einfügen oder über eine direkte Bild-URL laden.

**Gesamten Katalog löschen** entfernt alle Einträge aus AppAtlas. Die lokalen
App-Dateien werden dadurch nicht automatisch gelöscht.

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
Eine laufende Aktualisierung kann pausiert, fortgesetzt oder abgebrochen
werden. Vorhandene manuelle Angaben werden nicht einfach überschrieben.

Bei Online-Abfragen können Suchbegriffe wie der normalisierte App-Name und ein allgemeiner Kategoriehinweis an Dienste wie iTunes, GitHub, Reddit r/macapps oder DuckDuckGo gesendet werden. Lokale Dateipfade, Katalogstruktur und Lizenzdaten werden dabei nicht übertragen.

Wenn keine eindeutige Website gefunden wurde, kannst du selbst eine URL
ergänzen. AppAtlas kann daraus je nach Adresse Homepage, Download-Link,
GitHub-Verknüpfung, Beschreibung oder Icon ableiten. Über die
**Website-Ausschlussliste** kannst du Rückfragen für einzelne Apps ausschalten
oder später wieder erlauben.

## 7. App-Assistent verwenden

Der **App-Assistent** hilft dir, deinen lokalen Katalog zu befragen. Du kannst ihn zum Beispiel nutzen für:

- „Mit welcher App kann ich Videos erstellen?“
- „Welche meiner Apps eignet sich für Screenshots?“
- „Welche App ist für Backups gedacht?“

Die normale Kataloganalyse läuft lokal. Wenn du die optionale Internetrecherche aktivierst, wird deine eingegebene Frage an die Reddit-Suche in r/macapps und r/macos gesendet. Dein Katalog, lokale Dateipfade und Lizenzdaten werden dabei nicht mitgesendet.

Ein Klick auf eine vorgeschlagene App öffnet den passenden Katalogeintrag.

## 8. Lizenzdaten verwalten

AppAtlas kann Lizenzinformationen zu Apps speichern.

Mögliche Lizenzdaten sind zum Beispiel:

- Seriennummern.
- registrierte E-Mail-Adressen.
- Lizenztypen.
- private Notizen.

Private Lizenzdaten werden im macOS-Schlüsselbund gespeichert. Beim normalen Katalogexport sind Schlüsselbunddaten nicht enthalten. Du kannst Lizenzdaten bewusst importieren oder beim Export ausdrücklich mit aufnehmen.

Lizenzdaten können aus JSON- oder CSV-Dateien importiert werden. Die Importdatei wird nicht in AppAtlas gespeichert und nicht an Onlinedienste übertragen.

Vor dem Speichern zeigt AppAtlas eine Vorschau mit sicher zugeordneten,
fehlenden und nicht eindeutigen Apps. Private Lizenzwerte werden in dieser
Vorschau nicht angezeigt. Fehlende Apps können nach deiner Zustimmung als
manuelle Katalogeinträge angelegt werden.

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
Das Passwort muss mindestens 12 Zeichen lang sein und kann nicht
wiederhergestellt werden.

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

## 12. Einstellungen

Unter **Allgemein** kannst du:

- die Sprache automatisch, auf Deutsch oder auf Englisch festlegen,
- die Backup-Erinnerung auf 7, 30 oder 90 Tage einstellen oder ausschalten,
- manuell nach AppAtlas-Updates suchen,
- ein bis fünf gleichzeitig bearbeitete Apps für Online-Aktualisierungen
  wählen,
- die erweiterte Online-Suche ein- oder ausschalten,
- die letzte Leistungsmessung der Online-Aktualisierung ansehen.

AppAtlas prüft höchstens einmal täglich automatisch auf neue Versionen.
Gefundene Versionen werden nicht automatisch installiert.

Unter **Scanner** kannst du konkrete lokale Ordner, wiederkehrende Ordnernamen,
relative Pfade und bestimmte Dateiendungen vom nächsten Scan ausschließen.
Diese Einstellungen bleiben lokal auf deinem Mac.

## 13. Fehler melden

AppAtlas enthält einen datensparsamen Fehlerbericht.

So nutzt du ihn:

1. Öffne **App-Aktionen**.
2. Wähle **Fehler melden**.
3. Kopiere den Bericht in eine E-Mail oder in Codex.

Fehlerberichte und Fragen können an **appatlas@mailbox.org** gesendet werden.

## 14. Datenschutz kurz erklärt

AppAtlas ist auf lokale Nutzung ausgelegt.

Wichtig:

- Persönliche Kataloge liegen lokal im Application-Support-Verzeichnis der macOS-Sandbox.
- Icons und Vorschaubilder werden lokal gespeichert.
- Scan-Ordner werden beim Scannen nur gelesen.
- Lizenzdaten liegen im macOS-Schlüsselbund.
- Standardexporte enthalten keine Schlüsselbunddaten.
- Online-Abfragen passieren nur nach bewusster Aktion.
- Scanner-Ausschlüsse und gelernte Zuordnungen bleiben lokal.
- Eine absolute Aussage „AppAtlas sendet niemals irgendetwas“ wäre falsch, weil bewusst gestartete Online-Aktualisierungen, Internetrecherchen und Webseitenaufrufe Netzwerkverbindungen benötigen.

## 15. Empfohlener Einstieg

Wenn du AppAtlas zum ersten Mal nutzt, ist dieser Ablauf sinnvoll:

1. App öffnen.
2. **Ordner scannen** wählen.
3. Gefundene Apps kurz prüfen.
4. Wichtige Apps mit Tags und Kategorien versehen.
5. Fehlende Daten bewusst über **Online-Daten aktualisieren** ergänzen.
6. Unsichere Treffer unter **Zu prüfen** kontrollieren.
7. Lizenzdaten nur bei Bedarf ergänzen.
8. Katalog exportieren und sicher ablegen.

## 16. Hilfe mit KI

Du kannst diese Anleitung über die Schaltflächen im leeren Startbildschirm in
ChatGPT, Google Gemini oder Claude öffnen und dir den Einstieg erklären lassen.

Beispiel-Prompt:

```text
Ich habe AppAtlas gerade zum ersten Mal geöffnet und mein Katalog ist noch
leer. Erkläre mir AppAtlas freundlich und in einfacher Sprache. Führe mich
anschließend Schritt für Schritt durch meinen ersten Katalog:

1. „Ordner scannen“ auswählen.
2. Einen Ordner mit Apps oder Installationsdateien auswählen.
3. Das Scan-Ergebnis prüfen und unerwünschte Vorschläge abwählen.
4. Die ausgewählten Apps mit „Katalog mit … Apps abgleichen“ übernehmen.
5. Erklären, wie ich Apps suche, kategorisiere und bearbeite.
6. Erklären, wann „Online-Daten aktualisieren“ sinnvoll ist und dass diese
   Funktion bewusst gestartet werden muss.
7. Unsichere Treffer unter „Zu prüfen“ kontrollieren.
8. Zum Abschluss einen sicheren Katalogexport ohne Lizenzdaten erstellen.

Erkläre bei jedem Schritt genau, welche Schaltfläche ich anklicken muss, was
danach erscheint und worauf ich achten sollte. Weise besonders darauf hin,
dass ein erneuter vollständiger Scan nicht mehr vorhandene oder abgewählte
lokale Einträge aus dem Katalog entfernen kann. Verwende kurze Abschnitte und
frage mich am Ende, bei welchem Schritt ich Hilfe benötige.

Verweise anschließend auf das offizielle Handbuch:
https://github.com/Schrotty74/AppAtlas/blob/main/docs/output/pdf/AppAtlas-Handbuch-DE.pdf
```

Gib einer externen KI keine Seriennummern, Lizenzschlüssel, persönlichen
Dateipfade oder ungeschützten Katalogexporte.

## 17. Weitere Dokumentation

- [AppAtlas-Handbuch (Deutsch, PDF)](docs/output/pdf/AppAtlas-Handbuch-DE.pdf)
- [AppAtlas User Manual (English, PDF)](docs/output/pdf/AppAtlas-User-Manual-EN.pdf)
- [README](README.de.md)
- [Theme-Dokumentation](docs/themes/README.md)
- [Projektstruktur](docs/PROJECT_STRUCTURE.md)
- [Datenschutzdetails](docs/PRIVACY.md)
- [Release-Workflow](docs/RELEASE_WORKFLOW.md)
- [AppAtlas auf GitHub](https://github.com/Schrotty74/AppAtlas)
- [AppAtlas-Community auf Discord](https://discord.gg/RbsvqRCPQ)
