# Datenschutz

Datenschutz hat bei AppAtlas Vorrang vor Funktionalität.

## Git und Builds

Git und veröffentlichte Builds enthalten keine persönlichen Kataloge,
Scanlisten, App-Namen, Lizenzdaten, Importdateien oder lokalen Benutzerpfade.
Der Build bricht ab, falls private Katalog- oder Importdateien gefunden werden.

## Lokale Daten

Jeder Benutzer startet mit einem leeren Katalog. Der persönliche Katalog liegt
ausschließlich im lokalen Application-Support-Verzeichnis der macOS-Sandbox.
Icons und Vorschaubilder werden dort als separate lokale Dateien gespeichert.

Der ausgewählte Scan-Ordner wird beim Scannen nur gelesen. AppAtlas verändert
Dateien darin ausschließlich nach einer ausdrücklichen Bestätigung des
Benutzers über „Lokale Dateien in Papierkorb legen“. Dabei werden zugeordnete
Dateien über den macOS-Papierkorb gelöscht und können von dort wiederhergestellt
werden. AppAtlas bietet kein dauerhaftes Löschen lokaler Dateien an.

## Lizenzdaten

Seriennummern, registrierte E-Mail-Adressen, Lizenztypen und private Notizen
liegen im macOS-Schlüsselbund. Sie werden nur nach einer ausdrücklichen
Benutzerauswahl in eine Exportdatei aufgenommen.

Lizenzdaten können bewusst aus einer JSON- oder CSV-Datei importiert werden.
Dabei werden ausschließlich sicher zuordenbare Einträge in den macOS-
Schlüsselbund übernommen. Die Importdatei wird weder kopiert noch in AppAtlas
gespeichert und niemals an Onlinedienste übertragen.

## Katalogexport

Der Standardexport enthält keine Schlüsselbunddaten. Optional kann der Benutzer
Lizenzdaten unverschlüsselt oder passwortgeschützt exportieren. Der geschützte
Export verwendet PBKDF2-HMAC-SHA256 und authentifizierte AES-256-GCM-
Verschlüsselung. Unverschlüsselte Exporte zeigen vorab eine deutliche Warnung.
Exportdateien sind persönliche Daten und müssen vom Benutzer geschützt werden.

## Online-Anreicherung

Online-Anfragen für Icons, Beschreibungen und Links werden nur nach einem
bewussten Klick auf „Katalog aktualisieren“ ausgelöst. Das bloße Anzeigen oder
Scannen eines Katalogs startet keine Anreicherung. Für die Suche wird nur der
normalisierte App-Name an iTunes beziehungsweise DuckDuckGo gesendet; lokale
Dateipfade, Katalogstruktur und Lizenzdaten verlassen das Gerät nicht.
GitHub und Reddit r/macapps werden erst innerhalb derselben ausdrücklich
gestarteten Aktualisierung abgefragt. Dabei wird ebenfalls ausschließlich der
normalisierte App-Name übertragen. Bereits vom Benutzer gespeicherte oder
bestätigte Webseiten können direkt abgerufen werden, um deren Metadaten zu
prüfen.

Unsichere Funde werden als lokale Vorschläge mit Quellenangabe gespeichert und
nicht ungeprüft übernommen. Fremdsprachige Beschreibungen werden ab macOS 15
mit Apples Translation-Framework lokal zur Übersetzung vorbereitet. Falls die
Übersetzung nicht möglich ist, bleibt der Originaltext sichtbar gekennzeichnet
und muss vom Benutzer geprüft werden.

## Neue Funktionen

Bei neuen Funktionen mit Datenschutzwirkung muss die Auswirkung vor der
Umsetzung genannt und eine datensparsame Alternative vorgeschlagen werden.
