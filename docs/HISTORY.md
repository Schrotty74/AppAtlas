# Projekthistorie

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
