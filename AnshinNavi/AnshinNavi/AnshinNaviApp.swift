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
    @StateObject private var shelterViewModel: ShelterViewModel
    @StateObject private var policeViewModel: PoliceViewModel
    @StateObject private var mapViewModel: MapViewModel
    
    init() {
        // First load saved settings
        Self.loadSavedSettings()
        
        // Then initialize view models
        let shelterVM = ShelterViewModel()
        let policeVM = PoliceViewModel()
        _shelterViewModel = StateObject(wrappedValue: shelterVM)
        _policeViewModel = StateObject(wrappedValue: policeVM)
        _mapViewModel = StateObject(wrappedValue: MapViewModel(
            shelterViewModel: shelterVM,
            policeViewModel: policeVM
        ))
    }
    
    private static func loadSavedSettings() {
        // Load max annotations
        let savedMaxAnnotations = UserDefaults.standard.integer(forKey: "MaxAnnotations")
        if savedMaxAnnotations > 0 {
            MAX_ANNOTATIONS = savedMaxAnnotations
        }
        
        // Load default annotation type
        if let savedDefaultAnnotationType = UserDefaults.standard.object(forKey: "DefaultAnnotationType") as? Int,
           let annotationType = CurrentAnnotationType(rawValue: savedDefaultAnnotationType) {
            ANNOTATION_TYPE = annotationType
        }
        
        // Load map type
        if let savedMapType = UserDefaults.standard.string(forKey: "MapType"),
           let mapType = MapType(rawValue: savedMapType) {
            MAP_TYPE = mapType
        }
        
        // Load font size
        if let savedFontSize = UserDefaults.standard.string(forKey: "FontSize"),
           let fontSize = FontSize(rawValue: savedFontSize) {
            FONT_SIZE = fontSize
        }
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

