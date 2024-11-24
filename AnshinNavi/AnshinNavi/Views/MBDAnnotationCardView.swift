import SwiftUI
import MapKit

struct MBDAnnotationCardView: View {
    @Binding var currentAnnotationType: CurrentAnnotationType
    let mapView: MKMapView
    let shelterMapHandler: ShelterMapHandler
    let policeMapHandler: PoliceMapHandler
    
    private enum FacilityType {
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
            case .police: return "警察施設"
            }
        }
        
        var activeColor: Color {
            switch self {
            case .shelter: return Color(.systemGreen)
            case .police: return Color(.systemBlue)
            }
        }
        
        func matches(_ annotationType: CurrentAnnotationType) -> Bool {
            switch (self, annotationType) {
            case (.shelter, .shelter), (.police, .police):
                return true
            default:
                return false
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("表示する施設")
                .font(.system(size: FONT_SIZE.size*0.875))
                .foregroundColor(Color(.systemGray))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    facilityButton(for: .shelter)
                    facilityButton(for: .police)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private func facilityButton(for facilityType: FacilityType) -> some View {
        let isActive = facilityType.matches(currentAnnotationType)
        
        return Button(action: {
            withAnimation {
                switch facilityType {
                case .shelter:
                    currentAnnotationType = .shelter
                    NotificationCenter.default.post(
                        name: Notification.Name("search_region_notification".localized),
                        object: nil
                    )
                case .police:
                    currentAnnotationType = .police
                    NotificationCenter.default.post(
                        name: Notification.Name("search_region_notification".localized),
                        object: nil
                    )
                }
            }
        }) {
            VStack(spacing: 6) {
                Circle()
                    .fill(isActive ? facilityType.activeColor : Color(.systemGray5))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: facilityType.icon)
                            .font(.system(size: FONT_SIZE.size * 1))
                            .foregroundColor(isActive ? .white : Color(.systemGray2))
                    )
                Text(facilityType.title)
                    .font(.system(size: FONT_SIZE.size * 0.875))
                    .foregroundColor(isActive ? .primary : Color(.systemGray))
            }
        }
    }
}
