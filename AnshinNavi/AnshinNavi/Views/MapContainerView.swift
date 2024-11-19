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
            //<-----SHEET CHANGE LOGIC----->
            switch sheet {
            case .bottomDrawer:
                MainBottomDrawerView(selectedDetent: $selectedDetent,
                                     currentAnnotationType: $currentAnnotationType, selectedShelterFilterTypes: $selectedShelterFilterTypes)
                    .presentationBackground(.regularMaterial)
                    .interactiveDismissDisabled()
            
            case .detail:
                switch currentAnnotationType {
                    //<-----SHELTER DETAIL DRAWER OPENED----->
                    case .shelter:
                        if let shelter = selectedShelter {
                            DetailedShelterView(shelter: shelter, activeSheet: $activeSheet)
                                .presentationDragIndicator(.visible)
                        }
                    case .police:
                        EmptyView()
                    case .none:
                        EmptyView()
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
        .onChange(of: activeSheet) { oldValue in
            if oldValue != nil {
                previousSheet = oldValue
            }
        }
    }
    
    private func handleSheetDismissal() {
        guard !isTransitioning else { return }
        
        isTransitioning = true
        
        if activeSheet == nil {
            activeSheet = .bottomDrawer
        }

        if previousSheet == .filter, activeSheet != .filter {
            NotificationCenter.default.post(
                name: Notification.Name("searchRegion"),
                object: nil
            )
        }
        
        isTransitioning = false
    }
    
    private func handleShelterSelection(_ shelter: Shelter) {
        guard !isTransitioning else { return }
        
        isTransitioning = true
        selectedShelter = shelter
        previousDetent = selectedDetent
        previousSheet = activeSheet
        
        shelterViewModel.addPinAndCenterCamera(for: shelter)
        
        if activeSheet != .detail {
            activeSheet = .detail
        }
        
        isTransitioning = false
    }
}
