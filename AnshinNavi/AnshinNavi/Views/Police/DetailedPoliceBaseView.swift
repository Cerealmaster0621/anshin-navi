//
//  DetailedPoliceBaseView.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/21.
//

import Foundation
import SwiftUI

struct DetailedPoliceBaseView: View {
    @EnvironmentObject var policeViewModel: PoliceViewModel
    let policeBase: PoliceBase
    @Binding var activeSheet: CurrentSheet?
    @StateObject private var networkReachability = NetworkReachability()
    @State private var showingCoordinatesCopied = false
    @State private var showingAddressCopied = false
    
    private var shareText: String {
        String(format: "police_share_message".localized,
               policeBase.name,
               policeBase.fullNotation,
               "https://maps.apple.com/?q=\(policeBase.latitude),\(policeBase.longitude)",
               "https://www.google.com/maps/search/?api=1&query=\(policeBase.latitude),\(policeBase.longitude)")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerView
                mainContentView
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .overlay(toastOverlay)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(policeBase.name)
                    .font(.system(size: 32, weight: .bold))
                locationInfoView
            }
            Spacer()
            actionButtons
        }
    }
    
    private var locationInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            distanceText
            policeTypeTag
        }
    }
    
    private var distanceText: some View {
        Group {
            if let userLocation = policeViewModel.userLocation {
                let distance = policeViewModel.fastDistance(
                    lat1: userLocation.coordinate.latitude,
                    lon1: userLocation.coordinate.longitude,
                    lat2: policeBase.latitude,
                    lon2: policeBase.longitude
                )
                Text("\(policeBase.prefecture) ･ \(policeViewModel.formatDistance(meters: distance))\(!policeBase.isCoordinatesTrustful ? " ･ \("coordinates_not_trustful".localized)" : "")")
            } else {
                Text("\(policeBase.prefecture)\(!policeBase.isCoordinatesTrustful ? " ･ \("coordinates_not_trustful".localized)" : "")")
            }
        }
        .font(.system(size: 17))
        .foregroundColor(.secondary)
    }
    
    private var policeTypeTag: some View {
        HStack(spacing: 4) {
            Image(systemName: policeBase.policeType.iconName)
                .foregroundColor(.blue)
            Text(policeBase.policeType.localizedName)
                .font(.system(size: 15))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 4) {
            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(.systemGray4))
            }
            Button(action: { activeSheet = .bottomDrawer }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(.systemGray4))
            }
        }
    }
    
    // MARK: - Main Content Views
    private var mainContentView: some View {
        VStack(spacing: 20) {
            if networkReachability.isConnected && !policeBase.phoneNumber.isEmpty && policeBase.phoneNumber != "nan" {
                emergencyCallButton
            }
            
            informationCards
            
            if let parent = policeViewModel.getParentWithId(for: policeBase) {
                parentPoliceButton(parent)
            }
            
            if networkReachability.isConnected {
                mapButtons
            }
        }
    }
    
    private var emergencyCallButton: some View {
        Button(action: {
            guard let url = URL(string: "tel://\(policeBase.phoneNumber)") else { return }
            UIApplication.shared.open(url)
        }) {
            HStack {
                Image(systemName: "phone.fill")
                Text(policeBase.phoneNumber)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 2)
        }
    }
    
    private var coordinatesWarning: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("coordinates_might_not_be_accurate".localized)
                .font(.system(size: 15))
        }
        .foregroundColor(.orange)
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var informationCards: some View {
        Group {
            addressCard
            coordinatesCard
            if !policeBase.remarks.isEmpty && policeBase.remarks != "nan" {
                remarksCard
            }
        }
    }
    
    private var mapButtons: some View {
        VStack(spacing: 12) {
            mapButton(
                title: "open_in_apple_maps".localized,
                icon: "map.fill",
                url: "http://maps.apple.com/?q=\(policeBase.latitude),\(policeBase.longitude)"
            )
            
            mapButton(
                title: "open_in_google_maps".localized,
                icon: "globe",
                url: "https://www.google.com/maps/search/?api=1&query=\(policeBase.latitude),\(policeBase.longitude)"
            )
        }
        .padding(.top, 10)
    }
    
    // MARK: - Information Cards
    private var addressCard: some View {
        InformationCard(title: "address".localized, icon: "mappin.circle.fill") {
            Button(action: {
                UIPasteboard.general.string = policeBase.fullNotation
                showingAddressCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showingAddressCopied = false
                }
            }) {
                HStack {
                    Text(policeBase.fullNotation)
                        .font(.system(size: 17))
                    Spacer()
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            .foregroundColor(.primary)
        }
    }
    
    private var coordinatesCard: some View {
        InformationCard(title: "coordinates".localized, icon: "location.circle.fill") {
            Button(action: {
                let coordinates = "\(String(format: "latitude".localized)): \(String(format: "%.6f", policeBase.latitude)), \(String(format: "longitude".localized)): \(String(format: "%.6f", policeBase.longitude))"
                UIPasteboard.general.string = coordinates
                showingCoordinatesCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showingCoordinatesCopied = false
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(String(format: "latitude".localized)): \(String(format: "%.6f", policeBase.latitude))")
                        Text("\(String(format: "longitude".localized)): \(String(format: "%.6f", policeBase.longitude))")
                    }
                    .font(.system(size: 17))
                    Spacer()
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            .foregroundColor(.primary)
        }
    }
    
    private func parentPoliceButton(_ parent: PoliceBase) -> some View {
        Button(action: {
            policeViewModel.selectedPoliceStation = parent
        }) {
            HStack {
                Text(String(format: "view_parent_police".localized, parent.policeType.localizedName))
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(MapButtonStyle())
    }
    
    private var remarksCard: some View {
        InformationCard(title: "remarks".localized, icon: "info.circle.fill") {
            Text(policeBase.remarks)
                .font(.system(size: 17))
        }
    }
    
    private func mapButton(title: String, icon: String, url: String) -> some View {
        Button(action: {
            guard let url = URL(string: url) else { return }
            UIApplication.shared.open(url)
        }) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(MapButtonStyle())
    }
    
    private var toastOverlay: some View {
        Group {
            if showingCoordinatesCopied {
                ToastView(message: "coordinates_copied".localized, isShowing: $showingCoordinatesCopied)
            } else if showingAddressCopied {
                ToastView(message: "address_copied".localized, isShowing: $showingAddressCopied)
            }
        }
    }
}

// MARK: - Helper Views
private struct InformationCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            content
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

