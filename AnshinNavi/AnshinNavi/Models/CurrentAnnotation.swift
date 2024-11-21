enum CurrentAnnotationType {
    case shelter
    case none
    // TODO: Add other annotation types
     case police
    var id: Int {
        switch self {
        case .shelter: return 0
        case .none: return 1
        case .police: return 2
        }
    }
}

    
enum FacilityType {
        case shelter
        case police
        
        var icon: String {
            switch self {
            case .shelter: return "house.fill"
            case .police: return "building.columns.fill"
            }
        }
        
        var title: String {
            switch self {
            case .shelter: return "避難施設"
            case .police: return "警察署"
            }
        }
    }
