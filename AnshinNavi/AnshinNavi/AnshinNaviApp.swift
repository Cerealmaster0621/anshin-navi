//
//  AnshinNaviApp.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/14.
//

import SwiftUI
import SwiftData
import MapKit

@main
struct AnshinNaviApp: App {
    @StateObject private var shelterViewModel = ShelterViewModel()
    @StateObject private var policeViewModel = PoliceViewModel()
    @StateObject private var mapViewModel: MapViewModel
    
    init() {
        let shelterVM = ShelterViewModel()
        let policeVM = PoliceViewModel()
        _shelterViewModel = StateObject(wrappedValue: shelterVM)
        _policeViewModel = StateObject(wrappedValue: policeVM)
        _mapViewModel = StateObject(wrappedValue: MapViewModel(
            shelterViewModel: shelterVM,
            policeViewModel: policeVM
        ))
    }
    
    var body: some Scene {
        WindowGroup {
            MapContainerView()
                .environmentObject(shelterViewModel)
                .environmentObject(policeViewModel)
                .environmentObject(mapViewModel)
        }
    }
}

