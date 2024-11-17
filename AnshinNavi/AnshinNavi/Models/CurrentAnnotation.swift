enum CurrentAnnotationType {
    case shelter
    case none
    // TODO: Add other annotation types
    // case police
    // case fire
    // case ambulance
    var id: Int {
        switch self {
        case .shelter: return 0
        case .none: return 1
        }
    }
}
