//
//  NavigationDrawerView.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/25.
//

import Foundation
import SwiftUI
import MapKit

enum NavigationDestinationType {
    case shelter(Shelter)
    case police(PoliceBase)
}

struct NavigationDrawerView: View {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @EnvironmentObject var policeViewModel: PoliceViewModel
    let destinationType: NavigationDestinationType
    @Binding var activeSheet: CurrentSheet?
    @Binding var previousSheet : CurrentSheet?
    @State private var walkingTimeText: String? = nil
    @State private var distanceText: String? = nil
    
    private var destinationName: String {
        switch destinationType {
        case .shelter(let shelter):
            return shelter.name
        case .police(let police):
            return police.name
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 6) {
                headerView
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
            }
        }
        .presentationDetents([.height(80)])
        .presentationDragIndicator(.visible)
        .task {
            await updateNavigationInfo()
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(destinationName)
                .font(.system(size: FONT_SIZE.size * 1.25, weight: .bold))
                .lineLimit(1)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                Text("まで")
                    .font(.system(size: FONT_SIZE.size))
                    .foregroundColor(.secondary)
                
                Group {
                    if let distance = distanceText {
                        Text(distance)
                    } else {
                        Text("...")
                    }
                }
                .font(.system(size: FONT_SIZE.size))
                .foregroundColor(.secondary)
                
                if let walkingTime = walkingTimeText {
                    Group {
                        Text("/")
                        Text(walkingTime)
                    }
                    .font(.system(size: FONT_SIZE.size))
                    .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var closeButton: some View {
        Button(action: {
            previousSheet = activeSheet
            activeSheet = previousSheet == .detail ? .detail : .bottomDrawer
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: FONT_SIZE.size * 1.5))
                .foregroundColor(Color(.systemGray4))
        }
    }
    
    private func updateNavigationInfo() async {
        switch destinationType {
        case .shelter(let shelter):
            // Calculate walking time for shelter
            walkingTimeText = await shelterViewModel.calculateWalkingTime(to: shelter)
            
            // Calculate distance for shelter
            if let userLocation = shelterViewModel.userLocation {
                let distance = shelterViewModel.fastDistance(
                    lat1: userLocation.coordinate.latitude,
                    lon1: userLocation.coordinate.longitude,
                    lat2: shelter.latitude,
                    lon2: shelter.longitude
                )
                distanceText = shelterViewModel.formatDistance(meters: distance)
            }
            
        case .police(let police):
            // Calculate walking time for police
            walkingTimeText = await policeViewModel.calculateWalkingTime(to: police)
            
            // Calculate distance for police
            if let userLocation = policeViewModel.userLocation {
                let distance = policeViewModel.fastDistance(
                    lat1: userLocation.coordinate.latitude,
                    lon1: userLocation.coordinate.longitude,
                    lat2: police.latitude,
                    lon2: police.longitude
                )
                distanceText = policeViewModel.formatDistance(meters: distance)
            }
        }
    }
}
