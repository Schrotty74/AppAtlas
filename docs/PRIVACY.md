# Datenschutz

Datenschutz hat bei AppAtlas Vorrang vor Funktionalität.

## Git und Builds

Git und veröffentlichte Builds enthalten keine persönlichen Kataloge,
Scanlisten, App-Namen, Lizenzdaten, Importdateien oder lokalen Benutzerpfade.
Der Build bricht ab, falls private Katalog- oder Importdateien gefunden werden.
Vor Commit und Push prüft AppAtlas zusätzlich alle veröffentlichbaren Dateien.
Ein erweitertes Audit kontrolliert auch Dateinamen in der erreichbaren
Git-Historie. Dieses umfangreiche Audit wird bei jeder finalen Version
durchgeführt, nicht bei Betas. Jeder neue Final-Bericht ergänzt die bestehende
chronologische Audit-Historie; frühere Berichte bleiben erhalten. Der bisherige
Prüfbericht ist unter
[Datenschutzaudit vom 13. Juni 2026](PRIVACY_AUDIT_2026-06-13.md) dokumentiert.

## Lokale Daten

Jeder Benutzer startet mit einem leeren Katalog. Der persönliche Katalog liegt
ausschließlich im lokalen Application-Support-Verzeichnis der macOS-Sandbox.
Icons und Vorschaubilder werden dort als separate lokale Dateien gespeichert.
Vom Benutzer bestätigte Metadatenzuordnungen werden ebenfalls ausschließlich
lokal in den App-Einstellungen gespeichert. Dazu gehören normalisierte
App-Schlüssel, bestätigte Domains, konkrete GitHub-Repositories und
Apple-Store-IDs. Sie sind nicht Bestandteil von Katalogexporten oder
Release-Paketen.

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
Scannen eines Katalogs startet keine Anreicherung. Für die Suche wird der
normalisierte App-Name sowie gegebenenfalls ein allgemeiner Kategoriehinweis
an iTunes, GitHub, Reddit r/macapps beziehungsweise DuckDuckGo gesendet.
Lokale Dateipfade, die Katalogstruktur und Lizenzdaten werden dabei nicht
übertragen. Bereits vom Benutzer gespeicherte oder bestätigte Webseiten können
direkt abgerufen werden, um deren Metadaten zu prüfen. Wie bei jedem
Webseitenaufruf erhält der jeweilige Server dabei technisch notwendige
Verbindungsdaten wie die IP-Adresse.

Unsichere Funde werden als lokale Vorschläge mit Quellenangabe gespeichert und
nicht ungeprüft übernommen. Fremdsprachige Beschreibungen werden ab macOS 15
mit Apples Translation-Framework verarbeitet. AppAtlas baut dafür selbst keine
Verbindung zu einem Übersetzungsdienst auf; das Verhalten des
macOS-Systemframeworks und mögliche Modelldownloads liegen unter Apples
Kontrolle. Falls die Übersetzung nicht möglich ist, bleibt der Originaltext
sichtbar gekennzeichnet und muss vom Benutzer geprüft werden.

## Assistent

Die normale Kataloganalyse und Apple-Intelligence-Auswertung verwenden lokale
Katalogdaten auf dem Mac. Wird die optionale Internetrecherche bewusst
aktiviert, sendet AppAtlas die eingegebene Frage unverändert an die
Reddit-Suche in r/macapps und r/macos. Katalog, lokale Dateipfade und
Lizenzdaten werden nicht mitgesendet.

## Keine absolute Netzwerkaussage

AppAtlas lädt persönliche Kataloge, lokale Dateipfade und Lizenzdaten nicht
hoch. Eine Aussage, dass die App niemals irgendeine Information sendet, wäre
dennoch falsch: ausdrücklich gestartete Online-Aktualisierungen,
Internetrecherchen und Webseitenaufrufe benötigen Netzwerkverbindungen und
übertragen die oben beschriebenen Suchbegriffe oder Fragen.

## Neue Funktionen

Bei neuen Funktionen mit Datenschutzwirkung muss die Auswirkung vor der
Umsetzung genannt und eine datensparsame Alternative vorgeschlagen werden.
