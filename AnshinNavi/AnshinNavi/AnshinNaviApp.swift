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
    
    var body: some Scene {
        WindowGroup {
            // Main content: MapView displayed directly
            MapView()
                .ignoresSafeArea()
                .environmentObject(shelterViewModel)
            
            // Uncomment to display ListSheltersView instead of MapView
            // ListSheltersView()
            //     .environmentObject(shelterViewModel)
        }
    }
}

