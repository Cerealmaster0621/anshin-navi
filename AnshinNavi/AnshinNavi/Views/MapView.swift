import SwiftUI
import MapKit
import CoreLocation

struct MapView: UIViewRepresentable {
    @EnvironmentObject var shelterViewModel: ShelterViewModel

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
    }
}
