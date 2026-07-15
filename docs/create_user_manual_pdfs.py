#!/usr/bin/env python3
"""Create the German and English AppAtlas user manuals as accessible PDFs."""

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    Image,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
SCREENSHOTS = ROOT / "docs" / "screenshots"
ICON = ROOT / "Sources" / "AppAtlas" / "Resources" / "AppIcon.png"
OUTPUT = ROOT / "docs" / "output" / "pdf"

PAGE_WIDTH, PAGE_HEIGHT = A4
MARGIN_X = 1.65 * cm
MARGIN_Y = 1.55 * cm
CONTENT_WIDTH = PAGE_WIDTH - 2 * MARGIN_X

INK = colors.HexColor("#172033")
MUTED = colors.HexColor("#5D687A")
ACCENT = colors.HexColor("#356AE6")
ACCENT_DARK = colors.HexColor("#214AAB")
PALE = colors.HexColor("#ECF2FF")
LINE = colors.HexColor("#D8DFEA")
WHITE = colors.white


def esc(value):
    return (
        str(value)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def styles_for(language):
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "manual-title", parent=base["Title"], fontName="Helvetica-Bold",
            fontSize=29, leading=34, textColor=INK, alignment=TA_CENTER,
            spaceAfter=11,
        ),
        "subtitle": ParagraphStyle(
            "manual-subtitle", parent=base["Normal"], fontName="Helvetica",
            fontSize=13, leading=18, textColor=MUTED, alignment=TA_CENTER,
        ),
        "h1": ParagraphStyle(
            "manual-h1", parent=base["Heading1"], fontName="Helvetica-Bold",
            fontSize=19, leading=24, textColor=INK, spaceBefore=4, spaceAfter=10,
        ),
        "h2": ParagraphStyle(
            "manual-h2", parent=base["Heading2"], fontName="Helvetica-Bold",
            fontSize=13.5, leading=17, textColor=ACCENT_DARK, spaceBefore=12,
            spaceAfter=6,
        ),
        "body": ParagraphStyle(
            "manual-body", parent=base["BodyText"], fontName="Helvetica",
            fontSize=9.6, leading=14, textColor=INK, spaceAfter=7,
        ),
        "small": ParagraphStyle(
            "manual-small", parent=base["BodyText"], fontName="Helvetica",
            fontSize=8.4, leading=11.5, textColor=MUTED,
        ),
        "callout": ParagraphStyle(
            "manual-callout", parent=base["BodyText"], fontName="Helvetica",
            fontSize=9.4, leading=13.4, textColor=INK,
        ),
        "toc": ParagraphStyle(
            "manual-toc", parent=base["BodyText"], fontName="Helvetica",
            fontSize=10.3, leading=16, textColor=INK,
        ),
        "step": ParagraphStyle(
            "manual-step", parent=base["BodyText"], fontName="Helvetica",
            fontSize=9.4, leading=13.3, textColor=INK, leftIndent=7,
        ),
        "table": ParagraphStyle(
            "manual-table", parent=base["BodyText"], fontName="Helvetica",
            fontSize=8.2, leading=10.7, textColor=INK,
        ),
    }


def P(text, style):
    return Paragraph(esc(text), style)


def title(text, st):
    return Paragraph(esc(text), st["h1"])


def heading(text, st):
    return Paragraph(esc(text), st["h2"])


def body(text, st):
    return Paragraph(esc(text), st["body"])


def callout(text, st):
    table = Table([[Paragraph(esc(text), st["callout"])]], colWidths=[CONTENT_WIDTH])
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), PALE),
        ("BOX", (0, 0), (-1, -1), 0.6, colors.HexColor("#BBD0FF")),
        ("LINEBEFORE", (0, 0), (0, -1), 3, ACCENT),
        ("LEFTPADDING", (0, 0), (-1, -1), 11),
        ("RIGHTPADDING", (0, 0), (-1, -1), 11),
        ("TOPPADDING", (0, 0), (-1, -1), 9),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 9),
    ]))
    return table


