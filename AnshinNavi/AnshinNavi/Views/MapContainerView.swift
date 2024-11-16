import SwiftUI
import MapKit
import CoreLocation

struct MapContainerView: View {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @State private var showingShelterDetail = false
    @State private var selectedShelter: Shelter?
    @State private var showingBottomDrawer = true
    @State private var selectedDetent: PresentationDetent = .custom(MainBottomDrawerView.SmallDetent.self)
    @State private var previousDetent: PresentationDetent = .custom(MainBottomDrawerView.SmallDetent.self)

    var body: some View {
        ZStack {
            MapView(selectedDetent: selectedDetent)
                .ignoresSafeArea(.all)
                .environmentObject(shelterViewModel)
                .onReceive(shelterViewModel.$selectedShelter) { shelter in
                    if let shelter = shelter {
                        selectedShelter = shelter
                        previousDetent = selectedDetent // Store current detent
                        withAnimation {
                            showingBottomDrawer = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingShelterDetail = true
                        }
                    }
                }
        }
        .sheet(isPresented: $showingBottomDrawer) {
            MainBottomDrawerView(selectedDetent: $selectedDetent)
                .presentationBackground(.regularMaterial)
        }
        .sheet(isPresented: $showingShelterDetail) {
            if let shelter = selectedShelter {
                DetailedShelterView(shelter: shelter, isPresented: $showingShelterDetail)
                    .onDisappear {
                        selectedDetent = previousDetent // Restore previous detent
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                showingBottomDrawer = true
                            }
                        }
                    }
            }
        }
    }
}
