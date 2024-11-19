import SwiftUI
import MapKit
import CoreLocation

let SHELTERS_CSV_FILE_NAME = "shelter_data_filename".localized

// MainBottonDrawer Dent weight for each sizes
let SMALL_DENT_WEIGHT = 0.1
let MEDIUM_DENT_WEIGHT = 0.4

// Padding between searchbox and MainBottonDrawer
let MAIN_DRAWER_SEARCH_BOX_PADDING: CGFloat = 14

// Maximum number of annotations to show on the map at once
let MAX_ANNOTATIONS = 200

// evacuation shelters/centers
let WHAT_IS_SHELTER_FILTER: AttributedString = {
    let baseText = "shelter_filter_explanation".localized
    var text = AttributedString(baseText)
    
    let terms = [
        "evacuation_area_uppercase".localized,
        "shelter_uppercase".localized
    ]
    
    // Bold the terms
    for term in terms {
        var searchRange = text.startIndex..<text.endIndex
        while let range = text[searchRange].range(of: term) {
            text[range].font = .system(.footnote, design: .default, weight: .bold)
            searchRange = range.upperBound..<text.endIndex
        }
    }
    
    // Add link
    if let linkRange = text.range(of: "about_difference_link_text".localized) {
        text[linkRange].foregroundColor = .blue
        text[linkRange].link = URL(string: "https://www.bousai.go.jp/taisaku/hinanbasyo.html")
    }
    
    return text
}()

// Base Font Size
let BASE_FONT_SIZE: CGFloat = 14

// Share message templates
let SHARE_MESSAGE_TEMPLATE = "share_location_message".localized

let SHARE_NEAREST_SHELTER_TEMPLATE = "nearest_shelter_info".localized

let SHARE_GOOGLE_MAPS_URL_TEMPLATE = "https://www.google.com/maps/search/?api=1&query=%f,%f"
let SHARE_APPLE_MAPS_URL_TEMPLATE = "http://maps.apple.com/?q=%f,%f"
