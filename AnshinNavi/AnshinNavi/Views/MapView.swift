import SwiftUI
import MapKit
import CoreLocation

// Define a RouteViewModel to manage route-related state
class RouteViewModel: ObservableObject {
    @Published var destinationCoordinate: CLLocationCoordinate2D?
    @Published var shouldShowRoute: Bool = false
    @Published var shouldUpdateRoute: Bool = false
    @Published var shouldClearRoute: Bool = false
}

struct MapView: UIViewRepresentable {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @EnvironmentObject var policeViewModel: PoliceViewModel
    @ObservedObject var routeViewModel: RouteViewModel
    var selectedDetent: PresentationDetent
    @Binding var currentAnnotationType: CurrentAnnotationType
    @Binding var activeSheet: CurrentSheet?
    @Binding var previousSheet : CurrentSheet?
    @Binding var isTransitioning: Bool
    @Binding var selectedShelterFilterTypes: [ShelterFilterType]
    @Binding var selectedPoliceTypes: [PoliceType]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            self,
            shelterViewModel: shelterViewModel,
            policeViewModel: policeViewModel,
            routeViewModel: routeViewModel,
            activeSheet: $activeSheet,
            previousSheet: $previousSheet,
            isTransitioning: $isTransitioning,
            selectedShelterFilterTypes: $selectedShelterFilterTypes,
            selectedPoliceTypes: $selectedPoliceTypes
        )
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Set the mapView reference in ViewModels
        shelterViewModel.mapView = mapView
        policeViewModel.mapView = mapView
        
        configureMapView(mapView)
        setupLocationServices(context)
        setupMapControls(mapView, with: context)
        
        // Add observer for filter updates
        NotificationCenter.default.addObserver(
            forName: Notification.Name("search_region_notification".localized),
            object: nil,
            queue: .main
        ) { [context] _ in
            switch currentAnnotationType {
            case .shelter:
                context.coordinator.shelterMapHandler.updateAnnotations(on: mapView)
            case .police:
                context.coordinator.policeMapHandler.updateAnnotations(on: mapView)
            case .none:
                break
            }
        }
        
        // Add observer for settings updates
        NotificationCenter.default.addObserver(
            forName: Notification.Name("settings_updated"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let mapType = userInfo["mapType"] as? MapType {
                // Update map type
                switch mapType {
                case .standard:
                    mapView.mapType = .standard
                case .satellite:
                    mapView.mapType = .satellite
                case .hybrid:
                    mapView.mapType = .hybrid
                case .satelliteFlyOver:
                    mapView.mapType = .satelliteFlyover
                }
            }
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.updateSearchButtonPosition(uiView, for: selectedDetent)
        
        // Handle route updates
        if routeViewModel.shouldShowRoute, let destination = routeViewModel.destinationCoordinate {
            context.coordinator.showRoute(to: destination)
            routeViewModel.shouldShowRoute = false
        }
        if routeViewModel.shouldUpdateRoute, let destination = routeViewModel.destinationCoordinate {
            context.coordinator.updateRoute(to: destination)
            routeViewModel.shouldUpdateRoute = false
        }
        if routeViewModel.shouldClearRoute {
            context.coordinator.clearRoute()
            routeViewModel.shouldClearRoute = false
        }
    }
    
    // MARK: - Configuration Methods
    
    private func configureMapView(_ mapView: MKMapView) {
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .default)
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.userTrackingMode = .followWithHeading
    }
    
    private func setupLocationServices(_ context: Context) {
        let locationManager = CLLocationManager()
        locationManager.delegate = context.coordinator
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 5
        context.coordinator.locationManager = locationManager
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingHeading()
    }
    
    private func setupMapControls(_ mapView: MKMapView, with context: Context) {
        // Create right side controls
        let rightSideView = MapRightSideView(mapView: mapView, coordinator: context.coordinator, currentAnnotationType: $currentAnnotationType)
        context.coordinator.compassButton = rightSideView.compassButton
        context.coordinator.locationButton = rightSideView.locationButton
        context.coordinator.settingsButton = rightSideView.settingsButton
        if currentAnnotationType != .none {
            context.coordinator.filterButton = rightSideView.filterButton
        }
    
        // Let coordinator setup the search button
        context.coordinator.setupSearchButton(on: mapView, for: selectedDetent)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private let parent: MapView
        var shelterViewModel: ShelterViewModel
        var policeViewModel: PoliceViewModel
        var routeViewModel: RouteViewModel
        var locationManager: CLLocationManager?
        weak var locationButton: UIButton?
        weak var searchButton: UIButton?
        weak var settingsButton: UIButton?
        weak var filterButton: UIButton?
        weak var compassButton: MKCompassButton?
        private var isInitialLocationSet = false
        var shelterMapHandler: ShelterMapHandler!
        var policeMapHandler: PoliceMapHandler!
        weak var searchButtonBottomConstraint: NSLayoutConstraint?
        private var searchButtonTimer: Timer?
        private var isMapScrolling = false
        private let searchButtonAnimationDuration: TimeInterval = 0.3
        @Binding var activeSheet: CurrentSheet?
        @Binding var previousSheet: CurrentSheet?
        @Binding var isTransitioning: Bool
        @Binding var selectedShelterFilterTypes: [ShelterFilterType]
        @Binding var selectedPoliceTypes: [PoliceType]
        var currentRouteOverlay: MKOverlay?
        
        init(
            _ parent: MapView,
            shelterViewModel: ShelterViewModel,
            policeViewModel: PoliceViewModel,
            routeViewModel: RouteViewModel,
            activeSheet: Binding<CurrentSheet?>,
            previousSheet: Binding<CurrentSheet?>,
            isTransitioning: Binding<Bool>,
            selectedShelterFilterTypes: Binding<[ShelterFilterType]>,
            selectedPoliceTypes: Binding<[PoliceType]>
        ) {
            self.parent = parent
            self.shelterViewModel = shelterViewModel
            self.policeViewModel = policeViewModel
            self.routeViewModel = routeViewModel
            self._activeSheet = activeSheet
            self._previousSheet = previousSheet
            self._isTransitioning = isTransitioning
            self._selectedShelterFilterTypes = selectedShelterFilterTypes
            self._selectedPoliceTypes = selectedPoliceTypes
            super.init()
            
            self.shelterMapHandler = ShelterMapHandler(
                coordinator: self,
                shelterViewModel: shelterViewModel,
                selectedShelterFilterTypes: selectedShelterFilterTypes
            )
            
            self.policeMapHandler = PoliceMapHandler(
                coordinator: self,
                policeViewModel: policeViewModel,
                selectedPoliceTypes: selectedPoliceTypes
            )
        }
        
        // MARK: - MKMapViewDelegate Methods
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            switch parent.currentAnnotationType {
            case .shelter:
                return shelterMapHandler.mapView(mapView, viewFor: annotation)
            case .police:
                return policeMapHandler.mapView(mapView, viewFor: annotation)
            case .none:
                return nil
            }
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            switch parent.currentAnnotationType {
            case .shelter:
                shelterMapHandler.mapView(mapView, annotationView: view, calloutAccessoryControlTapped: control)
            case .police:
                policeMapHandler.mapView(mapView, annotationView: view, calloutAccessoryControlTapped: control)
            case .none:
                break
            }
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            isMapScrolling = true
            searchButtonTimer?.invalidate()
            
            UIView.animate(withDuration: searchButtonAnimationDuration,
                           delay: 0,
                           options: [.curveEaseOut]) {
                self.searchButton?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.searchButton?.alpha = 0
            } completion: { _ in
                self.searchButton?.isHidden = true
                self.searchButton?.transform = .identity
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            isMapScrolling = false
            searchButtonTimer?.invalidate()
            
            searchButtonTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                guard let self = self, !self.isMapScrolling else { return }
                
                if case .large = self.parent.selectedDetent {
                    return
                }
                
                self.searchButton?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.searchButton?.alpha = 0
                self.searchButton?.isHidden = false
                
                UIView.animate(withDuration: self.searchButtonAnimationDuration,
                               delay: 0,
                               usingSpringWithDamping: 0.8,
                               initialSpringVelocity: 0.5,
                               options: [.curveEaseOut]) {
                    self.searchButton?.transform = .identity
                    self.searchButton?.alpha = 1
                }
            }
        }
        
        // Handle rendering of route overlay
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // MARK: - CLLocationManagerDelegate Methods
        
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            if manager.authorizationStatus == .authorizedWhenInUse ||
                manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.first,
                  let mapView = locationButton?.superview as? MKMapView,
                  !isInitialLocationSet else { return }
            
            isInitialLocationSet = true
            updateMapRegion(mapView, coordinate: location.coordinate)
            
            manager.stopUpdatingLocation()
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            guard let mapView = locationButton?.superview as? MKMapView else { return }
            
            if mapView.userTrackingMode == .followWithHeading {
                let heading = newHeading.magneticHeading
                mapView.camera.heading = heading
            }
        }
        
        // MARK: - Button Actions
        
        @objc func locationButtonTapped() {
            guard let mapView = locationButton?.superview as? MKMapView else { return }
            
            mapView.setUserTrackingMode(.followWithHeading, animated: true)
            
            // Handle search button animation
            UIView.animate(withDuration: searchButtonAnimationDuration,
                           delay: 0,
                           options: [.curveEaseOut]) {
                self.searchButton?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.searchButton?.alpha = 0
            } completion: { _ in
                self.searchButton?.isHidden = true
                self.searchButton?.transform = .identity
            }
            
            searchButtonTimer?.invalidate()
            
            guard (locationManager?.location) != nil else {
                print("user_location_unavailable".localized)
                return
            }
            
            switch parent.currentAnnotationType {
            case .shelter:
                shelterMapHandler.updateAnnotations(on: mapView)
            case .police:
                policeMapHandler.updateAnnotations(on: mapView)
            case .none:
                break
            }
        }
        
        @objc func searchRegionButtonTapped() {
            guard let mapView = searchButton?.superview as? MKMapView else { return }
            
            UIView.animate(withDuration: searchButtonAnimationDuration,
                           delay: 0,
                           options: [.curveEaseOut]) {
                self.searchButton?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.searchButton?.alpha = 0
            } completion: { _ in
                self.searchButton?.isHidden = true
                self.searchButton?.transform = .identity
            }
            switch parent.currentAnnotationType {
            case .shelter:
                searchButtonTimer?.invalidate()
                shelterMapHandler.updateAnnotations(on: mapView)
            case .police:
                searchButtonTimer?.invalidate()
                policeMapHandler.updateAnnotations(on: mapView)
            case .none:
                break
            }
        }
        
        @objc func settingButtonTapped() {
            guard !isTransitioning else { return }
            isTransitioning = true
            
            if activeSheet == .settings {
                withAnimation {
                    activeSheet = .bottomDrawer
                }
            } else {
                withAnimation {
                    activeSheet = .settings
                }
            }
            
            DispatchQueue.main.async {
                self.isTransitioning = false
            }
        }
        
        @objc func filterButtonTapped() {
            guard !isTransitioning else { return }
            isTransitioning = true
            
            previousSheet = activeSheet
            
            if activeSheet == .filter {
                withAnimation {
                    activeSheet = .bottomDrawer
                }
            } else {
                withAnimation {
                    activeSheet = .filter
                }
            }
            
            DispatchQueue.main.async {
                self.isTransitioning = false
            }
        }
        
        // MARK: - Route Functions
        
        func showRoute(to destinationCoordinate: CLLocationCoordinate2D) {
            guard let mapView = self.locationButton?.superview as? MKMapView else { return }
            guard let userLocation = mapView.userLocation.location else { return }
            
            // Remove existing route overlay if any
            if let overlay = currentRouteOverlay {
                mapView.removeOverlay(overlay)
            }
            
            // Create the request
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
            request.transportType = .walking
            
            let directions = MKDirections(request: request)
            directions.calculate { [weak self] response, error in
                guard let self = self, let route = response?.routes.first else {
                    // Handle error
                    return
                }
                self.currentRouteOverlay = route.polyline
                mapView.addOverlay(route.polyline)
                
                // Adjust the map region to fit the route
                mapView.setVisibleMapRect(
                    route.polyline.boundingMapRect,
                    edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
                    animated: true
                )
            }
        }
        
        func updateRoute(to destinationCoordinate: CLLocationCoordinate2D) {
            guard let mapView = self.locationButton?.superview as? MKMapView else { return }
            guard let userLocation = mapView.userLocation.location else { return }
            
            // Remove existing route overlay if any
            if let overlay = currentRouteOverlay {
                mapView.removeOverlay(overlay)
            }
            
            // Create the request
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
            request.transportType = .walking
            
            let directions = MKDirections(request: request)
            directions.calculate { [weak self] response, error in
                guard let self = self, let route = response?.routes.first else {
                    // Handle error
                    return
                }
                self.currentRouteOverlay = route.polyline
                mapView.addOverlay(route.polyline)
                // Don't adjust the map region
            }
        }
        
        func clearRoute() {
            guard let mapView = self.locationButton?.superview as? MKMapView else { return }
            
            if let overlay = currentRouteOverlay {
                mapView.removeOverlay(overlay)
                currentRouteOverlay = nil
            }
        }
        
        // MARK: - Helper Methods
        
        private func updateMapRegion(_ mapView: MKMapView, coordinate: CLLocationCoordinate2D) {
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapView.setRegion(region, animated: true)
        }
        
        func updateSearchButtonPosition(_ mapView: MKMapView, for detent: PresentationDetent) {
            let drawerHeight = MainBottomDrawerView.getCurrentHeight(for: detent)
            let newSearchButtonPadding: CGFloat = -(drawerHeight + MAIN_DRAWER_SEARCH_BOX_PADDING)
            let shouldHide = detent == .large || isMapScrolling
            
            // Update the existing constraint's constant
            searchButtonBottomConstraint?.constant = newSearchButtonPadding
            
            if shouldHide && !(searchButton?.isHidden ?? true) {
                UIView.animate(withDuration: searchButtonAnimationDuration,
                               delay: 0,
                               options: [.curveEaseOut]) {
                    self.searchButton?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    self.searchButton?.alpha = 0
                    self.searchButton?.superview?.layoutIfNeeded()
                } completion: { _ in
                    self.searchButton?.isHidden = true
                    self.searchButton?.transform = .identity
                }
            } else if !shouldHide && (searchButton?.isHidden ?? false) {
                self.searchButton?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.searchButton?.alpha = 0
                self.searchButton?.isHidden = false
                
                UIView.animate(withDuration: self.searchButtonAnimationDuration,
                               delay: 0,
                               usingSpringWithDamping: 0.8,
                               initialSpringVelocity: 0.5,
                               options: [.curveEaseOut]) {
                    self.searchButton?.transform = .identity
                    self.searchButton?.alpha = 1
                    self.searchButton?.superview?.layoutIfNeeded()
                }
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.searchButton?.superview?.layoutIfNeeded()
                }
            }
        }
        
        func setupSearchButton(on mapView: MKMapView, for detent: PresentationDetent) {
            let searchButton = UIButton(type: .system)
            searchButton.translatesAutoresizingMaskIntoConstraints = false
            
            // Configure button
            var config = UIButton.Configuration.plain()
            config.title = "search_this_area".localized
            config.image = UIImage(systemName: "magnifyingglass")
            config.imagePadding = 8
            config.imagePlacement = .leading
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            config.background.backgroundColor = .systemBackground
            searchButton.configuration = config
            
            searchButton.addTarget(self, action: #selector(searchRegionButtonTapped), for: .touchUpInside)
            
            // Setup shadow and corner radius
            searchButton.layer.cornerRadius = 18
            searchButton.layer.shadowColor = UIColor.black.cgColor
            searchButton.layer.shadowOffset = CGSize(width: 0, height: 2)
            searchButton.layer.shadowRadius = 4
            searchButton.layer.shadowOpacity = 0.1
            
            mapView.addSubview(searchButton)
            
            let initialDrawerHeight = MainBottomDrawerView.getCurrentHeight(for: detent)
            let initialSearchButtonPadding: CGFloat = -(initialDrawerHeight + MAIN_DRAWER_SEARCH_BOX_PADDING)
            
            let bottomConstraint = searchButton.bottomAnchor.constraint(
                equalTo: mapView.safeAreaLayoutGuide.bottomAnchor,
                constant: initialSearchButtonPadding
            )
            
            NSLayoutConstraint.activate([
                searchButton.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
                bottomConstraint,
                searchButton.heightAnchor.constraint(equalToConstant: 36),
                searchButton.widthAnchor.constraint(lessThanOrEqualTo: mapView.widthAnchor, multiplier: 0.7)
            ])
            
            self.searchButton = searchButton
            self.searchButtonBottomConstraint = bottomConstraint
        }
    }
}

// Extension for new search when closing filter sheet
extension MapView {
    static let searchRegionNotification = NotificationCenter.default.publisher(
        for: Notification.Name("search_region_notification".localized)
    )
}
