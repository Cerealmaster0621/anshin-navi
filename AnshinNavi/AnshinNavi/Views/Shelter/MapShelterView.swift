import SwiftUI
import MapKit
import CoreLocation

// MARK: - Shelter Annotation
class ShelterAnnotation: NSObject, MKAnnotation {
    let shelter: Shelter
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: shelter.latitude, longitude: shelter.longitude)
    }
    
    var title: String? {
        shelter.name
    }
    
    var subtitle: String? {
        shelter.regionName
    }
    
    init(shelter: Shelter) {
        self.shelter = shelter
        super.init()
    }
}

class ShelterMapHandler: NSObject {
    weak var coordinator: MapView.Coordinator?
    private let shelterViewModel: ShelterViewModel
    private let selectedShelterFilterTypes: Binding<[ShelterFilterType]>
    
    init(coordinator: MapView.Coordinator,
         shelterViewModel: ShelterViewModel,
         selectedShelterFilterTypes: Binding<[ShelterFilterType]>) {
        self.coordinator = coordinator
        self.shelterViewModel = shelterViewModel
        self.selectedShelterFilterTypes = selectedShelterFilterTypes
        super.init()
    }
    
    // MARK: - Map Update Methods
    
    func updateAnnotations(on mapView: MKMapView) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Get all visible shelters without filters first
            let unfilteredShelters = self.shelterViewModel.getSheltersInMapRegion(mapView.region)
            
            // Get visible shelters based on filters
            let visibleShelters: [Shelter]
            if selectedShelterFilterTypes.wrappedValue.isEmpty {
                visibleShelters = unfilteredShelters
            } else {
                visibleShelters = self.shelterViewModel.filterVisibleSheltersByTypes(
                    selectedShelterFilterTypes.wrappedValue,
                    in: mapView.region
                )
            }
            
            // Get center location for distance calculation
            let centerLocation = CLLocation(
                latitude: mapView.region.center.latitude,
                longitude: mapView.region.center.longitude
            )
            
            // Sort and limit shelters
            let limitedShelters = visibleShelters
                .sorted { shelter1, shelter2 in
                    let location1 = CLLocation(latitude: shelter1.latitude, longitude: shelter1.longitude)
                    let location2 = CLLocation(latitude: shelter2.latitude, longitude: shelter2.longitude)
                    return location1.distance(from: centerLocation) < location2.distance(from: centerLocation)
                }
                .prefix(MAX_ANNOTATIONS)
            
            // Update shelter view model
            DispatchQueue.main.async {
                self.shelterViewModel.visibleShelterCount = min(visibleShelters.count, MAX_ANNOTATIONS)
                self.shelterViewModel.currentUnfilteredShelters = Array(unfilteredShelters.prefix(MAX_ANNOTATIONS))
                self.shelterViewModel.currentVisibleShelters = Array(limitedShelters)
            }
            
            // Convert shelters to annotations
            let annotations = limitedShelters.map { shelter in
                ShelterAnnotation(shelter: shelter)
            }
            
            // Update map annotations on main thread
            DispatchQueue.main.async {
                let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
                mapView.removeAnnotations(existingAnnotations)
                mapView.addAnnotations(annotations)
            }
        }
    }
}

// MARK: - MKMapViewDelegate Methods
extension ShelterMapHandler: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? ShelterAnnotation else { return nil }
        
        let identifier = "ShelterAnnotation"
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        
        annotationView.canShowCallout = true
        annotationView.markerTintColor = UIColor(Color(.systemGreen))
        annotationView.glyphImage = UIImage(systemName: "house.fill")
        
        let button = UIButton(type: .detailDisclosure)
        annotationView.rightCalloutAccessoryView = button
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? ShelterAnnotation else { return }
        shelterViewModel.selectedShelter = annotation.shelter
    }
}
