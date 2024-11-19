import SwiftUI
import MapKit
import CoreLocation

// ShelterHandler manages shelter annotations on the MKMapView.
// It conforms to NSObject and MKMapViewDelegate protocols.
class ShelterHandler: NSObject, MKMapViewDelegate {
    weak var coordinator: MapView.Coordinator?
    var shelterViewModel: ShelterViewModel
    @Binding var selectedShelterFilterTypes: [ShelterFilterType]
    
    init(coordinator: MapView.Coordinator, 
         shelterViewModel: ShelterViewModel,
         selectedShelterFilterTypes: Binding<[ShelterFilterType]>) {
        self.coordinator = coordinator
        self.shelterViewModel = shelterViewModel
        self._selectedShelterFilterTypes = selectedShelterFilterTypes
        super.init()
    }
    
    func updateAnnotations(on mapView: MKMapView) {
        shelterViewModel.mapView = mapView
        shelterViewModel.updateAnnotations(
            for: mapView.region,
            selectedFilters: selectedShelterFilterTypes
        )
    }
    
    // Calculates the search radius based on the map's visible region.
    private func calculateSearchRadius(from region: MKCoordinateRegion) -> CLLocationDistance {
        let span = region.span
        let distanceLatitude = span.latitudeDelta * 111000 / 2  // Approximate conversion.
        let distanceLongitude = span.longitudeDelta * 111000 / 2
        return max(distanceLatitude, distanceLongitude)
    }
    
    // MARK: - MKMapViewDelegate Methods for Shelter Annotations
    
    // Provides the view for each annotation on the map.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        // Identifier for shelter annotation views.
        let identifier = "ShelterPin"
        var view: MKMarkerAnnotationView

        // Try to dequeue an existing annotation view.
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            // Reuse the existing view.
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            // Create a new annotation view if none are available.
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }

        // Configure the annotation view.
        view.canShowCallout = true
        view.markerTintColor = .systemGreen
        view.glyphImage = UIImage(systemName: "house.fill")
        view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)

        return view
    }
    
    // Handles taps on the callout accessory control.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Ensure the annotation is a ShelterAnnotation.
        guard let annotation = view.annotation as? ShelterAnnotation else { return }
        // Update the selected shelter in the ViewModel.
        shelterViewModel.selectedShelter = annotation.shelter
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? ShelterAnnotation {
            shelterViewModel.selectedShelter = annotation.shelter
        }
    }
}

// Custom annotation class to store shelter data.
class ShelterAnnotation: MKPointAnnotation {
    // The shelter associated with this annotation.
    let shelter: Shelter
    
    // Initializer that sets up the annotation with shelter data.
    init(shelter: Shelter) {
        self.shelter = shelter
        super.init()
        // Set the title and subtitle for the annotation's callout.
        self.title = shelter.name
        self.subtitle = shelter.address
        // Set the coordinate for the annotation's location on the map.
        self.coordinate = CLLocationCoordinate2D(
            latitude: shelter.latitude,
            longitude: shelter.longitude
        )
    }
}