def table(rows, widths, st, header=True):
    formatted = []
    for row in rows:
        formatted.append([Paragraph(esc(cell), st["table"]) for cell in row])
    result = Table(formatted, colWidths=widths, repeatRows=1 if header else 0)
    style = [
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("GRID", (0, 0), (-1, -1), 0.35, LINE),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("BACKGROUND", (0, 1), (-1, -1), WHITE),
    ]
    if header:
        style += [
            ("BACKGROUND", (0, 0), (-1, 0), ACCENT),
            ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ]
    result.setStyle(TableStyle(style))
    return result


def bullets(items, st):
    return [
        Paragraph("• " + esc(item), st["body"])
        for item in items
    ]


def steps(items, st):
    result = []
    for number, item in enumerate(items, start=1):
        result.append(Paragraph(f"<b>{number}.</b> {esc(item)}", st["step"]))
        result.append(Spacer(1, 3))
    return result


def screenshot(filename, caption, st, height_cm=10.2):
    path = SCREENSHOTS / filename
    image = Image(str(path))
    image._restrictSize(CONTENT_WIDTH, height_cm * cm)
    return KeepTogether([
        image,
        Spacer(1, 4),
        Paragraph(esc(caption), st["small"]),
        Spacer(1, 9),
    ])


def footer(canvas, document):
    canvas.saveState()
    canvas.setStrokeColor(LINE)
    canvas.line(MARGIN_X, 1.15 * cm, PAGE_WIDTH - MARGIN_X, 1.15 * cm)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(MUTED)
    canvas.drawString(MARGIN_X, 0.75 * cm, "AppAtlas User Manual")
    canvas.drawRightString(PAGE_WIDTH - MARGIN_X, 0.75 * cm, str(document.page))
    canvas.restoreState()


