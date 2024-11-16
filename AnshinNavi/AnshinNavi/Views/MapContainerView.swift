import SwiftUI
import MapKit
import CoreLocation

struct MapContainerView: View {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @State private var showingShelterDetail = false
    @State private var selectedShelter: Shelter?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                // Main Map View
                MapView()
                    .ignoresSafeArea(.all)
                    .environmentObject(shelterViewModel)
                    .onReceive(shelterViewModel.$selectedShelter) { shelter in
                        if let shelter = shelter {
                            selectedShelter = shelter
                            showingShelterDetail = true
                        }
                    }
            }
        }
        .sheet(isPresented: $showingShelterDetail) {
            if let shelter = selectedShelter {
                DetailedShelterView(shelter: shelter, isPresented: $showingShelterDetail)
            }
        }
    }
}
