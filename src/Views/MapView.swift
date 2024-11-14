import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @EnvironmentObject var shelterViewModel: ShelterViewModel

    // create the map view
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    // update the map view
    func updateUIView(_ uiView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        
        let annotations = viewModel.shelters.map { shelter -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.title = shelter.name
            annotation.subtitle = "Capacity: \(shelter.capacity)"
            annotation.coordinate = shelter.location
            return annotation
        }
        mapView.addAnnotations(annotations)
    }

    // create the coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation, let shelter = parent.viewModel.shelters.first(where: { $0.name == annotation.title }) {
                parent.viewModel.selectedShelter = shelter
            }
        }
    }
}
