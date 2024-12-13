import Foundation
import MapKit
import SwiftUI

final class MapViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var region: MKCoordinateRegion
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var routeViewModel: RouteViewModel // Add this line

    // MARK: - Map Properties
    let mapView: MKMapView
    let shelterMapHandler: ShelterMapHandler
    let policeMapHandler: PoliceMapHandler

    // MARK: - View Model References
    let shelterViewModel: ShelterViewModel
    let policeViewModel: PoliceViewModel

    init(
        region: MKCoordinateRegion = MKCoordinateRegion(),
        shelterViewModel: ShelterViewModel,
        policeViewModel: PoliceViewModel,
        routeViewModel: RouteViewModel // Add this parameter
    ) {
        self.region = region
        self.shelterViewModel = shelterViewModel
        self.policeViewModel = policeViewModel
        self.routeViewModel = routeViewModel

        // Initialize map view
        let map = MKMapView()
        self.mapView = map

        // Create MapView instance
        let mapViewInstance = MapView(
            routeViewModel: routeViewModel,
            selectedDetent: .custom(MainBottomDrawerView.MediumDetent.self),
            currentAnnotationType: .constant(.police),
            activeSheet: .constant(.bottomDrawer),
            previousSheet: .constant(.bottomDrawer),
            isTransitioning: .constant(false),
            selectedShelterFilterTypes: .constant([]),
            selectedPoliceTypes: .constant([])
        )

        // Create coordinator for map handlers
        let coordinator = MapView.Coordinator(
            mapViewInstance,
            shelterViewModel: shelterViewModel,
            policeViewModel: policeViewModel,
            routeViewModel: routeViewModel,
            activeSheet: .constant(.bottomDrawer),
            previousSheet: .constant(.bottomDrawer),
            isTransitioning: .constant(false),
            selectedShelterFilterTypes: .constant([]),
            selectedPoliceTypes: .constant([])
        )

        // Initialize handlers
        self.shelterMapHandler = ShelterMapHandler(
            coordinator: coordinator,
            shelterViewModel: shelterViewModel,
            selectedShelterFilterTypes: .constant([])
        )

        self.policeMapHandler = PoliceMapHandler(
            coordinator: coordinator,
            policeViewModel: policeViewModel,
            selectedPoliceTypes: .constant([])
        )
    }

    // MARK: - Map Interaction Methods

    func updateRegion(_ region: MKCoordinateRegion) {
        self.region = region
    }

    func selectLocation(_ coordinate: CLLocationCoordinate2D) {
        self.selectedLocation = coordinate
    }

    // MARK: - Shelter Methods

    func getSheltersInCurrentRegion() -> [Shelter] {
        return shelterViewModel.getSheltersInMapRegion(region)
    }

    func updateShelterAnnotations() {
        shelterMapHandler.updateAnnotations(on: mapView)
    }

    // MARK: - Police Methods

    func getPoliceStationsInCurrentRegion() -> [PoliceBase] {
        return policeViewModel.getPoliceStationsInMapRegion(region)
    }

    func updatePoliceAnnotations() {
        policeMapHandler.updateAnnotations(on: mapView)
    }

    // MARK: - Annotation Update Methods

    func updateAnnotations(for annotationType: CurrentAnnotationType) {
        switch annotationType {
        case .shelter:
            updateShelterAnnotations()
        case .police:
            updatePoliceAnnotations()
        case .none:
            // Clear annotations if needed
            mapView.removeAnnotations(mapView.annotations)
        }
    }
}
