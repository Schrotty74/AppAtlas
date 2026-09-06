# Security Policy

[Deutsch](SECURITY.de.md)

## Supported Versions

| Version | Supported |
| --- | --- |
| 1.2.x | Yes |
| 1.1.x and earlier | No |

The current stable release is 1.2.3. Preview and beta versions are not maintained separately.

## Reporting a Vulnerability

Please do not open a public GitHub issue for security vulnerabilities. Report them privately to [appatlas@mailbox.org](mailto:appatlas@mailbox.org). Include the AppAtlas and macOS versions, a clear description, reproduction steps and relevant logs or screenshots with private catalog and license information removed.

I aim to respond to security reports within 7 days.

## Scope

Relevant reports include local folder scanning and file operations, catalog databases and exports, AES-256-GCM protected exports, macOS Keychain handling of license data, metadata/catalog updates, local translation, optional online lookups and privacy-conscious bug reports.

AppAtlas is a local-first macOS app without its own data backend. Online sources are contacted only by features that deliberately perform an online lookup or update.

Thank you for helping keep AppAtlas and its users secure.
