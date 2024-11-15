import SwiftUI
import MapKit
import CoreLocation

struct MapView: UIViewRepresentable {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @State private var isUserLocationVisible: Bool = true

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()

        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow

        // map configuration
        let configuration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        mapView.preferredConfiguration = configuration
        
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isPitchEnabled = true
        mapView.showsScale = true
        mapView.showsUserLocation = true
        mapView.isRotateEnabled = true
        
        
        mapView.showsUserLocation = true
        // Todo - show user locations
        mapView.userLocation.location
        mapView.userLocation.coordinate
        mapView.userLocation.isUpdating
        mapView.setUserTrackingMode(.follow, animated: true)
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        
        mapView.showsCompass = false
        // Add custom compass button and position it in the top-right corner
        let compassButton = MKCompassButton(mapView: mapView)
        compassButton.compassVisibility = .visible
        compassButton.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(compassButton)
        NSLayoutConstraint.activate([
            compassButton.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 10),
            compassButton.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])

        // Add recenter button with native iOS style
        let recenterButton = UIButton(configuration: .filled())
        recenterButton.configuration?.baseBackgroundColor = .systemBackground
        recenterButton.configuration?.baseForegroundColor = .label
        recenterButton.configuration?.cornerStyle = .medium
        
        // Create button title with icon
        let buttonText = "この地域で検索"
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let searchImage = UIImage(systemName: "magnifyingglass", withConfiguration: imageConfig)
        
        recenterButton.configuration?.image = searchImage
        recenterButton.configuration?.imagePlacement = .leading
        recenterButton.configuration?.imagePadding = 6
        recenterButton.configuration?.title = buttonText
        
        // Add shadow for depth
        recenterButton.layer.shadowColor = UIColor.black.cgColor
        recenterButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        recenterButton.layer.shadowRadius = 4
        recenterButton.layer.shadowOpacity = 0.15
        
        recenterButton.translatesAutoresizingMaskIntoConstraints = false
        recenterButton.addTarget(context.coordinator, 
                               action: #selector(Coordinator.searchCurrentRegionButtonTapped), 
                               for: .touchUpInside)
        recenterButton.isHidden = true
        
        mapView.addSubview(recenterButton)
        
        NSLayoutConstraint.activate([
            recenterButton.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            recenterButton.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 16),
            recenterButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        context.coordinator.recenterButton = recenterButton
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        let nonUserAnnotations = uiView.annotations.filter { !($0 is MKUserLocation) }
        uiView.removeAnnotations(nonUserAnnotations)

        let annotations = shelterViewModel.shelters.map { shelter -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.title = shelter.name
            annotation.coordinate = CLLocationCoordinate2D(latitude: shelter.latitude, longitude: shelter.longitude)
            return annotation
        }
        uiView.addAnnotations(annotations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var parent: MapView
        var locationManager: CLLocationManager?
        weak var recenterButton: UIButton?

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
            if annotation is MKUserLocation {
                return nil // Use default user location view
            } else {
                let identifier = "ShelterAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            }
        }

        @objc func searchCurrentRegionButtonTapped() {
            guard let mapView = recenterButton?.superview as? MKMapView else { return }
            
            // Get shelters near the current map center
            let centerCoordinate = mapView.centerCoordinate
            let nearbyShelters = parent.shelterViewModel.getSheltersInVisibleRegion(
                center: centerCoordinate,
                radius: 2000 // 2km radius, adjust as needed
            )
            
            // Update annotations
            updateAnnotations(on: mapView, with: nearbyShelters)
            
            // Hide the button after search
            recenterButton?.isHidden = true
        }
        
        private func updateAnnotations(on mapView: MKMapView, with shelters: [Shelter]) {
            let nonUserAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
            mapView.removeAnnotations(nonUserAnnotations)
            
            let annotations = shelters.map { shelter -> MKPointAnnotation in
                let annotation = MKPointAnnotation()
                annotation.title = shelter.name
                annotation.coordinate = CLLocationCoordinate2D(
                    latitude: shelter.latitude,
                    longitude: shelter.longitude
                )
                return annotation
            }
            mapView.addAnnotations(annotations)
        }
        
        // Update the regionDidChangeAnimated method
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if !animated {
                // Show button when user manually moves the map
                recenterButton?.isHidden = false
            }
        }
        
        // Optional: Add this method to handle user tracking mode changes
        func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
            // Hide button when user location tracking is active
            recenterButton?.isHidden = mode != .none
        }
    }
}
