# Projekthistorie

## 1.2.0 – Scanner- und Metadatenkorrekturen

- Stabiler Release der 1.2.0-Reihe mit den aktuellen Korrekturen seit 1.1.1.
- Schwerer Hänger beim lokalen Scan behoben: Regex-Muster in
  `AppNameNormalizer` werden jetzt statisch gecacht.
- Bestätigte Quellen-URLs werden gegen den tatsächlich vorgeschlagenen Wert
  geprüft.
- Regex-Caching wurde in beiden AppNameNormalizer-Implementierungen ergänzt;
  technische Begriffe in `CatalogEntryFilter` werden ebenfalls gecacht.
- Beta-/Release-Paketierung robuster gemacht, inklusive lokaler Xcode-Cache-
  Pfade, DMG-Fallback, ignorierten Backup-Release-Notizen und strukturierten
  Release Notes.

## 1.2.0-beta.2 – Metadaten- und Stabilitätskorrekturen

- Zweite Beta der 1.2.0-Reihe mit den aktuellen Korrekturen für
  Metadaten-Vorschläge, Icon-Verarbeitung und lokale Datenpfade.
- 1.2.0-beta.1 bleibt als frühere Beta erhalten; diese Version ist ein
  separates Pre-Release.

## 1.2.0-beta.1 – Metadaten, Icons und getrennte Beta-Daten

- Development-, Beta- und Release-Builds verwenden getrennte lokale
  Application-Support-Ordner; Beta-Builds haben eine eigene Bundle-ID.
- Scanner-Ausschlüsse greifen zuverlässiger und entfernen ausgeschlossene
  Einträge auch aus dem bestehenden Katalog.
- Online-Erkennung und Icon-Auswahl wurden mit Homebrew-Cask-Daten,
  robusterer App-Normalisierung, Apple-Bundle-ID-Abgleich und SVG-Unterstützung
  verbessert.
- Einzelne Apps können gezielt mit der vollständigen Metadaten-Pipeline
  aktualisiert werden.
- Abgelehnte Quellen werden dauerhaft lokal gemerkt und nicht erneut
  vorgeschlagen.

## 1.1.1 – Schlüsselbund-Export und Development-Build

- Katalogexporte mit Lizenzdaten lesen nur noch bekannte Lizenzdatensätze aus
  dem macOS-Schlüsselbund, statt jede App im Katalog gegen den Schlüsselbund zu
  prüfen.
- Der zusätzliche Schlüsselbund-Authentifizierungskontext wurde entfernt, um
  unnötige macOS-Passwortdialoge beim Export zu vermeiden.
- Die Exportdatei wird erst nach Auswahl des Speicherorts erzeugt, damit keine
  App-Sheets und Schlüsselbunddialoge ineinanderlaufen.
- Der Katalogimport verwendet wieder zuverlässig den nativen macOS-Dateidialog.
- Lokale Development-Builds laufen ohne Datenschutz-Audit; Datenschutzprüfungen
  bleiben für Commit, Push, Release und Backup aktiv.

## 1.1.0 – Backup-Erinnerung, Statistik und Tags

- Konfigurierbare Backup-Erinnerung für Katalogexporte mit Intervallen von
  7, 30 oder 90 Tagen sowie einer Nie-Option.
- Katalogstatistik mit Gesamtzahl, Kategorien, lokaler Dateigröße, fehlenden
  Beschreibungen, Icons, Homepages und Lizenzdaten-Hinweisen.
- Eigene Tags pro App, inklusive Editor-Feld, Sidebar-Filter und Suche.
- Katalog-JSON bleibt abwärtskompatibel: ältere Kataloge ohne Tags werden
  weiterhin geladen.
- Statistik liest keine privaten Lizenzwerte aus dem macOS-Schlüsselbund und
  löst dadurch keine Schlüsselbund-Passwortabfrage aus.
- Der App-Editor verwendet eine feste, scrollbar nutzbare Dialoggröße, damit
  macOS das Hauptfenster beim Öffnen nicht verschiebt.

## 1.0.1 – Test- und Stabilitätskorrekturen

- Lizenzspeicher ist für Tests injizierbar, während die App weiterhin
  unverändert den macOS-Schlüsselbund verwendet.
- Lizenztests verwenden einen isolierten Speicher und greifen nicht mehr auf
  den echten Schlüsselbund zu.
- Icon-Qualitätstests sind unabhängig von App-Ressourcen.
- Leistungstests vergleichen relative Laufzeiten statt geräteabhängiger fester
  Zeitlimits.

## 1.0.0 – Erste stabile Version

- Alle Funktionen und Stabilitätskorrekturen der fünf öffentlichen Betas.
- Zuverlässiger Import kompatibler UroBilanz-Themes mit Reduktion auf die für
  AppAtlas relevanten Darstellungswerte.
- Einheitliche Theme-Darstellung in der Kompaktansicht.
- Importierte Theme-Kopien erscheinen ohne technischen Kopiezusatz in der
  gemeinsamen Theme-Liste.