DE = {
    "cover": "AppAtlas Handbuch",
    "tagline": "Der klare Leitfaden für deinen lokalen App-Katalog",
    "edition": "Deutsch | Stand: Juli 2026",
    "intro": "AppAtlas hilft dir, Anwendungen, Installer und Informationen dazu an einem Ort zu sammeln. Dieses Handbuch zeigt jede wichtige Funktion, ihren Ort in der App und den einfachsten Weg dorthin.",
    "toc": [
        "1. AppAtlas auf einen Blick", "2. Wo finde ich was?", "3. Ersten Katalog erstellen",
        "4. Apps verwalten", "5. Finden, filtern und Ansichten", "6. Online-Daten aktualisieren",
        "7. App-Assistent und Prüfung", "8. Lizenzen und private Daten", "9. Export, Import und Backup",
        "10. Erscheinungsbild und Einstellungen", "11. Fehler melden, Hilfe und Datenschutz",
    ],
    "overview": "1. AppAtlas auf einen Blick",
    "overview_text": "AppAtlas ist ein lokaler Katalog für deine Software. Du kannst Programme und Installer aus Ordnern einlesen, Apps selbst anlegen, Informationen ergänzen und alles später bequem wiederfinden. Die App verwaltet dabei einen Katalog - sie verändert keine gefundenen Dateien.",
    "overview_points": [
        "Ordner scannen: Apps und Installer aus einem ausgewählten Ordner in den Katalog aufnehmen.",
        "Manuell anlegen: auch Programme ohne lokale Datei erfassen.",
        "Ordnen und finden: Kategorien, Unterkategorien, Tags, Suche und fünf Ansichten nutzen.",
        "Ergänzen: fehlende Icons, Beschreibungen und Links auf Wunsch online suchen.",
        "Sichern: Katalog und Lizenzdaten getrennt exportieren oder importieren.",
    ],
    "where": "2. Wo finde ich was?",
    "where_rows": [
        ("Funktion", "Wo du sie findest"),
        ("Ordner scannen", "Oben links in der Leiste: Ordner-Symbol mit Plus."),
        ("Ansicht wechseln", "Neben Ordner scannen: Symbol für die aktuelle Ansicht anklicken."),
        ("Alle Apps, Kategorien, Tags", "Linke Seitenleiste."),
        ("Apps suchen", "Oben rechts: Suchen mit Lupen-Symbol."),
        ("App-Assistent", "Oben rechts: App-Assistent mit Glitzer-Symbol."),
        ("App manuell hinzufügen", "Oben rechts: App hinzufügen mit Plus-Symbol."),
        ("Katalog, Import, Lizenzen, Statistik", "Oben rechts: App-Aktionen mit Kreis und drei Punkten."),
        ("Einstellungen und Fehler melden", "In App-Aktionen."),
        ("Themes", "Oben in der Leiste: Farb-/Theme-Menü neben der App-Anzahl."),
        ("Discord und GitHub", "Ganz links in der oberen Leiste: die beiden Logo-Schaltflächen."),
    ],
    "first": "3. Deinen ersten Katalog erstellen",
    "scan": "Apps und Installer aus einem Ordner einlesen",
    "scan_text": "Der Scan ist der normale Start. Er durchsucht nur den Ordner, den du auswählst. Unterstützt werden typische Dateitypen wie .app, .dmg, .pkg, .zip, .iso, .apk und .exe. Die Originaldateien bleiben unverändert.",
    "scan_steps": [
        "Klicke oben links auf Ordner scannen.",
        "Wähle den Ordner, in dem deine Programme oder Installer liegen.",
        "Prüfe die vorgeschlagenen Treffer und entferne bei Bedarf einzelne Einträge.",
        "Starte den Import. Danach erscheinen die Apps in deiner Mediathek.",
    ],
    "scan_note": "Bei einem erneuten Scan kann AppAtlas nicht mehr gefundene lokale Einträge aus dem Katalog entfernen. Manuell angelegte Apps bleiben erhalten.",
    "import": "Vorhandenen Katalog übernehmen",
    "import_steps": [
        "Öffne App-Aktionen oben rechts.",
        "Wähle Katalog importieren und ersetzen.",
        "Wähle deine AppAtlas-JSON-Datei. Bei einem geschützten Export gibst du zusätzlich das Passwort ein.",
        "Bestätige erst, wenn der aktuelle Katalog wirklich ersetzt werden darf.",
    ],
    "manage": "4. Apps verwalten",
    "add": "Eine App manuell hinzufügen",
    "add_steps": [
        "Klicke auf App hinzufügen oben rechts.",
        "Trage mindestens den Namen ein. Hersteller, Kurzbeschreibung, Kategorie und Unterkategorie sind optional, aber hilfreich.",
        "Ergänze Stichwörter und Tags mit Komma getrennt, damit du die App später leichter findest.",
        "Unter Links kannst du Homepage, Download und GitHub hinterlegen.",
        "Sichere den Eintrag über Sichern.",
    ],
    "edit": "Bearbeiten, Icon und Löschen",
    "edit_text": "Wähle zuerst eine App in der Liste. Öffne danach App-Aktionen und wähle Bearbeiten. Dort kannst du Beschreibungen, Kategorien, Tags, Links und den Prüfstatus ändern. Ein Icon kannst du aus einer Datei wählen, aus der Zwischenablage einfügen oder über eine direkte Bild-URL laden. Das Löschen einer einzelnen App und das Löschen des gesamten Katalogs findest du ebenfalls in App-Aktionen.",
    "find": "5. Finden, filtern und Ansichten",
    "find_text": "Die linke Seitenleiste ist deine Navigation. Alle Apps zeigt den gesamten Katalog. Zu prüfen zeigt Einträge, die noch kontrolliert werden sollten. Kategorien können Unterordner enthalten; Tags filtern über eigene Schlagwörter. Die Zahl rechts zeigt jeweils die Anzahl der passenden Apps.",
    "search": "Suche und Layouts",
    "search_text": "Klicke oben rechts auf Suchen. Die Suche prüft App-Namen, Kategorien und Dateinamen. Für die Darstellung klickst du oben links neben Ordner scannen auf das Ansichts-Symbol. Es gibt fünf Layouts: Klassisch, Fokus, Kompakt, Dashboard und Regale. Der Inhalt bleibt gleich; nur die Darstellung ändert sich.",
    "statistics": "Katalogstatistik",
    "statistics_text": "Öffne App-Aktionen > Katalogstatistik für einen schnellen Überblick. Dort siehst du die Gesamtzahl der Apps, die Größe lokaler Dateien, die Zahl der Apps mit Lizenzdaten, fehlende Beschreibungen, Icons und Homepages sowie die Verteilung auf Kategorien.",
    "online": "6. Online-Daten aktualisieren",
    "online_text": "Wenn Icons, Beschreibungen oder Links fehlen, kannst du sie bewusst online ergänzen lassen. Klicke oben links auf Online-Daten aktualisieren oder wähle dieselbe Funktion in App-Aktionen. Während der Aktualisierung kannst du Pausieren, Fortsetzen oder Abbrechen. Der Fortschritt erscheint direkt in der oberen Leiste.",
    "online_points": [
        "AppAtlas nutzt je nach Fundlage öffentliche Quellen wie iTunes, GitHub, Reddit und DuckDuckGo.",
        "Öffne danach Zu prüfen in der Seitenleiste und kontrolliere Vorschläge und Quellen.",
        "Eigene Eingaben werden geschützt: selbst gepflegte Daten werden nicht einfach überschrieben.",
        "Unter Einstellungen kannst du die Anzahl gleichzeitiger Anfragen und die erweiterte Online-Suche anpassen.",
    ],
    "assistant": "7. App-Assistent und Prüfung",
    "assistant_text": "Den App-Assistenten öffnest du oben rechts. Er beantwortet Fragen zu deinem lokalen Katalog, etwa welche Apps zu einer Kategorie gehören oder welche Einträge noch geprüft werden müssen. Er ist lokal. Eine Reddit-Suche wird nur dann online gestartet, wenn du das ausdrücklich auswählst; dabei wird nur deine Frage gesendet, nicht dein Katalog oder deine Lizenzdaten.",
    "review": "Prüfen und Website-Ausschlussliste",
    "review_text": "Zu prüfen in der Seitenleiste sammelt Einträge, bei denen Informationen kontrolliert werden sollten. Falls AppAtlas für eine App nach einer Website fragen möchte, kannst du diesen Hinweis für einzelne Apps oder Gruppen von Apps unterdrücken. Den Ort dafür findest du in App-Aktionen unter Website-Ausschlussliste.",
    "license": "8. Lizenzen und private Daten",
    "license_text": "Öffne eine App über Bearbeiten. Im Bereich Private Lizenzdaten kannst du Seriennummer, registrierte E-Mail-Adresse, Lizenztyp und Notizen speichern. Diese Daten liegen nur im macOS-Schlüsselbund deines Benutzerkontos - sie sind nicht Teil des normalen App-Katalogs.",
    "license_steps": [
        "Wähle eine App und öffne App-Aktionen > Bearbeiten.",
        "Fülle im Bereich Private Lizenzdaten die gewünschten Felder aus.",
        "Nutze das Auge-Symbol, wenn du die Seriennummer kurz anzeigen möchtest.",
        "Klicke Sichern. Bei einem Fehler zeigt AppAtlas eine Meldung an.",
    ],
    "license_import": "Lizenzdaten können außerdem aus JSON oder CSV importiert werden: App-Aktionen > Lizenzdaten importieren. Vor dem endgültigen Import zeigt AppAtlas eine Vorschau. Optional können fehlende passende Katalogeinträge angelegt werden.",
    "backup": "9. Export, Import und Backup",
    "backup_text": "Für eine Sicherung öffnest du App-Aktionen > Katalog exportieren. Du kannst nur den Katalog exportieren, die Lizenzdaten getrennt mitnehmen oder einen geschützten Export erstellen. Ein geschützter Export verwendet ein Passwort mit mindestens 12 Zeichen und AES-256-GCM-Verschlüsselung. Bewahre dieses Passwort sicher auf - ohne Passwort kann die Datei nicht wiederhergestellt werden.",
    "backup_steps": [
        "Öffne App-Aktionen und wähle Katalog exportieren.",
        "Wähle die gewünschten Inhalte und bei Bedarf den Passwortschutz.",
        "Speichere die JSON-Datei an einem sicheren Ort, zum Beispiel auf einem verschlüsselten Backup-Laufwerk.",
        "Zum Wiederherstellen wählst du Katalog importieren und ersetzen.",
    ],
    "backup_note": "Die Erinnerung an ein Backup kann unter Einstellungen > Allgemein ein- oder ausgeschaltet werden.",
    "settings": "10. Erscheinungsbild und Einstellungen",
    "themes": "Themes und eigene Farben",
    "themes_text": "Das Theme-Menü liegt oben neben der App-Anzahl. Dort wählst du mitgelieferte Erscheinungsbilder oder eigene Themes. Eigene Themes lassen sich importieren, exportieren und wieder löschen. Unter macOS 26 kann AppAtlas automatisch den Liquid-Glass-Stil des Systems nutzen.",
    "settings_text": "Öffne App-Aktionen > Einstellungen. Im Reiter Allgemein stellst du Sprache, Backup-Erinnerung, Update-Prüfung, Online-Suche und die Anzahl paralleler Online-Anfragen ein. Die Update-Prüfung kann neue Versionen anzeigen und die passende GitHub-Release-Seite öffnen. Im Reiter Scanner bestimmst du ausgeschlossene Ordner, Namen, relative Pfade und Dateiendungen. Das ist sinnvoll, wenn bestimmte Bereiche nie eingelesen werden sollen.",
    "help": "11. Fehler melden, Hilfe und Datenschutz",
    "help_text": "Fehler melden findest du in App-Aktionen. Der Bericht ist bewusst klein gehalten und enthält App-Version, macOS-Version, gewählte Sprache sowie eine Fehlerbeschreibung. Du entscheidest selbst, ob du ihn weitergibst. Discord und GitHub erreichst du über die Logo-Schaltflächen ganz links in der oberen Leiste. Das Handbuch und die KI-Hilfe sind auch auf der leeren Startansicht verlinkt.",
    "privacy": "Datenschutz in einem Satz",
    "privacy_text": "AppAtlas arbeitet zuerst lokal. Es liest nur Ordner, die du auswählst, verändert keine gefundenen Dateien und sendet Daten nur für Funktionen, die du bewusst online auslöst. Lizenzdaten bleiben im Schlüsselbund deines macOS-Benutzers.",
    "start": "Empfohlener Start",
    "start_steps": [
        "Einen Ordner mit Apps oder Installern scannen.",
        "Die ersten Einträge in Zu prüfen kontrollieren und bei Bedarf bearbeiten.",
        "Online-Daten aktualisieren nur dann starten, wenn Informationen fehlen.",
        "Nach wichtigen Änderungen einen Katalog-Export als Backup speichern.",
    ],
}


