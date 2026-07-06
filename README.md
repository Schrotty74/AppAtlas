# AppAtlas

[Deutsch](README.de.md)

<p align="center">
  <img src="Sources/AppAtlas/Resources/AppIcon.png" width="180" alt="AppAtlas Logo">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0-orange?logo=swift" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/macOS-14%2B-blue?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/License-GPL--3.0-green" alt="GPL-3.0">
  <img src="https://img.shields.io/github/v/release/Schrotty74/AppAtlas" alt="Release">
  <img src="https://img.shields.io/github/downloads/Schrotty74/AppAtlas/total" alt="Downloads">
  <img src="https://img.shields.io/badge/Privacy-Audited-brightgreen" alt="Privacy Audited">
</p>

AppAtlas is a native, privacy-focused SwiftUI app for macOS. It organizes
personal app collections from user-selected folders and manages icons,
descriptions, links, tags, license information, and local catalog exports.

> Current release: **AppAtlas 1.2.0**

[Download AppAtlas 1.2.0](https://github.com/Schrotty74/AppAtlas/releases/download/v1.2.0/AppAtlas-1.2.0-macos.dmg)

## Key Features

- Scan freely selected folders in read-only mode and filter out technical data
  and typical backup archives.
- Permanently exclude local folders and custom file extensions from scans.
- Compare new, changed and removed files with the catalog on repeated scans.
- Manually add, edit and delete app entries.
- Tag apps and filter them through the sidebar or search.
- Move local app files to the Trash only after explicit confirmation.
- Manage descriptions, links and high-quality icons.
- Update missing metadata manually through "Update Catalog".
- Review uncertain matches with source labels before accepting or rejecting
  them.
- Configure online lookups, parallel processing and extended search locally.
- Manage per-app website prompts through an exclusion list.
- Translate foreign-language descriptions locally before saving them.
- Store icons locally as original files and fast thumbnails.
- Search apps by name, description, category, folder and tags.
- Use hierarchical categories and subfolders.
- Use an app assistant with optional Reddit research.
- Import, export and delete themes.
- Use native Liquid Glass effects for controls and cards on macOS 26 and
  later, with compatible rendering on older macOS versions.
- Export and import the catalog as JSON, optionally without license data,
  unencrypted or password-protected with AES-256-GCM.
- Configure backup reminders for regular catalog exports.
- View catalog statistics with categories, storage usage and missing metadata.
- Import license data from JSON and CSV files.
- Store private license data in the macOS Keychain.
- Delete individual apps or the complete catalog.
- Create privacy-conscious bug reports for email or Codex.
- Use the interface in English or German.

## Screenshots

The screenshots below use demo data only.

<table>
  <tr>
    <td width="50%">
      <img src="docs/screenshots/appatlas-classic-demo.jpg" alt="AppAtlas classic view with demo data" width="100%">
      <br><sub>Classic view</sub>
    </td>
    <td width="50%">
      <img src="docs/screenshots/appatlas-focus-demo.jpg" alt="AppAtlas focus view with demo data" width="100%">
      <br><sub>Focus view</sub>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="docs/screenshots/appatlas-compact-demo.jpg" alt="AppAtlas compact view with demo data" width="100%">
      <br><sub>Compact view</sub>
    </td>
    <td width="50%">
      <img src="docs/screenshots/appatlas-dashboard-demo.jpg" alt="AppAtlas dashboard view with demo data" width="100%">
      <br><sub>Dashboard view</sub>
    </td>
  </tr>
</table>

## Requirements

- macOS 14 or later.
- macOS 15 or later for Apple's local translation feature.
- Swift 6.

## Build and Install

Download the current release:
[AppAtlas 1.2.0](https://github.com/Schrotty74/AppAtlas/releases/download/v1.2.0/AppAtlas-1.2.0-macos.dmg)

When opening AppAtlas for the first time, macOS may display a warning because
the app is not notarized with a paid Apple Developer account.

To open the app anyway:

1. Right-click the app file.
2. Select **Open**.
3. Click **Open** or **Open Anyway** in the dialog that appears.

Alternatively, open **System Settings -> Privacy & Security** and confirm
**Open Anyway** at the bottom of the page.

For development checks:

```sh
swift test
swift build
```

For a manually launchable development build without beta, ZIP or backup:

```sh
./Scripts/build-development.sh
```

The app is created at `dist/local-test/AppAtlas-Development/AppAtlas.app` and is not
opened automatically.

The Beta release workflow is handled by the release script:

```sh
./Scripts/create-beta-from-dev.sh 1.2.0-beta.3
```

Build artifacts in `dist/` are not tracked by Git. Backups are created only on
explicit request. Local Git checks before every commit and push help prevent
typical catalog, export and database files from being added.

## Documentation

- [Theme documentation](docs/themes/README.md)
- [Template for custom themes](docs/themes/appatlas-theme-template.json)
- [Complete example theme](docs/themes/example-custom-theme.json)
- [Example theme Autumn Ember](docs/themes/example-autumn-ember.json)
- [Example theme Winter Frost](docs/themes/example-winter-frost.json)
- [Project structure](docs/PROJECT_STRUCTURE.md)
- [Release workflow](docs/RELEASE_WORKFLOW.md)
- [Privacy details](docs/PRIVACY.md)
- [Privacy audit for AppAtlas 1.2.0](docs/PRIVACY_AUDIT_2026-07-06.md)

## Transparency

AppAtlas was designed and developed together with OpenAI Codex. The name
**AppAtlas** also came from a Codex suggestion. The app logo was created with
Codex as well.

## Report Issues

Bug reports and questions can be sent to
[appatlas@mailbox.org](mailto:appatlas@mailbox.org). AppAtlas also includes a
bug report dialog that creates a privacy-conscious report for email or for
pasting into Codex.

## License

AppAtlas is licensed under the GNU General Public License Version 3.
