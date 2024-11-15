import SwiftUI
import MapKit
import CoreLocation

struct MapView: UIViewRepresentable {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        // Basic setup
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        // Map configuration
        let configuration = MKStandardMapConfiguration()
        configuration.elevationStyle = .flat
        configuration.emphasisStyle = .default
        mapView.preferredConfiguration = configuration
        
        // Setup compass
        mapView.showsCompass = false
        let compassButton = MKCompassButton(mapView: mapView)
        compassButton.compassVisibility = .visible
        mapView.addSubview(compassButton)
        
        // Setup location button
        let locationButton = createLocationButton()
        locationButton.addTarget(context.coordinator, 
                               action: #selector(Coordinator.locationButtonTapped),
                               for: .touchUpInside)
        mapView.addSubview(locationButton)
        
        // Setup search region button
        let searchButton = createSearchButton()
        searchButton.addTarget(context.coordinator,
                             action: #selector(Coordinator.searchRegionButtonTapped),
                             for: .touchUpInside)
        searchButton.isHidden = true
        mapView.addSubview(searchButton)
        
        // Setup constraints
        setupConstraints(mapView, compassButton, locationButton, searchButton)
        
        // Store references
        context.coordinator.locationButton = locationButton
        context.coordinator.searchButton = searchButton
        
        return mapView
    }
    
    private func createLocationButton() -> UIButton {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Style
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 8
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.15
        
        // Icon
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let image = UIImage(systemName: "location.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
        
        return button
    }
    
    private func createSearchButton() -> UIButton {
        let button = UIButton(configuration: .filled())
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Style
        button.configuration?.baseBackgroundColor = .systemBackground
        button.configuration?.baseForegroundColor = .label
        button.configuration?.cornerStyle = .medium
        
        // Icon and text
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let image = UIImage(systemName: "magnifyingglass", withConfiguration: config)
        button.configuration?.image = image
        button.configuration?.imagePlacement = .leading
        button.configuration?.imagePadding = 6
        button.configuration?.title = "この地域で検索"
        
        // Shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.15
        
        return button
    }
    
    private func setupConstraints(_ mapView: MKMapView, _ compass: MKCompassButton, _ location: UIButton, _ search: UIButton) {
        NSLayoutConstraint.activate([
            // Compass
            compass.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 10),
            compass.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            // Location button
            location.topAnchor.constraint(equalTo: compass.bottomAnchor, constant: 20),
            location.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            location.widthAnchor.constraint(equalToConstant: 40),
            location.heightAnchor.constraint(equalToConstant: 40),
            
            // Search button
            search.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            search.bottomAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            search.heightAnchor.constraint(equalToConstant: 36),
            search.widthAnchor.constraint(lessThanOrEqualTo: mapView.widthAnchor, multiplier: 0.7)
        ])
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Remove existing annotations
        let nonUserAnnotations = uiView.annotations.filter { !($0 is MKUserLocation) }
        uiView.removeAnnotations(nonUserAnnotations)
        
        // Debug print to verify data
        print("Number of shelters: \(shelterViewModel.shelters.count)")
        
        // Create annotations for all shelters
        let annotations = shelterViewModel.shelters.map { shelter -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.title = shelter.name
            annotation.subtitle = shelter.address
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: shelter.latitude,
                longitude: shelter.longitude
            )
            return annotation
        }
        
        // Add annotations to map
        uiView.addAnnotations(annotations)
        print("Added \(annotations.count) annotations")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var parent: MapView
        var locationManager: CLLocationManager?
        weak var locationButton: UIButton?
        weak var searchButton: UIButton?

        init(_ parent: MapView) {
            self.parent = parent
            super.init()
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
            self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager?.requestWhenInUseAuthorization()
            self.locationManager?.startUpdatingLocation()
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation,
               let shelter = parent.shelterViewModel.shelters.first(where: { $0.name == annotation.title }) {
                parent.shelterViewModel.selectedShelter = shelter
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Return nil for user location to use default blue dot
            if annotation is MKUserLocation {
                return nil
            }
            
            // Setup shelter annotation view
            let identifier = "ShelterAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                // Customize the marker
                annotationView?.markerTintColor = .systemGreen
                annotationView?.glyphImage = UIImage(systemName: "house.fill")
                
                // Add a right callout accessory
                let button = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = button
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }

        @objc func searchRegionButtonTapped() {
            guard let mapView = searchButton?.superview as? MKMapView else { return }
            
            // Get visible region
            let visibleRegion = mapView.region
            let nearbyShelters = parent.shelterViewModel.getSheltersInMapRegion(visibleRegion)
            print("Found \(nearbyShelters.count) shelters in visible region")
            
            // Update annotations
            updateAnnotations(on: mapView, with: nearbyShelters)
            searchButton?.isHidden = true
        }
        
        private func updateAnnotations(on mapView: MKMapView, with shelters: [Shelter]) {
            // Remove existing annotations
            let nonUserAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
            mapView.removeAnnotations(nonUserAnnotations)
            
            // Create new annotations
            let annotations = shelters.map { shelter -> MKPointAnnotation in
                let annotation = MKPointAnnotation()
                annotation.title = shelter.name
                annotation.subtitle = shelter.address
                annotation.coordinate = CLLocationCoordinate2D(
                    latitude: shelter.latitude,
                    longitude: shelter.longitude
                )
                return annotation
            }
            
            // Add new annotations
            mapView.addAnnotations(annotations)
            print("Updated map with \(annotations.count) annotations")
        }
        
        // Update the regionDidChangeAnimated method
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if !animated {
                // Show button when user manually moves the map
                searchButton?.isHidden = false
            }
        }
        
        // Optional: Add this method to handle user tracking mode changes
        func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
            // Hide button when user location tracking is active
            searchButton?.isHidden = mode != .none
        }

        @objc func locationButtonTapped() {
            guard let mapView = locationButton?.superview as? MKMapView,
                  let userLocation = locationManager?.location else { return }
            
            // Animate to user location
            let region = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapView.setRegion(region, animated: true)
        }
    }
}
