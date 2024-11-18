import SwiftUI
import MapKit
import CoreLocation

struct MapContainerView: View {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @State private var currentAnnotationType: CurrentAnnotationType = .shelter
    @State private var selectedShelter: Shelter?
    @State private var selectedDetent: PresentationDetent = .custom(MainBottomDrawerView.SmallDetent.self)
    @State private var previousDetent: PresentationDetent = .custom(MainBottomDrawerView.SmallDetent.self)
    @State private var isTransitioning = false
    @State private var activeSheet: CurrentSheet? = .bottomDrawer
    @State private var previousSheet: CurrentSheet? = nil
    @State private var selectedShelterFilterTypes: [ShelterFilterType] = []
    
    var body: some View {
        ZStack {
            MapView(selectedDetent: selectedDetent,
                    currentAnnotationType: $currentAnnotationType,
                    activeSheet: $activeSheet,
                    isTransitioning: $isTransitioning,
                    selectedShelterFilterTypes: $selectedShelterFilterTypes
                    )
                .ignoresSafeArea(.all)
                .environmentObject(shelterViewModel)
                .onReceive(shelterViewModel.$selectedShelter) { shelter in
                    if let shelter = shelter {
                        handleShelterSelection(shelter)
                    }
                }
        }
        .sheet(item: $activeSheet, onDismiss: handleSheetDismissal) { sheet in
            switch sheet {
            case .bottomDrawer:
                MainBottomDrawerView(selectedDetent: $selectedDetent,
                                   currentAnnotationType: $currentAnnotationType)
                    .presentationBackground(.regularMaterial)
                    .interactiveDismissDisabled()
            
            case .shelterDetail:
                if let shelter = selectedShelter {
                    DetailedShelterView(shelter: shelter, isPresented: $isTransitioning)
                        .presentationDragIndicator(.visible)
                }
            
            case .settings:
                SettingDrawerView()
                    .presentationDragIndicator(.visible)
            
            case .filter:
                FilterDrawerView(
                    currentAnnotationType: currentAnnotationType,
                    selectedShelterFilterTypes: $selectedShelterFilterTypes
                )
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func handleSheetDismissal() {
        guard !isTransitioning else { return }
        
        isTransitioning = true
        
        if activeSheet == nil {
            activeSheet = .bottomDrawer
        }
        
        isTransitioning = false
    }
    
    private func handleShelterSelection(_ shelter: Shelter) {
        guard !isTransitioning else { return }
        
        isTransitioning = true
        selectedShelter = shelter
        previousDetent = selectedDetent
        previousSheet = activeSheet
        
        if activeSheet != .shelterDetail {
            activeSheet = .shelterDetail
        }
        
        isTransitioning = false
    }
}
