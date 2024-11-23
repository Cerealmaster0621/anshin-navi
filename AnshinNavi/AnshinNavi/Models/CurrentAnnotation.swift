enum CurrentAnnotationType: Int, CaseIterable {
    case shelter = 0
    case police = 1
    case none = 2
    
    var id: Int {
        return self.rawValue
    }
    
    var name: String {
        switch self {
        case .shelter: return "evacuation_area_lowercase".localized
        case .police: return "police_facility_lowercase".localized
        case .none: return ""
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
