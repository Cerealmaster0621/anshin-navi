//
//  ShelterViewModel.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/14.
//

import Foundation
import MapKit
import SwiftUI
import SwiftData

enum ShelterError: Error {
    case fileNotFound(String)
    case decodingError(String)
    case invalidData
}

enum DisasterType {
    case generalFlooding
    case landslide
    case earthquake
    case tsunami
    case fire
    case internalFlooding
}

// managing shelter data and actions
class ShelterViewModel: ObservableObject {
    // properties
    @Published var shelters: [Shelter] = []
    @Published var selectedShelter: Shelter?
    @Published var errorMessage: String?

    private let jsonFileName: String

    // initializer
    init(jsonFileName: String = sheltersJsonFileName) {
        self.jsonFileName = jsonFileName
        loadShelters()
    }

    // ACTIONS

    // filter shelters by region code
    func filterSheltersByRegion(regionCode: String) -> [Shelter] {
        return shelters.filter { $0.regionCode == regionCode }
    }

    // filter shelters by disaster type
    func filterShelterByDisasterType(_ disasterType: DisasterType) -> [Shelter] {
        return shelters.filter { shelter in
            switch disasterType {
            case .generalFlooding:
                return shelter.generalFlooding
            case .landslide:
                return shelter.landslide
            case .earthquake:
                return shelter.earthquake
            case .tsunami:
                return shelter.tsunami
            case .fire:
                return shelter.fire
            case .internalFlooding:
                return shelter.internalFlooding
            }
        }
    }

    // search shelters by name or address
    func searchShelters(query: String) -> [Shelter] {
        guard !query.isEmpty else {
            return shelters
        }

        let searchQuery = query.lowercased()
        return shelters.filter {
            $0.name.lowercased().contains(searchQuery)
        }
    }

    // sort shelters by distance from a given location(user's current location)
    func sortByDistance(from location: CLLocation) {
        shelters.sort { shelter1, shelter2 in
            let location1 = CLLocation(latitude: shelter1.latitude, longitude: shelter1.longitude)
            let location2 = CLLocation(latitude: shelter2.latitude, longitude: shelter2.longitude)

            return location1.distance(from: location) < location2.distance(from: location)
        }
    }

    // load shelters from JSON file
    private func loadShelters() {
        do {
            guard let url = Bundle.main.url(forResource: jsonFileName, withExtension: "json") else {
                throw ShelterError.fileNotFound("Could not find \(jsonFileName).json")
            }
            
            let data = try Data(contentsOf: url)
            let decodedShelters = try JSONDecoder().decode([Shelter].self, from: data)
            
            DispatchQueue.main.async {
                self.shelters = decodedShelters
                self.errorMessage = nil
            }
        } catch let error as ShelterError {
            handleError(error)
        } catch {
            handleError(ShelterError.decodingError(error.localizedDescription))
        }
    }

    /// Handle and display errors
    private func handleError(_ error: ShelterError) {
        DispatchQueue.main.async {
            switch error {
            case .fileNotFound(let message):
                self.errorMessage = "File Error: \(message)"
            case .decodingError(let message):
                self.errorMessage = "Decoding Error: \(message)"
            case .invalidData:
                self.errorMessage = "Invalid Data Error"
            }
            self.shelters = []
        }
    }
}

// Helper Methods
extension ShelterViewModel {
    /// Get shelters grouped by region
    var sheltersByRegion: [String: [Shelter]] {
        Dictionary(grouping: shelters) { $0.regionCode }
    }
    
    /// Get all unique region codes
    var availableRegions: [String] {
        Array(Set(shelters.map { $0.regionCode })).sorted()
    }
}



