import Foundation
import SwiftUI
import MapKit
import CoreLocation

public class MapRightSideView {
    @Binding var currentAnnotationType: CurrentAnnotationType
    private weak var mapView: MKMapView?
    private weak var coordinator: MapView.Coordinator?

    var compassButton: MKCompassButton?
    var locationButton: UIButton?
    var settingsButton: UIButton?
    var filterButton: UIButton?

    init(mapView: MKMapView, coordinator: MapView.Coordinator, currentAnnotationType: Binding<CurrentAnnotationType>) {
        self.mapView = mapView
        self.coordinator = coordinator
        self._currentAnnotationType = currentAnnotationType
        setupRightSideControls()
    }
    
    private func setupRightSideControls() {
        guard let mapView = mapView else { 
            print("DEBUG: MapView is nil in setupRightSideControls")
            return 
        }
        
        print("DEBUG: Current annotation type is: \(currentAnnotationType)")
        
        // Compass
        let compass = MKCompassButton(mapView: mapView)
        compass.compassVisibility = .visible
        compass.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(compass)
        self.compassButton = compass
        
        // Location button
        let locationButton = createLocationButton()
        mapView.addSubview(locationButton)
        self.locationButton = locationButton
        
        // Settings button - TODO
        let settingsButton = createSettingsButton()
        mapView.addSubview(settingsButton)
        self.settingsButton = settingsButton

        // filter button (only shown when annotation is selected)
        if currentAnnotationType == .none {
            print("DEBUG: Filter button not created - annotation type is .none")
            self.filterButton = nil
            setupConstraints(compass: compass, location: locationButton, settings: settingsButton, filter: nil)
        } else {
            print("DEBUG: Creating filter button")
            let filterButton = createFilterButton()
            mapView.addSubview(filterButton)
            self.filterButton = filterButton
            setupConstraints(compass: compass, location: locationButton, settings: settingsButton, filter: filterButton)
        }
        
    }
    
    private func createSettingsButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBackground.withAlphaComponent(0.9)
        button.layer.cornerRadius = 6
        button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        let image = UIImage(systemName: "gearshape.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(coordinator, action: #selector(MapView.Coordinator.settingButtonTapped), for: .touchUpInside)
        
        return button
    }

    private func createLocationButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBackground.withAlphaComponent(0.9)
        button.layer.cornerRadius = 6
        button.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        let image = UIImage(systemName: "location.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(coordinator, action: #selector(MapView.Coordinator.locationButtonTapped), for: .touchUpInside)
        
        return button
    }
    
    // MARK: - Filter Button
    private func createFilterButton() -> UIButton {
        print("DEBUG: Inside createFilterButton")
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBackground.withAlphaComponent(0.9)
        button.layer.cornerRadius = 6
        
        let image = UIImage(systemName: "line.3.horizontal.decrease.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
        
        // Change to single target-action
        button.addTarget(coordinator, action: #selector(MapView.Coordinator.filterButtonTapped), for: .touchUpInside)
        print("DEBUG: Filter button created and target set")
        
        return button
    }
    
    private func setupConstraints(compass: MKCompassButton, location: UIButton, settings: UIButton, filter: UIButton?) {
        guard let mapView = mapView else { return }
        
        NSLayoutConstraint.activate([
            // Compass
            compass.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 10),
            compass.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            // Location button
            location.topAnchor.constraint(equalTo: compass.bottomAnchor, constant: 10),
            location.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            location.widthAnchor.constraint(equalToConstant: 40),
            location.heightAnchor.constraint(equalToConstant: 40),
            
            // Settings button
            settings.topAnchor.constraint(equalTo: location.bottomAnchor),
            settings.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            settings.widthAnchor.constraint(equalToConstant: 40),
            settings.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Only add filter button constraints if it exists
        if let filter = filter {
            NSLayoutConstraint.activate([
                filter.topAnchor.constraint(equalTo: settings.bottomAnchor, constant: 10),
                filter.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
                filter.widthAnchor.constraint(equalToConstant: 40),
                filter.heightAnchor.constraint(equalToConstant: 40)
            ])
        }
        
        // Add separator line between buttons
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .systemGray4
        mapView.addSubview(separator)
        
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: location.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: location.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: location.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
}
