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
var MAX_ANNOTATIONS = 200

// Default Annotation Type
var ANNOTATION_TYPE:CurrentAnnotationType = .shelter

// Default FontSize Weight

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

let SHARE_NEAREST_POLICE_TEMPLATE = "nearest_police_info".localized

let SHARE_GOOGLE_MAPS_URL_TEMPLATE = "https://www.google.com/maps/search/?api=1&query=%f,%f"
let SHARE_APPLE_MAPS_URL_TEMPLATE = "http://maps.apple.com/?q=%f,%f"

// Map Settings
var MAP_TYPE: MapType = .standard
let MAX_ANNOTATION_RANGE: ClosedRange<Double> = 100...500
let ANNOTATION_STEP: Double = 10

// Font Settings
var FONT_SIZE: FontSize = .medium

// Setting Icons
let SETTING_ICONS = [
    "map": "map.fill",
    "annotation": "mappin.circle.fill",
    "defaultAnnotation": "building.2.fill",
    "fontSize": "textformat.size",
    "tsunami": "tsunami",
    "earthquake": "earthquake",
    "fire": "flame.fill",
    "dataSources": "doc.text.fill"
]

// Setting Colors
let SETTING_COLORS = [
    "map": Color.green,
    "annotation": Color.orange,
    "defaultAnnotation": Color.blue,
    "fontSize": Color.purple,
    "tsunami": Color.blue,
    "earthquake": Color.red,
    "fire": Color.orange,
    "dataSources": Color.gray
]

// Setting Presentation
let SETTING_DETENTS: Set<PresentationDetent> = [.medium, .large]

// Map Types
enum MapType: String, CaseIterable, Identifiable {
    case standard
    case satellite
    case hybrid
    case satelliteFlyOver
    
    var id: String { rawValue }
    var name: String {
        switch self {
        case .standard: return "map_type_standard".localized
        case .satellite: return "map_type_satellite".localized
        case .hybrid: return "map_type_hybrid".localized
        case .satelliteFlyOver: return "map_type_satellite_fly_over".localized
        }
    }
    
    // For map type grid preview images
    var previewImageName: String {
        switch self {
        case .standard: return "map_preview_standard"
        case .satellite: return "map_preview_satellite"
        case .hybrid: return "map_preview_hybrid"
        case .satelliteFlyOver: return "map_preview_satellite_fly_over"
        }
    }
}

// Annotation Types
enum AnnotationType: String, CaseIterable, Identifiable {
    case shelter
    case police
    case hospital
    case fireStation
    
    var id: String { rawValue }
    var name: String {
        switch self {
        case .shelter: return "Evacuation Shelter"
        case .police: return "Police Station"
        case .hospital: return "Hospital"
        case .fireStation: return "Fire Station"
        }
    }
    
    var icon: String {
        switch self {
        case .shelter: return "house.fill"
        case .police: return "building.columns.fill"
        case .hospital: return "cross.circle.fill"
        case .fireStation: return "flame.fill"
        }
    }
}

// Font Sizes
enum FontSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large
    case extraLarge
    
    var id: String { rawValue }
    var name: String {
        switch self {
        case .small: return "font_size_small".localized
        case .medium: return "font_size_medium".localized
        case .large: return "font_size_large".localized
        case .extraLarge: return "font_size_extra_large".localized
        }
    }
    
    var size: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        case .extraLarge: return 20
        }
    }
}

// Safety Guide Types
enum SafetyGuideType: String, CaseIterable, Identifiable {
    case tsunami
    case earthquake
    case fire
    
    var id: String { rawValue }
    var title: String {
        switch self {
        case .tsunami: return "Tsunami Safety Guide"
        case .earthquake: return "Earthquake Safety Guide"
        case .fire: return "Fire Safety Guide"
        }
    }
    
    var icon: String { SETTING_ICONS[rawValue]! }
    var color: Color { SETTING_COLORS[rawValue]! }
}

// Data Sources Section
struct DataSourceInfo {
    static let sources = [
        "Shelter Data": "Data provided by Ministry of Land, Infrastructure, Transport and Tourism",
        "Police Data": "Data provided by National Police Agency",
        "Map Data": "Map data © OpenStreetMap contributors"
    ]
    
    static let lastUpdated = "2024-01"
    static let dataLicense = "This data is provided under CC BY 4.0 license"
    static let attributionURL = "https://www.data.go.jp/"
}

// Additional Setting Constants
let SETTING_ROW_HEIGHT: CGFloat = 44
let SETTING_ICON_SIZE: CGFloat = 28
let SETTING_CORNER_RADIUS: CGFloat = 6
let SETTING_HORIZONTAL_PADDING: CGFloat = 16
let MAP_GRID_SPACING: CGFloat = 10
let MAP_PREVIEW_ASPECT_RATIO: CGFloat = 16/9