EN = {
    "cover": "AppAtlas User Manual",
    "tagline": "A clear guide to your local application catalog",
    "edition": "English | July 2026 edition",
    "intro": "AppAtlas helps you collect applications, installers, and their information in one place. This manual explains every important feature, where to find it, and the simplest way to use it.",
    "toc": [
        "1. AppAtlas at a glance", "2. Where to find everything", "3. Create your first catalog",
        "4. Manage apps", "5. Search, filters, and layouts", "6. Update online data",
        "7. App Assistant and review", "8. Licenses and private data", "9. Export, import, and backup",
        "10. Appearance and settings", "11. Report an issue, help, and privacy",
    ],
    "overview": "1. AppAtlas at a glance",
    "overview_text": "AppAtlas is a local catalog for your software. You can scan folders for applications and installers, create apps manually, add information, and find everything again later. The app manages a catalog - it does not modify files it finds.",
    "overview_points": [
        "Scan folders: add applications and installers from a folder you choose.",
        "Create manually: record software even when no local file is available.",
        "Organize and find: use categories, subcategories, tags, search, and five layouts.",
        "Enrich: deliberately look online for missing icons, descriptions, and links.",
        "Protect your work: export or import the catalog and license data separately.",
    ],
    "where": "2. Where to find everything",
    "where_rows": [
        ("Feature", "Where to find it"),
        ("Scan a folder", "Top left toolbar: folder icon with a plus."),
        ("Change layout", "Next to Scan Folder: click the current layout icon."),
        ("All apps, categories, tags", "Left sidebar."),
        ("Search apps", "Top right toolbar: Search with magnifying-glass icon."),
        ("App Assistant", "Top right toolbar: App Assistant with sparkle icon."),
        ("Add an app manually", "Top right toolbar: Add App with plus icon."),
        ("Catalog, import, licenses, statistics", "Top right toolbar: App Actions, the circle with three dots."),
        ("Settings and report an issue", "Inside App Actions."),
        ("Themes", "Toolbar: theme/color menu next to the app count."),
        ("Discord and GitHub", "Far left in the top toolbar: the two logo buttons."),
    ],
    "first": "3. Create your first catalog",
    "scan": "Add apps and installers from a folder",
    "scan_text": "Scanning is the usual starting point. It only searches the folder you choose. Typical file types such as .app, .dmg, .pkg, .zip, .iso, .apk, and .exe are supported. Your original files remain unchanged.",
    "scan_steps": [
        "Click Scan Folder in the top-left toolbar.",
        "Choose the folder containing your applications or installers.",
        "Review the proposed matches and remove individual entries if needed.",
        "Start the import. Your apps then appear in the library.",
    ],
    "scan_note": "When you scan again, AppAtlas can remove local catalog entries that are no longer found. Apps you created manually remain in the catalog.",
    "import": "Use an existing catalog",
    "import_steps": [
        "Open App Actions in the top-right toolbar.",
        "Choose Import and replace catalog.",
        "Choose your AppAtlas JSON file. For a protected export, also enter its password.",
        "Confirm only when the current catalog may really be replaced.",
    ],
    "manage": "4. Manage apps",
    "add": "Add an app manually",
    "add_steps": [
        "Click Add App in the top-right toolbar.",
        "Enter at least the name. Developer, short description, category, and subcategory are optional but useful.",
        "Add keywords and tags separated by commas so that the app is easier to find later.",
        "Under Links, add a homepage, download page, and GitHub address when available.",
        "Save the entry using Save.",
    ],
    "edit": "Edit, icon, and delete",
    "edit_text": "First select an app in the list. Then open App Actions and choose Edit. There you can change descriptions, categories, tags, links, and the review status. You can choose an icon from a file, paste one from the clipboard, or load it from a direct image URL. Deleting one app and deleting the entire catalog are also available in App Actions.",
    "find": "5. Search, filters, and layouts",
    "find_text": "The left sidebar is your navigation. All Apps shows the entire catalog. Needs Review shows entries that should still be checked. Categories can contain subfolders; Tags filter by your own labels. The number on the right shows how many apps match.",
    "search": "Search and layouts",
    "search_text": "Click Search in the top-right toolbar. Search checks app names, categories, and file names. To change the presentation, click the layout icon next to Scan Folder in the top-left toolbar. There are five layouts: Classic, Focus, Compact, Dashboard, and Shelves. The content stays the same; only the presentation changes.",
    "statistics": "Catalog statistics",
    "statistics_text": "Open App Actions > Catalog Statistics for a quick overview. It shows the total number of apps, the size of local files, the number of apps with license data, missing descriptions, icons and homepages, and the distribution across categories.",
    "online": "6. Update online data",
    "online_text": "When icons, descriptions, or links are missing, you can deliberately enrich them online. Click Update Online Data in the top-left toolbar, or choose the same action in App Actions. During the update, you can Pause, Resume, or Cancel. Progress appears directly in the top toolbar.",
    "online_points": [
        "Depending on availability, AppAtlas uses public sources such as iTunes, GitHub, Reddit, and DuckDuckGo.",
        "Afterward, open Needs Review in the sidebar and check suggestions and sources.",
        "Your own entries are protected: information you maintain yourself is not simply overwritten.",
        "In Settings, adjust the number of concurrent requests and extended online search.",
    ],
    "assistant": "7. App Assistant and review",
    "assistant_text": "Open App Assistant in the top-right toolbar. It answers questions about your local catalog, for example which apps belong to a category or which entries still need review. It works locally. A Reddit search starts online only when you explicitly choose it; only your question is sent, not your catalog or license data.",
    "review": "Review and website exclusion list",
    "review_text": "Needs Review in the sidebar collects entries whose information should be checked. If AppAtlas wants to ask about a website for an app, you can suppress this prompt for individual apps or groups of apps. Find this under App Actions > Website Exclusion List.",
    "license": "8. Licenses and private data",
    "license_text": "Open an app through Edit. In the Private License Data area, you can save a serial number, registered email address, license type, and notes. This data is stored only in the macOS Keychain for your user account - it is not part of the regular app catalog.",
    "license_steps": [
        "Select an app and open App Actions > Edit.",
        "Fill in the fields you want in the Private License Data area.",
        "Use the eye icon when you want to reveal the serial number briefly.",
        "Click Save. AppAtlas displays a message if saving fails.",
    ],
    "license_import": "License data can also be imported from JSON or CSV: App Actions > Import License Data. AppAtlas shows a preview before the final import. You may optionally create matching catalog entries that are missing.",
    "backup": "9. Export, import, and backup",
    "backup_text": "For a backup, open App Actions > Export Catalog. You can export only the catalog, include license data separately, or create a protected export. A protected export uses a password with at least 12 characters and AES-256-GCM encryption. Keep that password safe - the file cannot be restored without it.",
    "backup_steps": [
        "Open App Actions and choose Export Catalog.",
        "Choose the content you need and password protection when desired.",
        "Store the JSON file somewhere safe, for example on an encrypted backup drive.",
        "To restore it, choose Import and replace catalog.",
    ],
    "backup_note": "The backup reminder can be enabled or disabled in Settings > General.",
    "settings": "10. Appearance and settings",
    "themes": "Themes and your own colors",
    "themes_text": "The theme menu is in the toolbar next to the app count. There you can choose built-in appearances or your own themes. Custom themes can be imported, exported, and deleted. On macOS 26, AppAtlas can automatically use the system Liquid Glass style.",
    "settings_text": "Open App Actions > Settings. On the General tab, choose language, backup reminder, update checking, online search behavior, and the number of parallel online requests. Update checking can display a newer version and open its GitHub release page. On the Scanner tab, define excluded folders, names, relative paths, and file extensions. This is useful when certain areas should never be scanned.",
    "help": "11. Report an issue, help, and privacy",
    "help_text": "Report an Issue is in App Actions. The report is intentionally small and contains the app version, macOS version, selected language, and your description of the problem. You decide whether to share it. Discord and GitHub are available through the logo buttons at the far left of the top toolbar. The manual and AI help are also linked from the empty start screen.",
    "privacy": "Privacy in one sentence",
    "privacy_text": "AppAtlas works locally first. It reads only folders you choose, does not modify files it finds, and sends data only for features you deliberately start online. License data stays in your macOS user Keychain.",
    "start": "Recommended first steps",
    "start_steps": [
        "Scan a folder containing apps or installers.",
        "Check the first entries in Needs Review and edit them when needed.",
        "Start Update Online Data only when information is missing.",
        "After important changes, save an Export Catalog backup.",
    ],
}


