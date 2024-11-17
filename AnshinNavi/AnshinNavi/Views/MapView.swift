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
    var selectedDetent: PresentationDetent
    @Binding var currentAnnotationType: CurrentAnnotationType

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
        context.coordinator.updateSearchButtonPosition(uiView,for: selectedDetent)
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
        let rightSideView = MapRightSideView(mapView: mapView, coordinator: context.coordinator, currentAnnotationType: $currentAnnotationType)
        context.coordinator.compassButton = rightSideView.compassButton
        context.coordinator.locationButton = rightSideView.locationButton
        context.coordinator.settingsButton = rightSideView.settingsButton
        if currentAnnotationType != .none {
            context.coordinator.filterButton = rightSideView.filterButton
        }

        // Search button
        let searchButton = createSearchButton(target: context.coordinator)
        mapView.addSubview(searchButton)
        
        // Calculate initial padding based on drawer height
        let initialDrawerHeight = MainBottomDrawerView.getCurrentHeight(for: selectedDetent)
        let initialSearchButtonPadding: CGFloat = -(initialDrawerHeight + MAIN_DRAWER_SEARCH_BOX_PADDING)
        
        // Create bottom constraint and store it in coordinator
        let bottomConstraint = searchButton.bottomAnchor.constraint(
            equalTo: mapView.safeAreaLayoutGuide.bottomAnchor,
            constant: initialSearchButtonPadding
        )
        
        NSLayoutConstraint.activate([
            searchButton.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            bottomConstraint,
            searchButton.heightAnchor.constraint(equalToConstant: 36),
            searchButton.widthAnchor.constraint(lessThanOrEqualTo: mapView.widthAnchor, multiplier: 0.7)
        ])
        
        context.coordinator.searchButton = searchButton
        context.coordinator.searchButtonBottomConstraint = bottomConstraint
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
        weak var settingsButton: UIButton?
        weak var filterButton: UIButton?
        weak var compassButton: MKCompassButton?
        private var isInitialLocationSet = false
        var shelterHandler: ShelterHandler!
        weak var searchButtonBottomConstraint: NSLayoutConstraint?
        private var searchButtonTimer: Timer?
        private var isMapScrolling = false
        private let searchButtonAnimationDuration: TimeInterval = 0.3
        
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
            isMapScrolling = true
            searchButtonTimer?.invalidate()
            
            UIView.animate(withDuration: searchButtonAnimationDuration, 
                          delay: 0,
                          options: [.curveEaseOut]) {
                self.searchButton?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.searchButton?.alpha = 0
            } completion: { _ in
                self.searchButton?.isHidden = true
                self.searchButton?.transform = .identity
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            isMapScrolling = false
            searchButtonTimer?.invalidate()
            
            searchButtonTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                guard let self = self, !self.isMapScrolling else { return }
                
                if case .large = self.parent.selectedDetent {
                    return
                }
                
                self.searchButton?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.searchButton?.alpha = 0
                self.searchButton?.isHidden = false
                
                UIView.animate(withDuration: self.searchButtonAnimationDuration,
                             delay: 0,
                             usingSpringWithDamping: 0.8,
                             initialSpringVelocity: 0.5,
                             options: [.curveEaseOut]) {
                    self.searchButton?.transform = .identity
                    self.searchButton?.alpha = 1
                }
            }
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
            
            UIView.animate(withDuration: searchButtonAnimationDuration,
                          delay: 0,
                          options: [.curveEaseOut]) {
                self.searchButton?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.searchButton?.alpha = 0
            } completion: { _ in
                self.searchButton?.isHidden = true
                self.searchButton?.transform = .identity
            }
            
            searchButtonTimer?.invalidate()
            
            guard let location = locationManager?.location else {
                print("User location is not available.")
                return
            }
            
            shelterHandler.updateAnnotations(on: mapView, near: location)
        }
        
        @objc func searchRegionButtonTapped() {
            guard let mapView = searchButton?.superview as? MKMapView else { return }
            
            UIView.animate(withDuration: searchButtonAnimationDuration,
                          delay: 0,
                          options: [.curveEaseOut]) {
                self.searchButton?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.searchButton?.alpha = 0
            } completion: { _ in
                self.searchButton?.isHidden = true
                self.searchButton?.transform = .identity
            }
            
            searchButtonTimer?.invalidate()
            
            let region = mapView.region
            let centerLocation = CLLocation(
                latitude: region.center.latitude,
                longitude: region.center.longitude
            )
            
            shelterHandler.updateAnnotations(on: mapView, near: centerLocation)
        }

        @objc func filterButtonTapped() {
            print("DEBUG: Filter button tapped")
            guard let mapView = locationButton?.superview as? MKMapView else {
                print("DEBUG: MapView is nil in filterButtonTapped")
                return
            }
            
            let filterDrawer = FilterDrawerView(currentAnnotationType: parent.currentAnnotationType)
            filterDrawer.show(in: mapView)
            print("DEBUG: Filter drawer shown")
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
        
        func updateSearchButtonPosition(_ mapView: MKMapView, for detent: PresentationDetent) {
            let drawerHeight = MainBottomDrawerView.getCurrentHeight(for: detent)
            let newSearchButtonPadding: CGFloat = -(drawerHeight + MAIN_DRAWER_SEARCH_BOX_PADDING)
            let shouldHide = detent == .large || isMapScrolling
            
            // Update the existing constraint's constant
            searchButtonBottomConstraint?.constant = newSearchButtonPadding
            
            if shouldHide && !searchButton!.isHidden {
                UIView.animate(withDuration: searchButtonAnimationDuration,
                             delay: 0,
                             options: [.curveEaseOut]) {
                    self.searchButton?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    self.searchButton?.alpha = 0
                    self.searchButton?.superview?.layoutIfNeeded() // Animate constraint change
                } completion: { _ in
                    self.searchButton?.isHidden = true
                    self.searchButton?.transform = .identity
                }
            } else if !shouldHide && searchButton!.isHidden {
                self.searchButton?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.searchButton?.alpha = 0
                self.searchButton?.isHidden = false
                
                UIView.animate(withDuration: self.searchButtonAnimationDuration,
                             delay: 0,
                             usingSpringWithDamping: 0.8,
                             initialSpringVelocity: 0.5,
                             options: [.curveEaseOut]) {
                    self.searchButton?.transform = .identity
                    self.searchButton?.alpha = 1
                    self.searchButton?.superview?.layoutIfNeeded() // Animate constraint change
                }
            } else {
                // If button is visible and staying visible, just animate the position change
                UIView.animate(withDuration: 0.3) {
                    self.searchButton?.superview?.layoutIfNeeded()
                }
            }
        }
        
        // Clean up timer when coordinator is deallocated
        deinit {
            searchButtonTimer?.invalidate()
        }
    }
}
