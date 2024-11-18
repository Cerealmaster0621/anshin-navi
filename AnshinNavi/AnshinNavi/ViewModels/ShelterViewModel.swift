//
//  ShelterViewModel.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/16.
//

import Foundation
import MapKit
import SwiftUI

enum DataError: Error {
    case fileNotFound(String)
    case decodingError(String)
    case invalidData
}

enum DisasterType: CaseIterable {
    case generalFlooding
    case landslide
    case highTide
    case earthquake
    case tsunami
    case fire
    case internalFlooding
    case volcano
}

final class ShelterViewModel: ObservableObject {
    @Published private(set) var shelters: [Shelter] = []
    @Published var selectedShelter: Shelter?
    
    private let jsonFileName = "shelters"
    private let jsonFileExtension = "json"
    private let defaultRadius: CLLocationDistance = 2000 // 2km
    
    weak var mapView: MKMapView?
    
    init() {
        loadShelters()
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
    
    func filterSheltersByRegion(regionCode: String) -> [Shelter] {
        shelters.filter { $0.regionCode == regionCode }
    }
    
    /// Filters shelters by disaster type
    /// - Parameter disasterType: The type of disaster to filter by
    /// - Returns: Array of shelters suitable for the specified disaster type
    func filterShelterByDisasterType(_ disasterType: DisasterType) -> [Shelter] {
        shelters.filter { shelter in
            switch disasterType {
            case .generalFlooding: return shelter.generalFlooding
            case .landslide: return shelter.landslide
            case .highTide: return shelter.highTide
            case .earthquake: return shelter.earthquake
            case .tsunami: return shelter.tsunami
            case .fire: return shelter.fire
            case .internalFlooding: return shelter.internalFlooding
            case .volcano: return shelter.volcano
            }
        }
    }
    
    func searchShelters(query: String) -> [Shelter] {
        guard !query.isEmpty else { return shelters }
        
        let searchQuery = query.lowercased()
        return shelters.filter {
            $0.name.lowercased().contains(searchQuery) ||
            $0.address.lowercased().contains(searchQuery)
        }
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
