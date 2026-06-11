import Foundation
import NaturalLanguage

enum DescriptionLanguageProcessor {
    static func detectedLanguage(for text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }

    static func isGerman(_ language: String?) -> Bool {
        language == NLLanguage.german.rawValue
    }

    static func matches(_ language: String?, targetLanguage: String) -> Bool {
        language == targetLanguage
    }

    static func originalWithLanguageNote(
        _ text: String,
        language: String?
    ) -> String {
        guard let language, !language.isEmpty else {
            return text
        }
        return "\(text)\n\n(Originalsprache: \(language))"
    }
}
