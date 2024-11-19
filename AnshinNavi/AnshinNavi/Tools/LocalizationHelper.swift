import Foundation

enum Language: String {
    case japanese = "ja"
    case english = "en"
    case german = "de"
    case korean = "ko"
    
    static var current: Language {
        guard let languageCode = Locale.current.language.languageCode?.identifier else {
            return .japanese // Default to Japanese
        }
        return Language(rawValue: languageCode) ?? .japanese
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    // Get localized string for a specific language
    func localized(for language: Language) -> String {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return self
        }
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
}

// Usage example in code:
// "shelter".localized // Gets translation for current language
// "distance".localized(with: 500) // For strings with format specifiers
// "shelter".localized(for: .english) // Force English translation