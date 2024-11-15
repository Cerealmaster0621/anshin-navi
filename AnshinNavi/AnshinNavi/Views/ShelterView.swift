import SwiftUI
import MapKit
import CoreLocation

class ShelterHandler: NSObject, MKMapViewDelegate {
    weak var coordinator: MapView.Coordinator?
    var shelterViewModel: ShelterViewModel
    private static let maxAnnotations = 100

    init(coordinator: MapView.Coordinator, shelterViewModel: ShelterViewModel) {
        self.coordinator = coordinator
        self.shelterViewModel = shelterViewModel
        super.init()
    }
    
    func updateAnnotations(on mapView: MKMapView, near location: CLLocation) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Calculate search radius
            let radius = self.calculateSearchRadius(from: mapView.region)

            // Fetch shelters near location
            let shelters = self.shelterViewModel.getSheltersNearLocation(location, radius: radius)

            // Sort shelters by distance
            let centerLocation = location
            let sortedShelters = shelters
                .sorted { shelter1, shelter2 in
                    let location1 = CLLocation(latitude: shelter1.latitude, longitude: shelter1.longitude)
                    let location2 = CLLocation(latitude: shelter2.latitude, longitude: shelter2.longitude)
                    return location1.distance(from: centerLocation) < location2.distance(from: centerLocation)
                }
                .prefix(ShelterHandler.maxAnnotations)

            // Map shelters to annotations
            let annotations = sortedShelters.map { ShelterAnnotation(shelter: $0) }

            // Update the map view on the main thread
            DispatchQueue.main.async {
                // Remove existing annotations
                let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
                mapView.removeAnnotations(existingAnnotations)

                // Add new annotations
                mapView.addAnnotations(annotations)
            }
        }
    }
    
    private func calculateSearchRadius(from region: MKCoordinateRegion) -> CLLocationDistance {
        let span = region.span
        let distanceLatitude = span.latitudeDelta * 111000 / 2  // Convert to meters
        let distanceLongitude = span.longitudeDelta * 111000 / 2
        return max(distanceLatitude, distanceLongitude)
    }
    
    // MARK: - MKMapViewDelegate Methods for Shelter Annotations
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            // Use the default system user location view
            return nil
        }

        // Handle shelter annotations
        let identifier = "ShelterPin"
        var view: MKMarkerAnnotationView

        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            // Reuse an existing view
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            // Create a new view if no reusable view is available
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }

        view.canShowCallout = true
        view.markerTintColor = .systemGreen
        view.glyphImage = UIImage(systemName: "house.fill")
        view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)

        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? ShelterAnnotation else { return }
        shelterViewModel.selectedShelter = annotation.shelter
    }
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
