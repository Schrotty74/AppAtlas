This beta contains the latest AppAtlas fixes and improvements since v1.2.0-beta.2.

## Fixed

- Fixed severe main thread hang (beachball) on local scan: regex patterns in AppNameNormalizer are now cached as static properties.
- Fixed confirmed source URLs not being checked against the actual suggested value.
- Fixed regex caching in both AppNameNormalizer implementations and cached CatalogEntryFilter technical terms.

## Improved

- Improved beta release packaging to use local Xcode cache paths, fallback DMG creation, ignored backup release notes and structured release notes generation.
## Privacy

AppAtlas starts without a personal catalog. Catalogs, local paths, license
values, user-specific icons and backup files are not included in the source
code or release package.

Local catalogs, scan data, icons and caches remain in the local Application
Support folder for the active build variant. License values remain in the
macOS Keychain and are exported only after explicit user action.
