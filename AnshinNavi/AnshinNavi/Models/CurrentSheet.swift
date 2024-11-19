enum CurrentSheet: Identifiable {
    case bottomDrawer
    case detail
    case settings
    case filter
    
    var id: Int {
        switch self {
        case .bottomDrawer: return 0
        case .detail: return 1
        case .settings: return 2
        case .filter: return 3
        }
    }
}

