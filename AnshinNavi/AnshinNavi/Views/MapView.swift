import SwiftUI
import MapKit
import CoreLocation

struct MapView: UIViewRepresentable {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    func makeCoordinator() -> Coordinator {
        Coordinator(self, shelterViewModel: shelterViewModel)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        configureMapView(mapView)
        setupLocationServices(context)
        setupMapControls(mapView, with: context)
        
        return mapView
    }
    
    // MARK: - Configuration Methods
    
    /// Configures the initial map view settings
    /// - Parameter mapView: The map view to configure
    /// Sets up basic map properties like showing user location and tracking mode
    private func configureMapView(_ mapView: MKMapView) {
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .default)
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.userTrackingMode = .followWithHeading
    }
    
    /// Sets up location services for the map
    /// - Parameter context: The context containing the coordinator
    /// Configures location manager with appropriate accuracy and permissions
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
        // Compass
        let compass = MKCompassButton(mapView: mapView)
        compass.compassVisibility = .visible
        compass.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(compass)
        context.coordinator.compassButton = compass
        
        // Location button
        let locationButton = createLocationButton(target: context.coordinator)
        mapView.addSubview(locationButton)
        
        // Search button
        let searchButton = createSearchButton(target: context.coordinator)
        searchButton.isHidden = true
        mapView.addSubview(searchButton)
        
        setupConstraints(mapView, compass: compass, location: locationButton, search: searchButton)
        
        context.coordinator.locationButton = locationButton
        context.coordinator.searchButton = searchButton
    }
    
    private func createLocationButton(target: Coordinator) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.15
        
        let image = UIImage(systemName: "location.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .medium))
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(target, action: #selector(Coordinator.locationButtonTapped), for: .touchUpInside)
        
        return button
    }
    
    private func createSearchButton(target: Coordinator) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemBackground
        config.baseForegroundColor = .label
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "magnifyingglass")
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.title = "この地域で検索"
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.15
        button.addTarget(target, action: #selector(Coordinator.searchRegionButtonTapped), for: .touchUpInside)
        
        return button
    }
    
    private func setupConstraints(_ mapView: MKMapView, compass: MKCompassButton?, location: UIButton, search: UIButton) {
        guard let compass = compass else { return }
        NSLayoutConstraint.activate([
            // Compass
            compass.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 10),
            compass.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            // Location button
            location.topAnchor.constraint(equalTo: compass.bottomAnchor, constant: 10),
            location.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            location.widthAnchor.constraint(equalToConstant: 40),
            location.heightAnchor.constraint(equalToConstant: 40),
            
            // Search button - centered at bottom
            search.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            search.bottomAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            search.heightAnchor.constraint(equalToConstant: 36),
            search.widthAnchor.constraint(lessThanOrEqualTo: mapView.widthAnchor, multiplier: 0.7)
        ])
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // No updates needed here since annotations are handled elsewhere
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private let parent: MapView
        var shelterViewModel: ShelterViewModel
        var locationManager: CLLocationManager?
        weak var locationButton: UIButton?
        weak var searchButton: UIButton?
        weak var compassButton: MKCompassButton?
        private var isInitialLocationSet = false
        var shelterHandler: ShelterHandler!
        
        init(_ parent: MapView, shelterViewModel: ShelterViewModel) {
            self.parent = parent
            self.shelterViewModel = shelterViewModel
            super.init()
            self.shelterHandler = ShelterHandler(coordinator: self, shelterViewModel: shelterViewModel)
        }
        
        // Forward delegate methods
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            return shelterHandler.mapView(mapView, viewFor: annotation)
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            shelterHandler.mapView(mapView, annotationView: view, calloutAccessoryControlTapped: control)
        }

        
        func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            guard let mapView = locationButton?.superview as? MKMapView else { return }
            
            if mapView.userTrackingMode == .followWithHeading {
                // Update the map rotation to match the user's heading
                let heading = newHeading.magneticHeading
                mapView.camera.heading = heading
            }
        }
        
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
        
        // MARK: - Location Updates
        
        /// Handles user location updates
        /// - Parameters:
        ///   - manager: The location manager
        ///   - locations: Array of new locations
        /// Only updates map region on initial location set
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.first,
                  let mapView = locationButton?.superview as? MKMapView,
                  !isInitialLocationSet else { return }
            
            isInitialLocationSet = true
            updateMapRegion(mapView, coordinate: location.coordinate)
            shelterHandler.updateAnnotations(on: mapView, near: location)
            manager.stopUpdatingLocation()
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            searchButton?.isHidden = animated
        }
        
        /// Handles location button tap
        /// Centers map on user location and updates tracking mode
        @objc func locationButtonTapped() {
            guard let mapView = locationButton?.superview as? MKMapView else { return }

            mapView.setUserTrackingMode(.followWithHeading, animated: true)
            searchButton?.isHidden = true

            guard let location = locationManager?.location else {
                print("User location is not available.")
                return
            }

            // Call updateAnnotations
            shelterHandler.updateAnnotations(on: mapView, near: location)
        }
        
        @objc func searchRegionButtonTapped() {
            guard let mapView = searchButton?.superview as? MKMapView else { return }
            
            let region = mapView.region
            let centerLocation = CLLocation(
                latitude: region.center.latitude,
                longitude: region.center.longitude
            )
            
            shelterHandler.updateAnnotations(on: mapView, near: centerLocation)
            searchButton?.isHidden = true
        }
        
        private func updateMapRegion(_ mapView: MKMapView, coordinate: CLLocationCoordinate2D) {
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapView.setRegion(region, animated: true)
        }
    }
}
