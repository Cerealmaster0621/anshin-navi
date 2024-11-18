import Foundation
import MapKit
import SwiftUI

enum DataError: Error {
    case fileNotFound(String)
    case decodingError(String)
    case invalidData
}

final class ShelterViewModel: NSObject, ObservableObject {
    @Published private(set) var shelters: [Shelter] = []
    @Published var selectedShelter: Shelter?
    @Published var visibleShelterCount: Int = 0
    @Published var userLocation: CLLocation?
    
    private let locationManager = CLLocationManager()
    private let jsonFileName = "shelters"
    private let jsonFileExtension = "json"
    
    weak var mapView: MKMapView?
    
    override init() {
        super.init()
        loadShelters()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Public Methods
    
    /// Retrieves shelters within a specified radius of a location
    /// - Parameters:
    ///   - location: The center point to search from
    ///   - radius: The search radius in meters (defaults to 2km)
    /// - Returns: Array of shelters within the specified radius
    func getSheltersNearLocation(_ location: CLLocation, radius: CLLocationDistance = 2000) -> [Shelter] {
        let shelterLocations = shelters.map { shelter in
            (
                shelter: shelter,
                distance: location.distance(from: CLLocation(
                    latitude: shelter.latitude,
                    longitude: shelter.longitude
                ))
            )
        }
        
        return shelterLocations
            .filter { $0.distance <= radius }
            .map { $0.shelter }
    }
    
    /// Retrieves shelters visible within the current map region
    /// - Parameter region: The visible map region
    /// - Returns: Array of shelters within the region
    func getSheltersInMapRegion(_ region: MKCoordinateRegion) -> [Shelter] {
        let centerLocation = CLLocation(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        let radius = calculateRadius(from: region)
        return getSheltersNearLocation(centerLocation, radius: radius)
    }
    
    /// Filters visible shelters based on multiple disaster types using AND operation
    /// - Parameters:
    ///   - filters: ShelterFilterType with desired filter conditions
    ///   - region: The visible map region
    /// - Returns: Array of visible shelters matching ALL specified conditions
    func filterVisibleSheltersByTypes(_ filterTypes: [ShelterFilterType], in region: MKCoordinateRegion) -> [Shelter] {
        // First get only visible shelters in the map region
        let visibleShelters = getSheltersInMapRegion(region)
        
        // If no filters are selected, return all visible shelters
        guard !filterTypes.isEmpty else { return visibleShelters }
        
        return visibleShelters.filter { shelter in
            // A shelter must match ALL selected filter types (AND operation)
            filterTypes.allSatisfy { filterType in
                filterType.matches(shelter)
            }
        }
    }
    
    func updateAnnotations(for region: MKCoordinateRegion, selectedFilters: [ShelterFilterType]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Get visible shelters based on filters
            let visibleShelters: [Shelter]
            if selectedFilters.isEmpty {
                visibleShelters = self.getSheltersInMapRegion(region)
            } else {
                visibleShelters = self.filterVisibleSheltersByTypes(selectedFilters, in: region)
            }
            
            // Update visible shelter count
            DispatchQueue.main.async {
                self.visibleShelterCount = min(visibleShelters.count, MAX_ANNOTATIONS)
            }
            
            // Get center location for distance calculation
            let centerLocation = CLLocation(
                latitude: region.center.latitude,
                longitude: region.center.longitude
            )
            
            // Sort shelters by distance and limit to MAX_ANNOTATIONS
            let limitedShelters = visibleShelters
                .sorted { shelter1, shelter2 in
                    let location1 = CLLocation(latitude: shelter1.latitude, longitude: shelter1.longitude)
                    let location2 = CLLocation(latitude: shelter2.latitude, longitude: shelter2.longitude)
                    return location1.distance(from: centerLocation) < location2.distance(from: centerLocation)
                }
                .prefix(MAX_ANNOTATIONS)
            
            // Convert shelters to annotations
            let annotations = limitedShelters.map { shelter in
                ShelterAnnotation(shelter: shelter)
            }
            
            // Update map annotations on main thread
            DispatchQueue.main.async { [weak self] in
                guard let mapView = self?.mapView else { return }
                let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
                mapView.removeAnnotations(existingAnnotations)
                mapView.addAnnotations(annotations)
            }
        }
    }

    /// Gets the closest shelter with specific safety features
    /// - Parameters:
    ///   - userLocation: The user's current location
    ///   - filterTypes: Array of required safety features
    /// - Returns: The closest shelter matching the specified criteria
    func getClosestShelter(to userLocation: CLLocation, matching filterTypes: [ShelterFilterType]) -> Shelter? {
        // First filter shelters by safety features
        let filteredShelters = shelters.filter { shelter in
            filterTypes.allSatisfy { filterType in
                filterType.matches(shelter)
            }
        }
        
        // Then find the closest among filtered shelters
        return filteredShelters.min(by: { shelter1, shelter2 in
            let location1 = CLLocation(latitude: shelter1.latitude, longitude: shelter1.longitude)
            let location2 = CLLocation(latitude: shelter2.latitude, longitude: shelter2.longitude)
            return userLocation.distance(from: location1) < userLocation.distance(from: location2)
        })
    }
    
    // MARK: - Private Methods
    
    private func loadShelters() {
        guard let url = Bundle.main.url(forResource: jsonFileName, withExtension: jsonFileExtension) else {
            handleError(.fileNotFound("Shelter data file not found"))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let response = try decoder.decode(ShelterResponse.self, from: data)
            DispatchQueue.main.async {
                self.shelters = response.shelters
            }
        } catch {
            handleError(.decodingError(error.localizedDescription))
        }
    }
    
    private func calculateRadius(from region: MKCoordinateRegion) -> CLLocationDistance {
        let metersPerDegree = 111_000.0
        return max(
            region.span.latitudeDelta * metersPerDegree / 2,
            region.span.longitudeDelta * metersPerDegree / 2
        )
    }
    
    private func handleError(_ error: DataError) {
        DispatchQueue.main.async {
            self.shelters = []
            self.selectedShelter = nil
        }
    } 
}

// MARK: - Helper Methods
extension ShelterViewModel {
    var sheltersByRegion: [String: [Shelter]] {
        Dictionary(grouping: shelters) { $0.regionCode }
    }
    
    var availableRegions: [String] {
        Array(Set(shelters.map(\.regionCode))).sorted()
    }
}

// MARK: - Private Types
private struct ShelterResponse: Codable {
    let shelters: [Shelter]
}

// MARK: - CLLocationManagerDelegate
extension ShelterViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
