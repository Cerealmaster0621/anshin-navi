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
    
    var body: some Scene {
        WindowGroup {
            MapContainerView()
                .environmentObject(shelterViewModel)
                .environmentObject(policeViewModel)
        }
    }
}

