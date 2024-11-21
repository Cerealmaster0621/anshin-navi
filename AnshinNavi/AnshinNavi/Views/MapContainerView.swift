import SwiftUI
import MapKit
import CoreLocation

struct MapContainerView: View {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @EnvironmentObject var policeViewModel: PoliceViewModel
    @State private var currentAnnotationType: CurrentAnnotationType = .police// DEFAULT ANNOTATION
    @State private var selectedShelter: Shelter?
    @State private var selectedPoliceBase: PoliceBase?
    @State private var selectedDetent: PresentationDetent = .custom(MainBottomDrawerView.SmallDetent.self)
    @State private var previousDetent: PresentationDetent = .custom(MainBottomDrawerView.SmallDetent.self)
    @State private var isTransitioning = false
    @State private var activeSheet: CurrentSheet? = .bottomDrawer
    @State private var previousSheet: CurrentSheet? = nil
    @State private var selectedShelterFilterTypes: [ShelterFilterType] = []
    @State private var selectedPoliceTypes: [PoliceType] = [.honbu,.keisatsusho,.koban]

    var body: some View {
        ZStack {
            MapView(selectedDetent: selectedDetent,
                    currentAnnotationType: $currentAnnotationType,
                    activeSheet: $activeSheet,
                    isTransitioning: $isTransitioning,
                    selectedShelterFilterTypes: $selectedShelterFilterTypes,
                    selectedPoliceTypes: $selectedPoliceTypes
                    )
                .ignoresSafeArea(.all)
                .environmentObject(shelterViewModel)
                .environmentObject(policeViewModel)
                .onReceive(shelterViewModel.$selectedShelter) { shelter in
                    if let shelter = shelter {
                        handleShelterSelection(shelter)
                    }
                }
                .onReceive(policeViewModel.$selectedPoliceStation) { police in
                    if let police = police {
                        handlePoliceSelection(police)
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
                        if let policeBase = selectedPoliceBase {
                            DetailedPoliceBaseView(policeBase: policeBase, activeSheet: $activeSheet)
                                .presentationDragIndicator(.visible)
                        }
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
                name: Notification.Name("search_region_notification".localized),
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

    private func handlePoliceSelection(_ police: PoliceBase) {
        guard !isTransitioning else { return }
        
        isTransitioning = true
        selectedPoliceBase = police
        previousDetent = selectedDetent
        previousSheet = activeSheet
        
        policeViewModel.addPinAndCenterCamera(for: police)
        
        if activeSheet != .detail {
            activeSheet = .detail
        }
        
        isTransitioning = false
    }
}
