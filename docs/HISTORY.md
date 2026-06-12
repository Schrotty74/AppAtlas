# Projekthistorie

## 1.0.0-beta.2

- Theme-Dokumentation, Theme-Vorlage, Beispieltheme und Projektstruktur sind
  direkt auf der GitHub-Startseite verlinkt.
- „Alle Apps“ ist nun eine zuverlässig anklickbare Aktion zum Zurücksetzen des
  Kategorie-Filters.
- Einzelne Apps können direkt aus der Detailansicht gelöscht werden.
- Erneute Scans teilen ältere, fälschlich zusammengeführte App-Ausgaben anhand
  ihrer tatsächlichen Dateipfade wieder in getrennte Katalogeinträge auf.

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
