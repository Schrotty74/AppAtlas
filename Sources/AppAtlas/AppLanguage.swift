import Foundation

enum AppLanguageChoice: String, CaseIterable, Identifiable {
    case automatic
    case german
    case english

    static let storageKey = "appLanguage"
    static let dachRegions = Set(["DE", "AT", "CH", "LI"])

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: AppLocalization.text("Automatisch")
        case .german: AppLocalization.text("Deutsch")
        case .english: "English"
        }
    }

    func resolvedLanguage(
        regionCode: String? = Locale.current.region?.identifier
    ) -> String {
        switch self {
        case .german:
            "de"
        case .english:
            "en"
        case .automatic:
            Self.dachRegions.contains(regionCode?.uppercased() ?? "")
                ? "de"
                : "en"
        }
    }

    var locale: Locale {
        Locale(identifier: resolvedLanguage())
    }

    static var current: AppLanguageChoice {
        AppLanguageChoice(
            rawValue: UserDefaults.standard.string(forKey: storageKey) ?? ""
        ) ?? .automatic
    }
}

enum AppLocalization {
    static func text(_ key: String) -> String {
        let language = AppLanguageChoice.current.resolvedLanguage()
        guard let path = AppResources.bundle.path(
            forResource: language,
            ofType: "lproj"
        ),
        let bundle = Bundle(path: path)
        else {
            return key
        }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
