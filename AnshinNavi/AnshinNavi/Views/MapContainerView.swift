import SwiftUI
import MapKit
import CoreLocation

enum CurrentAnnotationType {
    case shelter
    case none
    // TODO: Add other annotation types
    // case police
    // case fire
    // case ambulance
}

struct MapContainerView: View {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @State private var currentAnnotationType: CurrentAnnotationType = .shelter
    @State private var showingShelterDetail = false
    @State private var selectedShelter: Shelter?
    @State private var showingBottomDrawer = true
    @State private var selectedDetent: PresentationDetent = .custom(MainBottomDrawerView.SmallDetent.self)
    @State private var previousDetent: PresentationDetent = .custom(MainBottomDrawerView.SmallDetent.self)
    @State private var isTransitioning = false

    var body: some View {
        ZStack {
            MapView(selectedDetent: selectedDetent, currentAnnotationType: $currentAnnotationType)
                .ignoresSafeArea(.all)
                .environmentObject(shelterViewModel)
                .onReceive(shelterViewModel.$selectedShelter) { shelter in
                    guard !isTransitioning else { return }
                    
                    if let shelter = shelter {
                        isTransitioning = true
                        selectedShelter = shelter
                        previousDetent = selectedDetent
                        
                        // Close bottom drawer first
                        withAnimation {
                            showingBottomDrawer = false
                        }
                        
                        // Wait for bottom drawer to close completely
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showingShelterDetail = true
                            isTransitioning = false
                        }
                    }
                }
        }
        .sheet(isPresented: $showingBottomDrawer) {
            MainBottomDrawerView(selectedDetent: $selectedDetent, currentAnnotationType: $currentAnnotationType)
                .presentationBackground(.regularMaterial)
        }
        .sheet(isPresented: $showingShelterDetail, onDismiss: {
            selectedShelter = nil
            shelterViewModel.selectedShelter = nil
            
            // Wait a moment before showing bottom drawer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                selectedDetent = previousDetent
                withAnimation {
                    showingBottomDrawer = true
                }
            }
        }) {
            if let shelter = selectedShelter {
                DetailedShelterView(shelter: shelter, isPresented: $showingShelterDetail)
            }
        }
    }
}