def make_manual(data, output_path):
    st = styles_for(data["edition"])
    story = []

    story += [Spacer(1, 1.3 * cm)]
    if ICON.exists():
        icon = Image(str(ICON), width=2.5 * cm, height=2.5 * cm)
        icon.hAlign = "CENTER"
        story += [icon, Spacer(1, 0.45 * cm)]
    story += [Paragraph(esc(data["cover"]), st["title"]), Paragraph(esc(data["tagline"]), st["subtitle"])]
    story += [Spacer(1, 0.8 * cm), callout(data["intro"], st), Spacer(1, 0.55 * cm)]
    story += [Paragraph(esc(data["edition"]), st["subtitle"]), Spacer(1, 0.65 * cm)]
    story += [screenshot("appatlas-classic-demo.jpg", data["cover"] + " - Classic layout", st, 7.4)]
    story += [PageBreak()]

    story += [title("Contents" if data is EN else "Inhalt", st), Spacer(1, 5)]
    for item in data["toc"]:
        story += [Paragraph(esc(item), st["toc"])]
    story += [Spacer(1, 14), heading(data["overview"], st), body(data["overview_text"], st)]
    story += bullets(data["overview_points"], st)
    story += [Spacer(1, 5), screenshot("appatlas-dashboard-demo.jpg", data["cover"] + " - Dashboard layout", st, 3.8)]
    story += [PageBreak()]

    story += [title(data["where"], st), Spacer(1, 4)]
    story += [table(data["where_rows"], [4.8 * cm, CONTENT_WIDTH - 4.8 * cm], st)]
    story += [Spacer(1, 14), screenshot("appatlas-focus-demo.jpg", data["cover"] + " - Focus layout", st, 8.5)]
    story += [PageBreak()]

    story += [title(data["first"], st), heading(data["scan"], st), body(data["scan_text"], st)]
    story += steps(data["scan_steps"], st)
    story += [callout(data["scan_note"], st), heading(data["import"], st)]
    story += steps(data["import_steps"], st)
    story += [Spacer(1, 10), screenshot("appatlas-compact-demo.jpg", data["cover"] + " - Compact layout", st, 8.0)]
    story += [PageBreak()]

    story += [title(data["manage"], st), heading(data["add"], st)]
    story += steps(data["add_steps"], st)
    story += [heading(data["edit"], st), body(data["edit_text"], st)]

    story += [title(data["find"], st), body(data["find_text"], st), heading(data["search"], st), body(data["search_text"], st), heading(data["statistics"], st), body(data["statistics_text"], st)]
    story += [heading(data["online"], st), body(data["online_text"], st)]
    story += bullets(data["online_points"], st)
    story += [PageBreak()]

    story += [title(data["assistant"], st), body(data["assistant_text"], st), heading(data["review"], st), body(data["review_text"], st)]
    story += [title(data["license"], st), body(data["license_text"], st)]
    story += steps(data["license_steps"], st)
    story += [callout(data["license_import"], st), PageBreak()]

    story += [title(data["backup"], st), body(data["backup_text"], st)]
    story += steps(data["backup_steps"], st)
    story += [callout(data["backup_note"], st), heading(data["settings"], st), heading(data["themes"], st), body(data["themes_text"], st), body(data["settings_text"], st)]
    story += [PageBreak()]

    story += [title(data["help"], st), body(data["help_text"], st), heading(data["privacy"], st), callout(data["privacy_text"], st), heading(data["start"], st)]
    story += steps(data["start_steps"], st)
    story += [Spacer(1, 18), Paragraph(esc(data["cover"]), st["subtitle"])]

    document = SimpleDocTemplate(
        str(output_path), pagesize=A4, leftMargin=MARGIN_X, rightMargin=MARGIN_X,
        topMargin=1.55 * cm, bottomMargin=1.45 * cm,
        title=data["cover"], author="AppAtlas",
    )
    document.build(story, onFirstPage=footer, onLaterPages=footer)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    make_manual(DE, OUTPUT / "AppAtlas-Handbuch-DE.pdf")
    make_manual(EN, OUTPUT / "AppAtlas-User-Manual-EN.pdf")
    print("Created:")
    print(OUTPUT / "AppAtlas-Handbuch-DE.pdf")
    print(OUTPUT / "AppAtlas-User-Manual-EN.pdf")


if __name__ == "__main__":
    main()
