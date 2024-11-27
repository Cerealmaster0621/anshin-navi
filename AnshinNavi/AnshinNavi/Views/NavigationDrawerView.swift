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

extension NavigationDestinationType {
    var tintColor: Color {
        switch self {
        case .shelter:
            return .green
        case .police:
            return .blue
        }
    }
}

struct NavigationDrawerView: View {
    @EnvironmentObject private var shelterViewModel: ShelterViewModel
    @EnvironmentObject private var policeViewModel: PoliceViewModel
    let destinationType: NavigationDestinationType
    @Binding var activeSheet: CurrentSheet?
    @Binding var previousSheet: CurrentSheet?
    
    // Add animation states
    @State private var isLoading = true
    @State private var showInfo = false
    @State private var walkingTimeText: String?
    
    @State private var updateTimer: Timer?
    
    private var destinationName: String {
        switch destinationType {
        case .shelter(let shelter): return shelter.name
        case .police(let police): return police.name
        }
    }
    
    private var destinationIcon: String {
        switch destinationType {
        case .shelter: return "house.fill"
        case .police: return "building.columns.fill"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main content container
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 5)
                    .frame(height: 80)
                    .overlay {
                        HStack(spacing: 16) {
                            // Destination icon with pulsing effect
                            Image(systemName: destinationIcon)
                                .font(.system(size: 24))
                                .foregroundColor(destinationType.tintColor)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(destinationType.tintColor.opacity(0.1))
                                        .overlay(
                                            Circle()
                                                .stroke(destinationType.tintColor, lineWidth: 2)
                                                .scaleEffect(isLoading ? 1.2 : 1.0)
                                                .opacity(isLoading ? 0 : 1)
                                                .animation(
                                                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                                    value: isLoading
                                                )
                                        )
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                // Destination name with slide-in animation
                                Text(destinationName)
                                    .font(.system(size: FONT_SIZE.size * 1.1, weight: .semibold))
                                    .lineLimit(1)
                                    .opacity(showInfo ? 1 : 0)
                                    .offset(x: showInfo ? 0 : -20)
                                
                                // Distance and time info with fade-in animation
                                HStack(spacing: 8) {
                                    if let distance = calculateDistance() {
                                        Label(distance, systemImage: "arrow.forward")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let time = walkingTimeText {
                                        Label(time, systemImage: "figure.walk")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .font(.system(size: FONT_SIZE.size * 0.9))
                                .opacity(showInfo ? 1 : 0)
                                .offset(y: showInfo ? 0 : 10)
                            }
                            
                            Spacer()
                            
                            // Close button with rotation animation
                            Button(action: handleClose) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                                    .rotationEffect(.degrees(showInfo ? 0 : 90))
                            }
                        }
                        .padding(.horizontal, 16)
                    }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Color.clear)
        }
        .presentationDetents([.height(100)])
        .task {
            await updateNavigationInfo()
            withAnimation(.easeOut(duration: 0.3)) {
                showInfo = true
                isLoading = false
            }
            
            // Start periodic updates
            updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
                Task {
                    await updateNavigationInfo()
                }
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            updateTimer?.invalidate()
            updateTimer = nil
        }
    }
    
    private func handleClose() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showInfo = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            previousSheet = activeSheet
            activeSheet = previousSheet == .detail ? .detail : .bottomDrawer
        }
    }
    
    private func updateNavigationInfo() async {
        switch destinationType {
        case .shelter(let shelter):
            walkingTimeText = await shelterViewModel.calculateWalkingTime(to: shelter)
        case .police(let police):
            walkingTimeText = await policeViewModel.calculateWalkingTime(to: police)
        }
    }
    
    private func calculateDistance() -> String? {
        switch destinationType {
        case .shelter(let shelter):
            guard let userLocation = shelterViewModel.userLocation else { return nil }
            let distance = shelterViewModel.fastDistance(
                lat1: userLocation.coordinate.latitude,
                lon1: userLocation.coordinate.longitude,
                lat2: shelter.latitude,
                lon2: shelter.longitude
            )
            return shelterViewModel.formatDistance(meters: distance)
            
        case .police(let police):
            guard let userLocation = policeViewModel.userLocation else { return nil }
            let distance = policeViewModel.fastDistance(
                lat1: userLocation.coordinate.latitude,
                lon1: userLocation.coordinate.longitude,
                lat2: police.latitude,
                lon2: police.longitude
            )
            return policeViewModel.formatDistance(meters: distance)
        }
    }
}
