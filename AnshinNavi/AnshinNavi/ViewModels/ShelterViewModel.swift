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

enum DataError: Error {
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
    @Environment(\.modelContext) private var modelContext

       func importCSVData() {
           guard let fileURL = Bundle.main.url(forResource: "全国指定緊急避難場所データ", withExtension: "csv") else {
               print("CSV-Datei nicht gefunden.")
               return
           }

           do {
               let data = try String(contentsOf: fileURL, encoding: .utf8)
               let rows = data.components(separatedBy: "\n")
               
               // Überspringe die Kopfzeile und parsiere jede Zeile in ein Shelter-Objekt
               for (index, row) in rows.enumerated() {
                   guard index > 0 else { continue }  // Überspringt die Kopfzeile
                   
                   let columns = row.components(separatedBy: ",")
                   guard columns.count >= 15 else { continue } // Sicherstellen, dass genügend Spalten vorhanden sind
                   
                   // Mapping der CSV-Spalten zu Shelter-Objekten
                   let shelter = Shelter(
                       regionCode: columns[0],
                       regionName: columns[1],
                       number: columns[2],
                       name: columns[3],
                       generalFlooding: columns[5] == "1",
                       landslide: columns[6] == "1",
                       earthquake: columns[8] == "1",
                       tsunami: columns[9] == "1",
                       fire: columns[10] == "1",
                       internalFlooding: columns[11] == "1",
                       isSameAsRegion: columns[13] == "1",
                       latitude: Double(columns[14]) ?? 0.0,
                       longitude: Double(columns[15]) ?? 0.0,
                       additionalInfo: columns.count > 16 ? columns[16] : ""
                   )
                   
                   // Speichern in Swift Data
                   modelContext.insert(shelter)
               }
               
               // Speichern der Änderungen im Modellkontext
               try modelContext.save()
               print("Daten erfolgreich importiert und gespeichert.")
               
           } catch {
               print("Fehler beim Importieren der CSV-Daten: \(error)")
           }
       }
    // properties
    @Published var shelters: [Shelter] = []
    @Published var selectedShelter: Shelter?
    @Published var errorMessage: String?

    private let jsonFileName: String

    // initializer
    init(jsonFileName: String = SHELTERS_CSV_FILE_NAME) {
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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let url = Bundle.main.url(forResource: self?.jsonFileName, withExtension: "json") else {
                    throw DataError.fileNotFound("Could not find \(self?.jsonFileName ?? "unknown").json")
                }
                
                let data = try Data(contentsOf: url)
                let decodedShelters = try JSONDecoder().decode([Shelter].self, from: data)
                
                DispatchQueue.main.async {
                    self?.shelters = decodedShelters
                    self?.errorMessage = nil
                }
            } catch let error as DataError {
                DispatchQueue.main.async {
                    self?.handleError(error)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.handleError(DataError.decodingError(error.localizedDescription))
                }
            }
        }
    }

    /// Handle and display errors
    private func handleError(_ error: DataError) {
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



