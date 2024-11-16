import Foundation
import SwiftUI
import MapKit
import CoreLocation

public class MapRightSideView {
    private weak var mapView: MKMapView?
    private weak var coordinator: MapView.Coordinator?
    
    var compassButton: MKCompassButton?
    var locationButton: UIButton?
    
    init(mapView: MKMapView, coordinator: MapView.Coordinator) {
        self.mapView = mapView
        self.coordinator = coordinator
        setupRightSideControls()
    }
    
    private func setupRightSideControls() {
        guard let mapView = mapView else { return }
        
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
        
        setupConstraints(compass: compass, location: locationButton)
    }
    
    private func createLocationButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.15
        
        let image = UIImage(systemName: "location.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .medium))
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(coordinator, action: #selector(MapView.Coordinator.locationButtonTapped), for: .touchUpInside)
        
        return button
    }
    
    private func setupConstraints(compass: MKCompassButton, location: UIButton) {
        guard let mapView = mapView else { return }
        
        NSLayoutConstraint.activate([
            // Compass
            compass.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 10),
            compass.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            // Location button
            location.topAnchor.constraint(equalTo: compass.bottomAnchor, constant: 10),
            location.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            location.widthAnchor.constraint(equalToConstant: 40),
            location.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
}
