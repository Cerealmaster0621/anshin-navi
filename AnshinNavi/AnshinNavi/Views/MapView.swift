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
    @EnvironmentObject var policeViewModel: PoliceViewModel
    var selectedDetent: PresentationDetent
    @Binding var currentAnnotationType: CurrentAnnotationType
    @Binding var activeSheet: CurrentSheet?
    @Binding var isTransitioning: Bool
    @Binding var selectedShelterFilterTypes: [ShelterFilterType]
    @Binding var selectedPoliceTypes: [PoliceType]

    func makeCoordinator() -> Coordinator {
        Coordinator(self, 
                   shelterViewModel: shelterViewModel,
                   policeViewModel: policeViewModel,
                   activeSheet: $activeSheet,
                   isTransitioning: $isTransitioning,
                   selectedShelterFilterTypes: $selectedShelterFilterTypes,
                   selectedPoliceTypes: $selectedPoliceTypes)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Set the mapView reference in ViewModels
        shelterViewModel.mapView = mapView
        policeViewModel.mapView = mapView
        
        configureMapView(mapView)
        setupLocationServices(context)
        setupMapControls(mapView, with: context)
        
        // Add observer for filter updates
        NotificationCenter.default.addObserver(
            forName: Notification.Name("search_region_notification".localized),
            object: nil,
            queue: .main
        ) { [context] _ in
            switch currentAnnotationType {
            case .shelter:
                context.coordinator.shelterMapHandler.updateAnnotations(on: mapView)
            case .police:
                context.coordinator.policeMapHandler.updateAnnotations(on: mapView)
            case .none:
                break
            }
        }
        
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

        // Let coordinator setup the search button
        context.coordinator.setupSearchButton(on: mapView, for: selectedDetent)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private let parent: MapView
        var shelterViewModel: ShelterViewModel
        var policeViewModel: PoliceViewModel
        var locationManager: CLLocationManager?
        weak var locationButton: UIButton?
        weak var searchButton: UIButton?
        weak var settingsButton: UIButton?
        weak var filterButton: UIButton?
        weak var compassButton: MKCompassButton?
        private var isInitialLocationSet = false
        var shelterMapHandler: ShelterMapHandler!
        var policeMapHandler: PoliceMapHandler!
        weak var searchButtonBottomConstraint: NSLayoutConstraint?
        private var searchButtonTimer: Timer?
        private var isMapScrolling = false
        private let searchButtonAnimationDuration: TimeInterval = 0.3
        @Binding var activeSheet: CurrentSheet?
        @Binding var isTransitioning: Bool
        @Binding var selectedShelterFilterTypes: [ShelterFilterType]
        @Binding var selectedPoliceTypes: [PoliceType]
        
        init(_ parent: MapView, 
             shelterViewModel: ShelterViewModel,
             policeViewModel: PoliceViewModel,
             activeSheet: Binding<CurrentSheet?>,
             isTransitioning: Binding<Bool>,
             selectedShelterFilterTypes: Binding<[ShelterFilterType]>,
             selectedPoliceTypes: Binding<[PoliceType]>) {
            self.parent = parent
            self.shelterViewModel = shelterViewModel
            self.policeViewModel = policeViewModel
            self._activeSheet = activeSheet
            self._isTransitioning = isTransitioning
            self._selectedShelterFilterTypes = selectedShelterFilterTypes
            self._selectedPoliceTypes = selectedPoliceTypes
            super.init()
            
            self.shelterMapHandler = ShelterMapHandler(
                coordinator: self,
                shelterViewModel: shelterViewModel,
                selectedShelterFilterTypes: selectedShelterFilterTypes
            )
            
            self.policeMapHandler = PoliceMapHandler(
                coordinator: self,
                policeViewModel: policeViewModel,
                selectedPoliceTypes: selectedPoliceTypes
            )
        }
        
        // MARK: - MKMapViewDelegate Methods
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            switch parent.currentAnnotationType {
            case .shelter:
                return shelterMapHandler.mapView(mapView, viewFor: annotation)
            case .police:
                return policeMapHandler.mapView(mapView, viewFor: annotation)
            case .none:
                return nil
            }
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            switch parent.currentAnnotationType {
            case .shelter:
                shelterMapHandler.mapView(mapView, annotationView: view, calloutAccessoryControlTapped: control)
            case .police:
                policeMapHandler.mapView(mapView, annotationView: view, calloutAccessoryControlTapped: control)
            case .none:
                break
            }
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
            
            // Handle search button animation
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
            
            guard (locationManager?.location) != nil else {
                print("user_location_unavailable".localized)
                return
            }
            
            switch parent.currentAnnotationType {
            //<-----SHELTER UPDATE----->
            case .shelter:
                shelterMapHandler.updateAnnotations(on: mapView)
            //<-----POLICE UPDATE----->
            case .police:
                policeMapHandler.updateAnnotations(on: mapView)
            case .none:
                break
            }
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
            switch parent.currentAnnotationType{
                //<-----SEARCH BUTTON SHELTER ANNOTATION HANDLER----->
                case .shelter:
                    searchButtonTimer?.invalidate()
                    shelterMapHandler.updateAnnotations(on: mapView)
                //<-----SEARCH BUTTON POLICE ANNOTATION HANDLER----->
                case .police:
                    searchButtonTimer?.invalidate()
                    policeMapHandler.updateAnnotations(on: mapView)
                case .none:
                    break
            }
        }

        @objc func settingButtonTapped() {
            guard !isTransitioning else { return }
            isTransitioning = true
            
            // If settings is already showing, close it and show bottom drawer
            if activeSheet == .settings {
                withAnimation {
                    activeSheet = .bottomDrawer
                }
            } 
            // If another sheet is showing, switch to settings
            else {
                withAnimation {
                    activeSheet = .settings
                }
            }
            
            // Reset transition state after animation completes
            DispatchQueue.main.async {
                self.isTransitioning = false
            }
        }

        @objc func filterButtonTapped() {
            guard !isTransitioning else { return }
            isTransitioning = true
            
            // If filter is already showing, close it and show bottom drawer
            if activeSheet == .filter {
                withAnimation {
                    activeSheet = .bottomDrawer
                }
            }
            // If another sheet is showing, switch to filter
            else {
                withAnimation {
                    activeSheet = .filter
                }
            }
            
            // Reset transition state after animation completes
            DispatchQueue.main.async {
                self.isTransitioning = false
            }
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
        
        func setupSearchButton(on mapView: MKMapView, for detent: PresentationDetent) {
            let searchButton = UIButton(type: .system)
            searchButton.translatesAutoresizingMaskIntoConstraints = false
            
            // Configure button using the new configuration API
            var config = UIButton.Configuration.plain()
            config.title = "search_this_area".localized
            config.image = UIImage(systemName: "magnifyingglass")
            config.imagePadding = 8  // Space between icon and text
            config.imagePlacement = .leading  // Place icon before text
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            config.background.backgroundColor = .systemBackground
            searchButton.configuration = config
            
            searchButton.addTarget(self, action: #selector(searchRegionButtonTapped), for: .touchUpInside)
            
            // Setup shadow and corner radius
            searchButton.layer.cornerRadius = 18
            searchButton.layer.shadowColor = UIColor.black.cgColor
            searchButton.layer.shadowOffset = CGSize(width: 0, height: 2)
            searchButton.layer.shadowRadius = 4
            searchButton.layer.shadowOpacity = 0.1
            
            mapView.addSubview(searchButton)
            
            // Calculate initial padding based on drawer height
            let initialDrawerHeight = MainBottomDrawerView.getCurrentHeight(for: detent)
            let initialSearchButtonPadding: CGFloat = -(initialDrawerHeight + MAIN_DRAWER_SEARCH_BOX_PADDING)
            
            // Create bottom constraint
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
            
            self.searchButton = searchButton
            self.searchButtonBottomConstraint = bottomConstraint
        }
    }
}

// extension for new search when closing filter sheet
extension MapView {
    static let searchRegionNotification = NotificationCenter.default.publisher(
        for: Notification.Name("search_region_notification".localized)
    )
}