- Signiertes DMG als regulärer GitHub-Release.
- Erweitertes Datenschutzaudit von Quellcode, Git-Historie und Release-Paket.

## 1.0.0-beta.5 – Theme- und Cache-Stabilität

- Zuverlässige vollständige Hell-/Dunkel-Umschaltung des System-Themes.
- Einheitlichere Theme-Darstellung ohne doppelt gezeichneten Hintergrund in
  der eingebetteten Detailspalte.
- Stabile kompakte Suche und lesbarer App-Zähler in der Toolbar.
- Kein automatischer Übersetzungsdownload-Dialog beim App-Start.
- Automatische Wiederherstellung fehlender Icon-Cache-Ordner.
- Release-ZIPs und Prüfsummen ausschließlich im lokalen Backup-Ordner.

## 1.0.0-beta.4 – Metadaten-Vertrauen, Fehlerberichte und Liquid Glass

- Gemeinsame Vertrauensbewertung für Apple, GitHub, Websuche und Reddit.
- Automatische Übernahme nur bei hoher Sicherheit und klarem Abstand zum
  zweitbesten Treffer.
- Bundle-ID, Hersteller, Kategorie, Unterordner und bestätigte Quellen als
  zusätzliche Identitätssignale.
- Ausschließlich lokal gespeicherte Lernzuordnungen für bestätigte Domains,
  GitHub-Repositories und Apple-Store-IDs.
- Datenschutzfreundlicher Fehlerbericht für E-Mail und Codex.
- Native Liquid-Glass-Oberflächen unter macOS 26 mit Rückfall auf das bisherige
  Theme-System.
- Gehärteter Release-Build gegen eingebettete lokale Toolchain-Pfade.

## 1.0.0-beta.3 – Scanner-Abgleich und bessere Icon-Auswahl

- Vollständige Scans gleichen neue, geänderte und entfernte lokale Dateien mit
  dem Katalog ab. Dateigröße und Änderungsdatum werden aktualisiert, während
  rein manuelle Einträge erhalten bleiben.
- Lokale Ordner können direkt über den macOS-Ordnerdialog dauerhaft vom Scan
  ausgeschlossen werden. Die Auswahl wird nur lokal als
  Security-Scoped Bookmark gespeichert.
- Zusätzlich lassen sich Ordnernamen, relative Pfade und selbst definierte
  Dateiendungen vom Scan ausschließen.
- Lokale `.app`-Bundles liefern bereits beim Scan ihr Originalicon.
- Bei der bewussten Katalogaktualisierung werden eindeutig passende lokal
  installierte Apps vor Onlinequellen geprüft.
- Onlinebilder benötigen eine höhere Mindestauflösung und ein nahezu
  quadratisches Format. Screenshots, Vorschauen, Banner und
  Dokumentationsbilder werden nicht mehr als App-Icons akzeptiert.
- GitHub-Repositories werden gezielter nach echten AppIcon- und
  Ressourcen-Dateien durchsucht.
- Die Scanbestätigung erklärt den vollständigen Katalogabgleich einschließlich
  der Behandlung nicht mehr vorhandener Dateien.
- Die Scanner-Einstellungen sind in einem eigenen Reiter zusammengefasst.
- Datenschutzdokumentation und öffentliche Offenlegung der bewusst
  ausgelösten Netzwerkzugriffe wurden erweitert.
- Automatisierte Scanner-, Abgleich-, Ausschluss- und Icon-Qualitätstests
  sichern die neuen Abläufe ab.

## 1.0.0-beta.2 – Stabilität, Navigation und private Lizenzimporte

- Theme-Dokumentation, Theme-Vorlage, Beispieltheme und Projektstruktur sind
  direkt auf der GitHub-Startseite verlinkt.
- „Alle Apps“ ist nun eine zuverlässig anklickbare Aktion zum Zurücksetzen des
  Kategorie-Filters.
- Einzelne Apps können aus der Detailansicht, von Karten und aus Listen
  gelöscht werden. Zugeordnete lokale Dateien lassen sich nach ausdrücklicher
  Bestätigung in den macOS-Papierkorb legen.
- Erneute Scans teilen ältere, fälschlich zusammengeführte App-Ausgaben anhand
  ihrer tatsächlichen Dateipfade wieder in getrennte Katalogeinträge auf.
- Bereits falsch zusammengeführte Einträge werden außerdem beim Laden des
  lokalen Katalogs automatisch getrennt und anhand ihres tatsächlichen
  Speicherorts wieder der richtigen Kategorie und dem richtigen Unterordner
  zugeordnet.
- Die Sidebar zeigt ausschließlich echte Ordner aus den Scanpfaden. Datei- und
  App-Namen werden nicht mehr als vermeintliche Unterordner dargestellt.
- Lizenzdaten können getrennt vom Katalog aus JSON oder CSV importiert werden.
  Eine Vorschau zeigt Zuordnungen und Konflikte, ohne private Lizenzwerte
  offenzulegen. Versions- und Verpackungszusätze werden besser erkannt,
  doppelte Einträge zusammengeführt und fehlende Apps können bewusst als
  private manuelle Einträge angelegt werden.
