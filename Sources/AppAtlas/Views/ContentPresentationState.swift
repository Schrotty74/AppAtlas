import Foundation

@MainActor
final class ContentPresentationState: ObservableObject {
    @Published var sheet: ContentSheet?
    @Published var importer: ContentImporter?
    @Published var alert: ContentAlert?

    var encryptedCatalogData: Data?
    var pendingCatalogExport: CatalogExportProtection?

    func dismissSheet() {
        sheet = nil
    }

    func dismissAlert() {
        alert = nil
    }
}

enum ContentSheet: Identifiable {
    case addApp
    case editApp(AppEntry)
    case assistant
    case scanner
    case websiteExclusions
    case catalogExporter
    case catalogPassword
    case licensePreview(LicenseImportPlan)

    var id: String {
        switch self {
        case .addApp:
            "add-app"
        case .editApp(let app):
            "edit-\(app.id)"
        case .assistant:
            "assistant"
        case .scanner:
            "scanner"
        case .websiteExclusions:
            "website-exclusions"
        case .catalogExporter:
            "catalog-exporter"
        case .catalogPassword:
            "catalog-password"
        case .licensePreview:
            "license-preview"
        }
    }
}

enum ContentImporter: Equatable {
    case theme
    case catalog
    case licenses
}

enum ContentAlert: Identifiable {
    case message(title: String, message: String)
    case deleteTheme(AppAtlasThemeDefinition)
    case deleteApp(AppEntry)
    case deleteAll

    var id: String {
        switch self {
        case .message(let title, let message):
            "message-\(title)-\(message)"
        case .deleteTheme(let theme):
            "delete-theme-\(theme.id)"
        case .deleteApp(let app):
            "delete-app-\(app.id)"
        case .deleteAll:
            "delete-all"
        }
    }
}
