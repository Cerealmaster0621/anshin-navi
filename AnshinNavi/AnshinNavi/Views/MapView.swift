//
//  MapView.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/16.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: UIViewRepresentable {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, shelterViewModel: shelterViewModel)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        configureMapView(mapView)
        setupLocationServices(context)
        setupMapControls(mapView, with: context)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
    }
    
    // MARK: - Configuration Methods
    
    private func configureMapView(_ mapView: MKMapView) {
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .default)
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.userTrackingMode = .followWithHeading
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
        // Create right side controls
        let rightSideView = MapRightSideView(mapView: mapView, coordinator: context.coordinator)
        context.coordinator.compassButton = rightSideView.compassButton
        context.coordinator.locationButton = rightSideView.locationButton
        
        // Search button
        let searchButton = createSearchButton(target: context.coordinator)
        searchButton.isHidden = true
        mapView.addSubview(searchButton)
        
        // Setup search button constraints only
        NSLayoutConstraint.activate([
            searchButton.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            searchButton.bottomAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            searchButton.heightAnchor.constraint(equalToConstant: 36),
            searchButton.widthAnchor.constraint(lessThanOrEqualTo: mapView.widthAnchor, multiplier: 0.7)
        ])
        
        context.coordinator.searchButton = searchButton
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
    
    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private let parent: MapView
        var shelterViewModel: ShelterViewModel
        var locationManager: CLLocationManager?
        weak var locationButton: UIButton?
        weak var searchButton: UIButton?
        weak var compassButton: MKCompassButton?
        private var isInitialLocationSet = false
        var shelterHandler: ShelterHandler!
        
        init(_ parent: MapView, shelterViewModel: ShelterViewModel) {
            self.parent = parent
            self.shelterViewModel = shelterViewModel
            super.init()
            self.shelterHandler = ShelterHandler(coordinator: self, shelterViewModel: shelterViewModel)
        }
        
        // MARK: - MKMapViewDelegate Methods
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            return shelterHandler.mapView(mapView, viewFor: annotation)
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            shelterHandler.mapView(mapView, annotationView: view, calloutAccessoryControlTapped: control)
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            searchButton?.isHidden = animated
        }
        
        // MARK: - CLLocationManagerDelegate Methods
        
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
            shelterHandler.updateAnnotations(on: mapView, near: location)
            manager.stopUpdatingLocation()
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            guard let mapView = locationButton?.superview as? MKMapView else { return }
            
            if mapView.userTrackingMode == .followWithHeading {
                let heading = newHeading.magneticHeading
                mapView.camera.heading = heading
            }
        }
        
        // MARK: - Button Actions
        
        @objc func locationButtonTapped() {
            guard let mapView = locationButton?.superview as? MKMapView else { return }
            
            mapView.setUserTrackingMode(.followWithHeading, animated: true)
            searchButton?.isHidden = true
            
            guard let location = locationManager?.location else {
                print("User location is not available.")
                return
            }
            
            shelterHandler.updateAnnotations(on: mapView, near: location)
        }
        
        @objc func searchRegionButtonTapped() {
            guard let mapView = searchButton?.superview as? MKMapView else { return }
            
            let region = mapView.region
            let centerLocation = CLLocation(
                latitude: region.center.latitude,
                longitude: region.center.longitude
            )
            
            shelterHandler.updateAnnotations(on: mapView, near: centerLocation)
            searchButton?.isHidden = true
        }
        
        // MARK: - Helper Methods
        
        private func updateMapRegion(_ mapView: MKMapView, coordinate: CLLocationCoordinate2D) {
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapView.setRegion(region, animated: true)
        }
    }
}
