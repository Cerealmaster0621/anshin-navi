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
    // Initialize shelter view model as a state object
    @StateObject private var shelterViewModel = ShelterViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TabView {
                    // Map View Tab
                    MapView()
                        .tabItem {
                            Label("マップ", systemImage: "map")
                        }
                    
                    // List View Tab (if you want to add a list view later)
                    // ListSheltersView()
                    //     .tabItem {
                    //         Label("一覧", systemImage: "list.bullet")
                    //     }
                }
                .environmentObject(shelterViewModel)
            }
        }
    }
}
