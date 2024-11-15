import SwiftUI
import MapKit
import CoreLocation

struct MapView: UIViewRepresentable {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    private static let maxAnnotations = 100
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        configureMapView(mapView, with: context)
        setupLocationServices(context)
        setupMapControls(mapView, with: context)

        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        
        return mapView
    }
    
    private func configureMapView(_ mapView: MKMapView, with context: Context) {
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .default)
        mapView.showsUserLocation = true
        mapView.showsCompass = false
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
        // Debug print
        print("📍 Updating map with \(shelterViewModel.shelters.count) shelters")
        
        // Remove existing annotations
        let existingAnnotations = uiView.annotations.filter { !($0 is MKUserLocation) }
        uiView.removeAnnotations(existingAnnotations)
        
        // Add new annotations
        let annotations = shelterViewModel.shelters.map { shelter -> MKAnnotation in
            let annotation = ShelterAnnotation(shelter: shelter)
            print("📌 Adding shelter: \(shelter.name) at \(shelter.latitude), \(shelter.longitude)")
            return annotation
        }
        
        uiView.addAnnotations(annotations)
    }
    
    // Custom annotation class to store shelter data
    class ShelterAnnotation: MKPointAnnotation {
        let shelter: Shelter
        
        init(shelter: Shelter) {
            self.shelter = shelter
            super.init()
            self.title = shelter.name
            self.subtitle = shelter.address
            self.coordinate = CLLocationCoordinate2D(
                latitude: shelter.latitude,
                longitude: shelter.longitude
            )
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private let parent: MapView
        var locationManager: CLLocationManager?
        weak var locationButton: UIButton?
        weak var searchButton: UIButton?
        weak var compassButton: MKCompassButton?
        private var isInitialLocationSet = false
        
        init(_ parent: MapView) {
            self.parent = parent
            super.init()
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
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.first,
                  let mapView = locationButton?.superview as? MKMapView,
                  !isInitialLocationSet else { return }
            
            isInitialLocationSet = true
            updateMapRegion(mapView, coordinate: location.coordinate)
            updateAnnotations(on: mapView, near: location)
            manager.stopUpdatingLocation()
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            searchButton?.isHidden = animated
        }
        
        @objc func locationButtonTapped() {
            guard let mapView = locationButton?.superview as? MKMapView,
                  let location = locationManager?.location else { return }
            
            // Update tracking mode to show heading
            mapView.setUserTrackingMode(.followWithHeading, animated: true)
            updateAnnotations(on: mapView, near: location)
            searchButton?.isHidden = true
        }
        
        @objc func searchRegionButtonTapped() {
            guard let mapView = searchButton?.superview as? MKMapView else { return }
            
            let region = mapView.region
            let centerLocation = CLLocation(
                latitude: region.center.latitude,
                longitude: region.center.longitude
            )
            
            updateAnnotations(on: mapView, near: centerLocation)
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
        
        private func updateAnnotations(on mapView: MKMapView, near location: CLLocation) {
            let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
            mapView.removeAnnotations(existingAnnotations)
            
            let radius = calculateSearchRadius(from: mapView.region)
            let shelters = parent.shelterViewModel.getSheltersNearLocation(location, radius: radius)
            
            let centerLocation = location
            let sortedShelters = shelters
                .sorted { shelter1, shelter2 in
                    let location1 = CLLocation(latitude: shelter1.latitude, longitude: shelter1.longitude)
                    let location2 = CLLocation(latitude: shelter2.latitude, longitude: shelter2.longitude)
                    return location1.distance(from: centerLocation) < location2.distance(from: centerLocation)
                }
                .prefix(MapView.maxAnnotations)
            
            let annotations = sortedShelters.map { ShelterAnnotation(shelter: $0) }
            mapView.addAnnotations(annotations)
        }
        
        private func calculateSearchRadius(from region: MKCoordinateRegion) -> CLLocationDistance {
            let span = region.span
            let distanceLatitude = span.latitudeDelta * 111000 / 2  // Convert to meters
            let distanceLongitude = span.longitudeDelta * 111000 / 2
            return max(distanceLatitude, distanceLongitude)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                // Use the default system user location view
                return nil
            }
            
            // Handle shelter annotations
            let identifier = "ShelterPin"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            view.canShowCallout = true
            view.markerTintColor = .systemGreen
            view.glyphImage = UIImage(systemName: "house.fill")
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
            return view
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let annotation = view.annotation as? ShelterAnnotation else { return }
            parent.shelterViewModel.selectedShelter = annotation.shelter
        }
    }
}
