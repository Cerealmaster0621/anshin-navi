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