- Katalogdateien werden vor und nach dem Schreiben validiert. Bei einer
  beschädigten Hauptdatei kann die letzte gültige Fassung wiederhergestellt
  werden.
- Scan-Abgleich, Dateiübertragungen und Dialogsteuerung wurden in eigene
  Dienste aufgeteilt. Der indexierte Abgleich und Leistungstests verbessern
  Stabilität und Geschwindigkeit bei großen Katalogen.
- Import, Export, Themes, Lizenzdateien und manuell gewählte Icons verwenden
  einen gemeinsamen geschützten Dateizugriff.
- Direkter Download-Link für den jeweils offiziellen Build auf der Startseite.
- Explizite Verknüpfung der Frameworks NaturalLanguage und Translation.
- Release-, Backup- und Push-Aktionen benötigen eine ausdrückliche Freigabe
  und führen vorab Datenschutzprüfungen aus.

## 1.0.0-beta.1 – Erste offizielle Beta

- Erste zusammengefasste Beta der nativen macOS-App unter GPLv3.
- Leerer und datenschutzfreundlicher Erststart mit frei wählbaren Scanordnern.
- Rein lesender Scanner mit Vorschlagsauswahl und allgemeinen Ausschlussregeln
  für technische Inhalte sowie Backup-Archive.
- Manuelle Katalogpflege, hierarchische Kategorien, mehrere Ansichten,
  Themes sowie schnelle lokale Suche mit tolerierten kleinen Tippfehlern.
- Bewusst gestartete Online-Aktualisierung für Icons, Beschreibungen und Links
  mit Review-Bereich, Quellenangaben und Schutz manueller Änderungen.
- Deutsche und englische Oberfläche sowie lokale Apple-Übersetzung
  fremdsprachiger Beschreibungen, sofern vom System unterstützt.
- Lokale Icon-Ablage mit Originalen und Vorschaubildern für flüssigere
  Katalogansichten.
- JSON-Import und -Export mit optionalen Lizenzdaten. Private Lizenzdaten
  liegen im Schlüsselbund; geschützte Exporte verwenden AES-256-GCM.

## Datenschutzbereinigung

- Persönliche Ausgangsdaten und sämtliche frühere Git-Historie wurden vor
  einer Veröffentlichung aus dem Repository entfernt.
- Neue Benutzer starten mit einem leeren Katalog.
- Private Lizenzdaten wurden in den macOS-Schlüsselbund ausgelagert.
- JSON-Katalogimport und -export wurden ohne Schlüsselbunddaten ergänzt.
- Der Katalogexport wurde um eine bewusste Auswahl für Lizenzdaten erweitert:
  ohne Lizenzdaten, unverschlüsselt oder passwortgeschützt. Geschützte
  Exporte verwenden PBKDF2-HMAC-SHA256 und AES-256-GCM.
- Eine bewusst ausgelöste Kataloganreicherung ergänzt fehlende Icons,
  Beschreibungen und Links, ohne vorhandene Inhalte zu überschreiben.
- Webseiten-Vorschaubilder werden nicht mehr als App-Icons verwendet.
  Kurze Quellenbeschreibungen werden um eine Funktionsübersicht ergänzt.
- Die manuelle Anreicherung heißt nun „Katalog aktualisieren“. GitHub- und
  GitLab-Projektseiten können als Metadatenquelle verwendet werden; nur
  geeignete quadratische Bilder werden als App-Icon akzeptiert.
- GitHub-Repositories werden gezielt nach echten App-Icon-Dateien durchsucht.
  Doppelte Links werden nach dem Auflösen von Weiterleitungen entfernt.
- Eingebettete Icon-Daten wurden aus dem lokalen Katalog ausgelagert.
  Originalicons und schnelle Vorschaubilder liegen separat in Application
  Support und werden beim Export weiterhin vollständig mitgegeben.
- Die manuelle Aktualisierung erhielt einen Review-Workflow mit Quellenangaben,
  Vorschlägen, Bestätigung, Bearbeitung und Verwerfen. Unsichere Treffer werden
  nicht automatisch übernommen.
- Reddit r/macapps wurde als ausdrücklich ausgelöster, subjektiv
  gekennzeichneter Beschreibungs-Fallback ergänzt.
- Fremdsprachige Beschreibungen werden erkannt und ab macOS 15 über Apples
  Translation-Framework vor einer automatischen Übernahme ins Deutsche
  übersetzt.
- Manuell gepflegte Icons, Beschreibungen und Links werden dauerhaft vor einer
  automatischen Überschreibung geschützt.
- Der Scanner überspringt technische Ordner, Datensammlungen und typische
  Backup-Archive. Vor der Aufnahme können alle App-Vorschläge einzeln an- oder
  abgewählt werden.

Weitere abgeschlossene technische Änderungen werden künftig ohne persönliche
Daten oder Rückschlüsse auf lokale Nutzung dokumentiert.
