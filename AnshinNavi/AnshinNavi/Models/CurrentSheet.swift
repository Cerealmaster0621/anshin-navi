enum CurrentSheet: Identifiable {
    case bottomDrawer
    case shelterDetail
    case settings
    case filter
    
    var id: Int {
        switch self {
        case .bottomDrawer: return 0
        case .shelterDetail: return 1
        case .settings: return 2
        case .filter: return 3
        }
    }
}

