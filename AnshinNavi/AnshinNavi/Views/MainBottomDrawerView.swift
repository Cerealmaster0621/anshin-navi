import SwiftUI
import MapKit

struct MainBottomDrawerView: View {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @Binding var selectedDetent: PresentationDetent
    @Binding var currentAnnotationType: CurrentAnnotationType
    @Binding var selectedShelterFilterTypes: [ShelterFilterType]
    @Binding var selectedPoliceTypes: [PoliceType]
    let mapView: MKMapView
    let shelterMapHandler: ShelterMapHandler
    let policeMapHandler: PoliceMapHandler
    
    // Custom detent for 10% height
    struct SmallDetent: CustomPresentationDetent {
        static func height(in context: Context) -> CGFloat? {
            return UIScreen.main.bounds.height * SMALL_DENT_WEIGHT
        }
    }
    
    // Custom detent for 40% height
    struct MediumDetent: CustomPresentationDetent {
        static func height(in context: Context) -> CGFloat? {
            return UIScreen.main.bounds.height * MEDIUM_DENT_WEIGHT
        }
    }
    
    // Get the current height based on the detent
    static func getCurrentHeight(for detent: PresentationDetent) -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        
        switch detent {
        case .custom(SmallDetent.self):
            return screenHeight * SMALL_DENT_WEIGHT
        case .custom(MediumDetent.self):
            return screenHeight * MEDIUM_DENT_WEIGHT
        case .large:
            return screenHeight
        default:
            return screenHeight * SMALL_DENT_WEIGHT
        }
    }
    
    private var isSmallDetent: Bool {
        selectedDetent == .custom(SmallDetent.self)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Drag indicator
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                // Annotation type content
                switch currentAnnotationType {
                    case .shelter:
                        MBDShelterView(
                            currentAnnotationType: $currentAnnotationType,
                            mapView: mapView,
                            shelterMapHandler: shelterMapHandler,
                            policeMapHandler: policeMapHandler,
                            isSmallDetent: isSmallDetent,
                            selectedShelterFilterTypes: selectedShelterFilterTypes
                        )
                    case .police:
                        MBDPoliceView(
                            currentAnnotationType: $currentAnnotationType,
                            mapView: mapView,
                            shelterMapHandler: shelterMapHandler,
                            policeMapHandler: policeMapHandler,
                            isSmallDetent: isSmallDetent,
                            selectedPoliceTypes: selectedPoliceTypes
                        )
                    case .none:
                        EmptyView()
                }
            }
        }
        .presentationDetents(
            [.custom(SmallDetent.self), .custom(MediumDetent.self), .large],
            selection: $selectedDetent
        )
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .interactiveDismissDisabled(true)
    }
}
