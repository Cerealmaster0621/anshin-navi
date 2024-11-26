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
    @State private var isLoading = true
    
    init() {
        // First load saved settings
        Self.loadSavedSettings()
        
        // Then initialize view models
        let shelterVM = ShelterViewModel()
        let policeVM = PoliceViewModel()
        let routeViewModel = RouteViewModel()
        _shelterViewModel = StateObject(wrappedValue: shelterVM)
        _policeViewModel = StateObject(wrappedValue: policeVM)
        _mapViewModel = StateObject(wrappedValue: MapViewModel(
            shelterViewModel: shelterVM,
            policeViewModel: policeVM,
            routeViewModel: routeViewModel
        ))
        
        // Configure fonts for the entire app
        if isUserAppJapanese {
            // Japanese font configuration
            UINavigationBar.appearance().largeTitleTextAttributes = [
                .font: UIFont.systemFont(ofSize: 34, weight: .bold)
            ]
            UINavigationBar.appearance().titleTextAttributes = [
                .font: UIFont.systemFont(ofSize: 17, weight: .regular)
            ]
            
            let font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
            UILabel.appearance().font = font
            UITextField.appearance().font = font
            UITextView.appearance().font = font
        } else {
            // English font configuration (SF Pro)
            UINavigationBar.appearance().largeTitleTextAttributes = [
                .font: UIFont.systemFont(ofSize: 34, weight: .bold)
            ]
            UINavigationBar.appearance().titleTextAttributes = [
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ]
            
            let defaultFont = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .regular)
            UILabel.appearance().font = defaultFont
            UITextField.appearance().font = defaultFont
            UITextView.appearance().font = defaultFont
            
            UILabel.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).font = .preferredFont(forTextStyle: .body)
            UIButton.appearance().titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        }
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
            ZStack {
                if isLoading {
                    LoadingView()
                } else {
                    MapContainerView()
                        .environmentObject(shelterViewModel)
                        .environmentObject(policeViewModel)
                        .environmentObject(mapViewModel)
                }
            }
            .onAppear {
                // Simulate loading or do actual initialization
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isLoading = false
                    }
                }
            }
        }
    }
}

