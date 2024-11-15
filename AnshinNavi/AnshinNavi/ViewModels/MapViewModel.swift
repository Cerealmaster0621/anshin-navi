//
//  ShelterViewModel.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/14.
//

import Foundation
import MapKit
import SwiftUI

final class MapViewModel: ObservableObject {
    // MARK: - Published Properties
    /// The current visible region of the map
    @Published var region: MKCoordinateRegion
    
    /// The location selected by the user on the map (if any)
    @Published var selectedLocation: CLLocationCoordinate2D?
    
    // Reference to ShelterViewModel
    let shelterViewModel: ShelterViewModel
    
    init(region: MKCoordinateRegion = MKCoordinateRegion()) {
        self.region = region
        self.shelterViewModel = ShelterViewModel()
    }
    
    // MARK: - Map Interaction Methods
    
    /// Updates the map's visible region
    /// - Parameter region: The new region to display
    func updateRegion(_ region: MKCoordinateRegion) {
        self.region = region
    }
    
    /// Marks a location as selected on the map
    /// - Parameter coordinate: The coordinate to select
    func selectLocation(_ coordinate: CLLocationCoordinate2D) {
        self.selectedLocation = coordinate
    }
    
    // Example method to get shelters in the current map region
    func getSheltersInCurrentRegion() -> [Shelter] {
        return shelterViewModel.getSheltersInMapRegion(region)
    }
    
    // add more methods to interact with shelters via shelterViewModel
}
