//
//  MapPoliceView.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/21.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

// MARK: - Police Annotation
class PoliceAnnotation: NSObject, MKAnnotation {
    let police: PoliceBase
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: police.latitude, longitude: police.longitude)
    }
    
    var title: String? {
        police.name
    }
    
    var subtitle: String? {
        police.prefecture
    }
    
    init(police: PoliceBase) {
        self.police = police
        super.init()
    }
}

class PoliceMapHandler: NSObject {
    weak var coordinator: MapView.Coordinator?
    private let policeViewModel: PoliceViewModel
    private let selectedPoliceTypes: Binding<[PoliceType]>
    
    init(coordinator: MapView.Coordinator,
         policeViewModel: PoliceViewModel,
         selectedPoliceTypes: Binding<[PoliceType]>) {
        self.coordinator = coordinator
        self.policeViewModel = policeViewModel
        self.selectedPoliceTypes = selectedPoliceTypes
        super.init()
    }
    
    // MARK: - Map Update Methods
    
    func updateAnnotations(on mapView: MKMapView) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Get all visible police stations without filters first
            let unfilteredStations = self.policeViewModel.getPoliceStationsInMapRegion(mapView.region)
            
            // Get visible stations based on filters
            let visibleStations: [PoliceBase]
            if selectedPoliceTypes.wrappedValue.isEmpty {
                visibleStations = unfilteredStations
            } else {
                visibleStations = self.policeViewModel.filterVisiblePoliceStationsByType(
                    selectedPoliceTypes.wrappedValue,
                    in: mapView.region
                )
            }
            
            // Get center location for distance calculation
            let centerLocation = CLLocation(
                latitude: mapView.region.center.latitude,
                longitude: mapView.region.center.longitude
            )
            
            // Sort and limit stations
            let limitedStations = visibleStations
                .sorted { station1, station2 in
                    let location1 = CLLocation(latitude: station1.latitude, longitude: station1.longitude)
                    let location2 = CLLocation(latitude: station2.latitude, longitude: station2.longitude)
                    return location1.distance(from: centerLocation) < location2.distance(from: centerLocation)
                }
                .prefix(MAX_ANNOTATIONS)
            
            // Update police view model
            DispatchQueue.main.async {
                self.policeViewModel.visiblePoliceCount = min(visibleStations.count, MAX_ANNOTATIONS)
                self.policeViewModel.currentUnfilteredPoliceStations = Array(unfilteredStations.prefix(MAX_ANNOTATIONS))
                self.policeViewModel.currentVisiblePoliceStations = Array(limitedStations)
            }
            
            // Convert stations to annotations
            let annotations = limitedStations.map { station in
                PoliceAnnotation(police: station)
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
extension PoliceMapHandler: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? PoliceAnnotation else { return nil }
        
        let identifier = "PoliceAnnotation"
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        
        annotationView.canShowCallout = true
        annotationView.markerTintColor = UIColor(Color(.systemBlue))
        
        // Set different icons based on police type
        switch annotation.police.policeType {
        case .koban:
            annotationView.glyphImage = UIImage(systemName: "building.columns.fill")
        case .keisatsusho:
            annotationView.glyphImage = UIImage(systemName: "shield.fill")
        case .honbu:
            annotationView.glyphImage = UIImage(systemName: "star.circle.fill")
        }
        
        let button = UIButton(type: .detailDisclosure)
        annotationView.rightCalloutAccessoryView = button
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? PoliceAnnotation else { return }
        policeViewModel.selectedPoliceStation = annotation.police
    }
}
