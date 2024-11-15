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
    
    init() {
        // Debug: Print all resources in the bundle
        if let resourcePath = Bundle.main.resourcePath {
            let fileManager = FileManager.default
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: resourcePath)
                print("Bundle contents:")
                contents.forEach { print($0) }
                
                // Specifically look for the Datas directory
                if let datasPath = Bundle.main.path(forResource: "Datas", ofType: nil) {
                    let datasContents = try fileManager.contentsOfDirectory(atPath: datasPath)
                    print("\nDatas directory contents:")
                    datasContents.forEach { print($0) }
                } else {
                    print("Datas directory not found in bundle")
                }
            } catch {
                print("Error listing bundle contents: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MapView()
                .ignoresSafeArea()
                .environmentObject(shelterViewModel)
        }
    }
}

