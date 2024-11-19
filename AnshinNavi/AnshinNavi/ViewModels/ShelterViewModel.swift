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
    @Published private(set) var currentVisibleShelters: [Shelter] = []
    
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
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        return shelters.filter { shelter in
            let distance = fastDistance(
                lat1: lat,
                lon1: lon,
                lat2: shelter.latitude,
                lon2: shelter.longitude
            )
            return distance <= radius
        }
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
            
            // Update visible shelter count and currentVisibleShelters
            DispatchQueue.main.async {
                self.visibleShelterCount = min(visibleShelters.count, MAX_ANNOTATIONS)
                self.currentVisibleShelters = Array(limitedShelters)
            }
            
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

    func addPinAndCenterCamera(for shelter: Shelter) {
        guard let mapView = mapView else { return }
        
        // Create coordinate and region
        let coordinate = CLLocationCoordinate2D(
            latitude: shelter.latitude,
            longitude: shelter.longitude
        )
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,  // 1km zoom level
            longitudinalMeters: 1000
        )
        
        // Check if annotation already exists
        let existingAnnotation = mapView.annotations.first { annotation in
            guard let shelterAnnotation = annotation as? ShelterAnnotation else { return false }
            return shelterAnnotation.shelter.id == shelter.id
        }
        
        // Add annotation if it doesn't exist
        if existingAnnotation == nil {
            let annotation = ShelterAnnotation(shelter: shelter)
            mapView.addAnnotation(annotation)
        }
        
        // Animate to the shelter's location
        mapView.setRegion(region, animated: true)
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

extension ShelterViewModel {
    /// Calculates distance between two coordinates using optimized Haversine formula
    /// - Parameters:
    ///   - lat1: First latitude in degrees
    ///   - lon1: First longitude in degrees
    ///   - lat2: Second latitude in degrees
    ///   - lon2: Second longitude in degrees
    /// - Returns: Distance in meters
    func fastDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        // Earth's radius in meters
        let R: Double = 6371000
        
        // Convert coordinates to radians
        let φ1 = lat1 * .pi / 180
        let φ2 = lat2 * .pi / 180
        let Δφ = (lat2 - lat1) * .pi / 180
        let Δλ = (lon2 - lon1) * .pi / 180
        
        // Pre-calculate trigonometric values
        let sinΔφ2 = sin(Δφ / 2)
        let sinΔλ2 = sin(Δλ / 2)
        
        // Haversine formula
        let a = sinΔφ2 * sinΔφ2 +
                cos(φ1) * cos(φ2) * sinΔλ2 * sinΔλ2
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return R * c
    }

    func formatDistance(meters: Double) -> String {
        if meters >= 1000 {
            let km = meters / 1000
            return String(format: "%.1f km", km)
        } else {
            return String(format: "%.0f m", meters)
        }
    }
}

extension ShelterViewModel {
    /// Searches for shelters matching the given keyword in name or region
    /// - Parameters:
    ///   - shelters: Array of shelters to search through
    ///   - keyword: Search keyword
    /// - Returns: Array of shelters matching the search criteria
    func searchShelters(_ shelters: [Shelter], keyword: String) -> [Shelter] {
        guard !keyword.isEmpty else { return shelters }
        
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return shelters.filter { shelter in
            shelter.name.lowercased().contains(trimmedKeyword) ||
            shelter.regionName.lowercased().contains(trimmedKeyword)
        }
    }
    
    /// Searches through currently visible shelters
    /// - Parameter keyword: Search keyword
    /// - Returns: Array of visible shelters matching the search criteria
    func searchCurrentVisibleShelters(keyword: String) -> [Shelter] {
        return searchShelters(currentVisibleShelters, keyword: keyword)
    }
}
