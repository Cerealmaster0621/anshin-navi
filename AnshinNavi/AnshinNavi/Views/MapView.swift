//
//  MapView.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/14.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @EnvironmentObject var shelterViewModel: ShelterViewModel

    // create the map view
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        // Add compass (shows up in top-right corner)
        mapView.showsCompass = true
        
        // Set map type to standard with points of interest and labels
        mapView.mapType = .standard
        mapView.pointOfInterestFilter = .includingAll
        
        return mapView
    }

    // update the map view
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Clear existing annotations
        uiView.removeAnnotations(uiView.annotations)
        
        // Add new annotations based on shelters
        let annotations = shelterViewModel.shelters.map { shelter -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.title = shelter.name
            annotation.coordinate = CLLocationCoordinate2D(latitude: shelter.latitude, longitude: shelter.longitude)
            return annotation
        }
        uiView.addAnnotations(annotations)
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
            if let annotation = view.annotation,
               let shelter = parent.shelterViewModel.shelters.first(where: { $0.name == annotation.title }) {
                parent.shelterViewModel.selectedShelter = shelter
            }
        }
    }
}


