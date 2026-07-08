import Foundation
import NaturalLanguage

public enum DescriptionLanguageProcessor {
    public static func detectedLanguage(for text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
            ?? NLLanguage.english.rawValue
    }

    public static func isGerman(_ language: String?) -> Bool {
        language == NLLanguage.german.rawValue
    }

    public static func isGermanTarget(_ language: String) -> Bool {
        language == NLLanguage.german.rawValue
            || language.lowercased().hasPrefix("de")
    }

    public static func matches(_ language: String?, targetLanguage: String) -> Bool {
        language == targetLanguage
    }

    public static func originalWithLanguageNote(
        _ text: String,
        language: String?
    ) -> String {
        text
    }
}
