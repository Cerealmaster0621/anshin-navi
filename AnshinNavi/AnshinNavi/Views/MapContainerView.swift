import SwiftUI
import MapKit
import CoreLocation

struct MapContainerView: View {
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @EnvironmentObject var policeViewModel: PoliceViewModel
    @State private var currentAnnotationType: CurrentAnnotationType = ANNOTATION_TYPE// DEFAULT ANNOTATION
    @State private var selectedShelter: Shelter?
    @State private var selectedPoliceBase: PoliceBase?
    @State private var selectedDetent: PresentationDetent = .custom(MainBottomDrawerView.SmallDetent.self)
    @State private var previousDetent: PresentationDetent = .custom(MainBottomDrawerView.SmallDetent.self)
    @State private var isTransitioning = false
    @State private var activeSheet: CurrentSheet? = .bottomDrawer
    @State private var previousSheet: CurrentSheet? = nil
    @State private var selectedShelterFilterTypes: [ShelterFilterType] = []
    @State private var selectedPoliceTypes: [PoliceType] = []

    var body: some View {
        ZStack {
            MapView(selectedDetent: selectedDetent,
                    currentAnnotationType: $currentAnnotationType,
                    activeSheet: $activeSheet,
                    previousSheet: $previousSheet,
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
        .onAppear {
            observeSettingsChanges()
        }
        .sheet(item: $activeSheet, onDismiss: handleSheetDismissal) { sheet in
            //<-----SHEET CHANGE LOGIC----->
            switch sheet {
            case .bottomDrawer:
                MainBottomDrawerView(selectedDetent: $selectedDetent,
                                     currentAnnotationType: $currentAnnotationType, selectedShelterFilterTypes: $selectedShelterFilterTypes, selectedPoliceTypes: $selectedPoliceTypes, mapView: mapViewModel.mapView, shelterMapHandler: mapViewModel.shelterMapHandler, policeMapHandler: mapViewModel.policeMapHandler)
                    .presentationBackground(.regularMaterial)
                    .interactiveDismissDisabled()
            
            case .detail:
                switch currentAnnotationType {
                    //<-----SHELTER DETAIL DRAWER OPENED----->
                    case .shelter:
                        if let shelter = selectedShelter {
                            DetailedShelterView(shelter: shelter, activeSheet: $activeSheet, previousSheet: $previousSheet)
                                .presentationDragIndicator(.visible)
                        }
                    case .police:
                        if let policeBase = selectedPoliceBase {
                            DetailedPoliceBaseView(policeBase: policeBase, activeSheet: $activeSheet, previousSheet: $previousSheet)
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
                    selectedShelterFilterTypes: $selectedShelterFilterTypes,
                    selectedPoliceTypes: $selectedPoliceTypes
                )
                    .presentationDragIndicator(.visible)
            case .navigation:
                switch currentAnnotationType {
                case .shelter:
                    if let selectedShelter = shelterViewModel.selectedShelter {
                        NavigationDrawerView(
                            destinationType: .shelter(selectedShelter),
                            activeSheet: $activeSheet,
                            previousSheet: $previousSheet
                        )
                        .presentationBackground(.clear)
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled)
                    }
                case .police:
                    if let selectedPolice = policeViewModel.selectedPoliceStation {
                        NavigationDrawerView(
                            destinationType: .police(selectedPolice),
                            activeSheet: $activeSheet,
                            previousSheet: $previousSheet
                        )
                        .presentationBackground(.clear)
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled)
                    }
                case .none:
                    EmptyView()
                }
            }
        }
    }
    
    private func updateSheets(newSheet: CurrentSheet?) {
        guard !isTransitioning else { return }
        isTransitioning = true
        
        previousSheet = activeSheet  // Store current as previous
        activeSheet = newSheet      // Update to new sheet
        
        isTransitioning = false
    }
    
    private func handleSheetDismissal() {
        guard !isTransitioning else { return }
        isTransitioning = true

        // When a sheet is dismissed, return to bottom drawer
        if activeSheet == nil {
            activeSheet = .bottomDrawer
        }
        // real prev
        print("prev prev : ",previousSheet)
        
        // Store the current sheet as previous before changing it
        previousSheet = activeSheet
        
        // When a sheet is dismissed, return to bottom drawer
        if activeSheet == nil {
            activeSheet = .bottomDrawer
        }
        
        // real act
        print("aft act : ",activeSheet)

        // Handle filter sheet dismissal
        if previousSheet == .filter {
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
        
        // Add pin first to ensure map updates
        shelterViewModel.addPinAndCenterCamera(for: shelter)
        
        previousSheet = activeSheet
        activeSheet = .detail
        
        isTransitioning = false
    }
    
    private func handlePoliceSelection(_ police: PoliceBase) {
        guard !isTransitioning else { return }
        isTransitioning = true
        
        selectedPoliceBase = police
        previousDetent = selectedDetent
        
        // Add pin first to ensure map updates
        policeViewModel.addPinAndCenterCamera(for: police)
        
        previousSheet = activeSheet
        activeSheet = .detail
        
        isTransitioning = false
    }

    private func observeSettingsChanges() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("settings_updated"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let maxAnnotations = userInfo["maxAnnotations"] as? Int,
               let defaultAnnotationType = userInfo["defaultAnnotationType"] as? CurrentAnnotationType {
                // Update the constants
                UserDefaults.standard.set(maxAnnotations, forKey: "MaxAnnotations")
                UserDefaults.standard.set(defaultAnnotationType.rawValue, forKey: "DefaultAnnotationType")
                
                // Trigger map refresh
                NotificationCenter.default.post(
                    name: Notification.Name("search_region_notification".localized),
                    object: nil
                )
            }
        }
    }
}
