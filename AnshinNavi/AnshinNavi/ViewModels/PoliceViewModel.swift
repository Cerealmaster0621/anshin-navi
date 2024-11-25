//
//  PoliceViewModel.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/21.
//

import Foundation
import MapKit
import SwiftUI

final class PoliceViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var policeStations: [PoliceBase] = []
    @Published var selectedPoliceStation: PoliceBase?
    @Published var visiblePoliceCount: Int = 0
    @Published var userLocation: CLLocation?
    @Published var currentVisiblePoliceStations: [PoliceBase] = []
    @Published var currentUnfilteredPoliceStations: [PoliceBase] = []
    
    private let locationManager = CLLocationManager()
    private let jsonFileName = "polices"
    private let jsonFileExtension = "json"
    
    var mapView: MKMapView?
    
    override init() {
        super.init()
        loadPoliceStations()
        setupLocationManager()
        print("Total loaded police stations: \(policeStations.count)")
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Public Methods
    func getPoliceStationsNearLocation(_ location: CLLocation, radius: CLLocationDistance = 2000) -> [PoliceBase] {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        return policeStations.filter { station in
            let distance = fastDistance(
                lat1: lat,
                lon1: lon,
                lat2: station.latitude,
                lon2: station.longitude
            )
            return distance <= radius
        }
    }
    
    func getPoliceStationsInMapRegion(_ region: MKCoordinateRegion) -> [PoliceBase] {
        let centerLocation = CLLocation(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        let radius = calculateRadius(from: region)
        return getPoliceStationsNearLocation(centerLocation, radius: radius)
    }
    
    func filterVisiblePoliceStationsByType(_ types: [PoliceType], in region: MKCoordinateRegion) -> [PoliceBase] {
        // First get only visible stations in the map region
        let visibleStations = getPoliceStationsInMapRegion(region)
        
        // If no types are selected, return all visible stations
        guard !types.isEmpty else { return visibleStations }
        
        return visibleStations.filter { station in
            types.contains(station.policeType)
        }
    }
    
    func updateAnnotations(for region: MKCoordinateRegion, selectedTypes: [PoliceType]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Get all visible police stations without filters first
            let unfilteredStations = self.getPoliceStationsInMapRegion(region)
            
            // Get visible stations based on filters
            let visibleStations: [PoliceBase]
            if selectedTypes.isEmpty {
                visibleStations = unfilteredStations
            } else {
                visibleStations = self.filterVisiblePoliceStationsByType(selectedTypes, in: region)
            }
            
            // Get center location for distance calculation
            let centerLocation = CLLocation(
                latitude: region.center.latitude,
                longitude: region.center.longitude
            )
            
            // Sort all stations by distance from center
            let sortedUnfilteredStations = unfilteredStations.sorted { station1, station2 in
                let location1 = CLLocation(latitude: station1.latitude, longitude: station1.longitude)
                let location2 = CLLocation(latitude: station2.latitude, longitude: station2.longitude)
                return location1.distance(from: centerLocation) < location2.distance(from: centerLocation)
            }
            
            let sortedVisibleStations = visibleStations.sorted { station1, station2 in
                let location1 = CLLocation(latitude: station1.latitude, longitude: station1.longitude)
                let location2 = CLLocation(latitude: station2.latitude, longitude: station2.longitude)
                return location1.distance(from: centerLocation) < location2.distance(from: centerLocation)
            }
            
            // Update on main thread
            DispatchQueue.main.async {
                self.currentUnfilteredPoliceStations = sortedUnfilteredStations
                self.currentVisiblePoliceStations = sortedVisibleStations
                self.visiblePoliceCount = sortedVisibleStations.count
            }
        }
    }
    
    func getClosestPoliceStation(to userLocation: CLLocation, matching types: [PoliceType]) -> PoliceBase? {
        let filteredStations = policeStations.filter { station in
            types.isEmpty || types.contains(station.policeType)
        }
        
        return filteredStations.min(by: { station1, station2 in
            let location1 = CLLocation(latitude: station1.latitude, longitude: station1.longitude)
            let location2 = CLLocation(latitude: station2.latitude, longitude: station2.longitude)
            return userLocation.distance(from: location1) < userLocation.distance(from: location2)
        })
    }
    
    func addPinAndCenterCamera(for station: PoliceBase) {
        guard let mapView = mapView else {
            print("MapView not available")
            return
        }
        
        let coordinate = CLLocationCoordinate2D(
            latitude: station.latitude,
            longitude: station.longitude
        )
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        
        let annotation = PoliceAnnotation(police: station)
        mapView.addAnnotation(annotation)
        mapView.setRegion(region, animated: true)
        mapView.selectAnnotation(annotation, animated: true)
    }
    
    // MARK: - Private Methods
    private func loadPoliceStations() {
        guard let url = Bundle.main.url(forResource: jsonFileName, withExtension: jsonFileExtension) else {
            print("Error: Police data file not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            // Decode into a wrapper structure that matches your JSON format
            let wrapper = try decoder.decode(PoliceDataWrapper.self, from: data)
            self.policeStations = wrapper.polices
            print("Successfully loaded \(policeStations.count) police stations")
        } catch {
            print("Error decoding police data: \(error)")
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
            self.policeStations = []
            self.selectedPoliceStation = nil
        }
    }
    
    /// Calculates walking time to a police station using MapKit routing
    /// - Parameters:
    ///   - police: The destination police station
    ///   - from: Starting location (defaults to user's current location)
    /// - Returns: Formatted travel time string if route is available, nil otherwise
    func calculateWalkingTime(to police: PoliceBase, from location: CLLocation? = nil) async -> String? {
        let startLocation = location ?? userLocation
        guard let startLocation = startLocation else {
            return nil
        }
        
        let request = MKDirections.Request()
        request.transportType = .walking
        
        request.source = MKMapItem(placemark: MKPlacemark(
            coordinate: startLocation.coordinate
        ))
        request.destination = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(
                latitude: police.latitude,
                longitude: police.longitude
            )
        ))
        
        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            
            if let route = response.routes.first {
                return formatTravelTime(seconds: route.expectedTravelTime)
            }
        } catch {
            print("Error calculating route: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Formats travel time into a human-readable string
    /// - Parameter seconds: Travel time in seconds
    /// - Returns: Formatted string like "5分", "2時間", or "1日"
    func formatTravelTime(seconds: TimeInterval) -> String {
        if seconds < 3600 {
            // Less than 1 hour, show minutes
            let minutes = Int(ceil(seconds / 60))
            return "\(minutes)\("minute".localized)"
        } else if seconds < 86400 {
            // Less than 1 day, show hours
            let hours = Int(ceil(seconds / 3600))
            return "\(hours)\("hour".localized)"
        } else {
            // Show days
            let days = Int(ceil(seconds / 86400))
            return "\(days)\("day".localized)"
        }
    }
}

// MARK: - Helper Methods
extension PoliceViewModel {
    var policeStationsByRegion: [String: [PoliceBase]] {
        Dictionary(grouping: policeStations) { $0.prefecture }
    }
    
    var availableRegions: [String] {
        Array(Set(policeStations.map(\.prefecture))).sorted()
    }
}

// MARK: - Private Types
private struct PoliceResponse: Codable {
    let policeStations: [PoliceBase]
}

// MARK: - CLLocationManagerDelegate
extension PoliceViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// MARK: - Distance Calculation
extension PoliceViewModel {
    func fastDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R: Double = 6371000
        
        let φ1 = lat1 * .pi / 180
        let φ2 = lat2 * .pi / 180
        let Δφ = (lat2 - lat1) * .pi / 180
        let Δλ = (lon2 - lon1) * .pi / 180
        
        let sinΔφ2 = sin(Δφ / 2)
        let sinΔλ2 = sin(Δλ / 2)
        
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

// MARK: - Search Methods
extension PoliceViewModel {
    func searchPoliceStations(_ stations: [PoliceBase], keyword: String) -> [PoliceBase] {
        guard !keyword.isEmpty else { return stations }
        
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return stations.filter { station in
            station.name.lowercased().contains(trimmedKeyword) ||
            station.prefecture.lowercased().contains(trimmedKeyword)
        }
    }
    
    func searchCurrentVisiblePoliceStations(keyword: String) -> [PoliceBase] {
        return searchPoliceStations(currentVisiblePoliceStations, keyword: keyword)
    }
}

// MARK: - Parent Police Station Methods
extension PoliceViewModel {
    /// Gets the parent police station for a given police station
    /// - Parameter police: The police station to find the parent for
    /// - Returns: The parent police station (if any)
    func getParentWithId(for police: PoliceBase) -> PoliceBase? {
        guard let parentId = police.parent else { return nil }
        
        // Find the parent based on police type hierarchy
        switch police.policeType {
        case .koban:
            // For koban, parent should be a keisatsusho
            return policeStations.first { station in
                station.id == parentId && station.policeType == .keisatsusho
            }
            
        case .keisatsusho:
            // For keisatsusho, parent should be a honbu
            return policeStations.first { station in
                station.id == parentId && station.policeType == .honbu
            }
            
        case .honbu:
            // Honbu has no parent
            return nil
        }
    }
    
    /// Gets the complete hierarchy chain for a police station
    /// - Parameter police: The police station to get the hierarchy for
    /// - Returns: Array of police stations in hierarchical order (from lowest to highest)
    func getPoliceHierarchy(for police: PoliceBase) -> [PoliceBase] {
        var hierarchy: [PoliceBase] = [police]
        var current = police
        
        // Build the hierarchy chain
        while let parent = getParentWithId(for: current) {
            hierarchy.append(parent)
            current = parent
        }
        
        return hierarchy
    }
}

// Add this structure to match your JSON format
struct PoliceDataWrapper: Codable {
    let polices: [PoliceBase]
}
