# Datenschutzaudit vom 13. Juni 2026

Dieses Audit dokumentiert den veröffentlichten Stand von AppAtlas
`1.0.0-beta.2` und den dazugehörigen Quellcode.

## Ergebnis

Die Prüfung war erfolgreich:

- Keine persönlichen Kataloge, Scanlisten oder Importdateien im Git-Repository
  oder Release-Paket
- Keine lokalen Benutzer- oder Volume-Pfade im veröffentlichten Quellcode oder
  App-Binary
- Keine realen Seriennummern, Lizenzschlüssel oder Passwörter im Repository
- Keine Katalog-, CSV-, TSV-, Datenbank- oder Exportdateien im Release-Paket
- Persönliche Lizenzwerte werden ausschließlich im macOS-Schlüsselbund
  gespeichert
- Der Standard-Katalogexport enthält keine Lizenzdaten

Die im Repository vorhandenen Theme-JSON-Dateien sind öffentliche Vorlagen und
enthalten keine Katalog- oder Nutzerdaten. In Tests verwendete Passwörter und
Lizenzwerte sind ausdrücklich erzeugte Testdaten.

## Geprüfte Bereiche

- Alle aktuell von Git verfolgten und für einen Commit vorgesehenen Dateien
- Dateinamen und Textinhalte der gesamten erreichbaren Git-Historie
- App-Bundle und ZIP-Datei von `1.0.0-beta.2`
- Release-Inhalt auf private Dateitypen und eingebettete lokale Pfade
- Quellcode aller direkten Netzwerkzugriffe
- Datenschutzprüfungen vor Commit, Push und Release-Build

Das Audit kann lokal mit folgendem Befehl wiederholt werden:

```sh
./Scripts/privacy-audit.sh
```

## Was AppAtlas nicht überträgt

AppAtlas überträgt bei seinen eigenen Netzwerkzugriffen keine:

- persönlichen Katalogdateien oder vollständigen Kataloge
- lokalen Dateipfade oder Scanordner
- Lizenzschlüssel, Seriennummern oder Lizenznotizen
- importierten Lizenzdateien
- lokal gespeicherten Icons oder Beschreibungen als Sammlung

## Bewusst ausgelöste Netzwerkzugriffe

Eine Garantie, dass AppAtlas niemals irgendeine Information sendet, wäre
inhaltlich falsch. Folgende Netzwerkzugriffe sind Bestandteil ausdrücklich
gewählter Funktionen:

| Aktion | Ziel | Übertragene Anwendungsdaten |
| --- | --- | --- |
| „Katalog aktualisieren“ | Apple iTunes Search API | normalisierter App-Name |
| „Katalog aktualisieren“ | GitHub API und GitHub-Rohdateien | normalisierter App-Name oder bereits gespeicherte GitHub-URL |
| „Katalog aktualisieren“ | Reddit r/macapps | normalisierter App-Name |
| Suche nach Herstellerseite | DuckDuckGo | normalisierter App-Name, allgemeiner Kategoriehinweis und „mac app official“ |
| Metadaten einer gespeicherten Webseite prüfen | gespeicherte oder bestätigte Webseite | Webseitenaufruf ohne Katalog- oder Lizenzdaten |
| Assistent mit aktivierter Internetrecherche | Reddit r/macapps und r/macos | eingegebene Frage |
| Links öffnen | ausgewählte Webseite | normaler Browseraufruf |

Bei Netzwerkverbindungen erhalten die jeweiligen Server außerdem technisch
notwendige Verbindungsdaten wie die IP-Adresse. AppAtlas besitzt keinen eigenen
Server, kein Benutzerkonto, keine Telemetrie und keine Analysefunktion.

Apples Translation- und Foundation-Models-Frameworks werden über macOS
verwendet. AppAtlas baut hierfür selbst keine Verbindung zu einem externen
KI- oder Übersetzungsdienst auf. Das Verhalten der Systemframeworks und
mögliche Modelldownloads liegen unter Apples Kontrolle.

## Technische Schutzmaßnahmen

- `.gitignore` schließt lokale Kataloge, TSV-Dateien, Builds und Backups aus.
- `Scripts/privacy-check.sh` blockiert sensible Dateitypen, lokale Pfade und
  fest eingetragene Lizenzwerte vor Commit und Push.
- `Scripts/privacy-audit.sh` erweitert die Prüfung um die erreichbare
  Git-Historie.
- Release-Builds entfernen private Dateien und brechen bei eingebetteten
  Benutzer- oder Volume-Pfaden ab.
- Git-Hooks verlangen Datenschutzprüfung und ausdrückliche Push-Freigabe.
- Release-, Backup- und Push-Aktionen benötigen eine ausdrückliche Freigabe.

## Geltungsbereich

Das Ergebnis gilt für den geprüften Stand. Absolute Sicherheit für jede
zukünftige Änderung oder das Verhalten externer Dienste kann seriös nicht
garantiert werden. Der normale Datenschutzcheck bleibt vor Commit und Push
aktiv. Das umfangreiche Audit wird bei jeder finalen Version erneut
durchgeführt, nicht bei Betas. Jeder neue Final-Bericht ergänzt diesen Bericht
als chronologische Audit-Historie und legt die tatsächlich übertragenen Daten
offen.
