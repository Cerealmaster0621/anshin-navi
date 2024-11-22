import Foundation
import SwiftUI

public var isUserAppJapanese: Bool {
    // Get current locale identifier (e.g., "ja_JP", "en_US")
    let currentLocale = Locale.current.identifier
    // Return true if it's Japanese
    return currentLocale.hasPrefix("ja")
}
