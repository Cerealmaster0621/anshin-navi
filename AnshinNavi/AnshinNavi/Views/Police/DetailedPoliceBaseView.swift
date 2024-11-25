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
    @Binding var previousSheet: CurrentSheet?
    @StateObject private var networkReachability = NetworkReachability()
    @State private var showingCoordinatesCopied = false
    @State private var showingAddressCopied = false
    @State private var walkingTimeText: String? = nil
    @State private var isCalculatingWalkingTime = true
    
    private var shareText: String {
        String(format: "police_share_message".localized,
               policeBase.policeType.localizedName,
               policeBase.name,
               policeBase.prefecture + policeBase.fullNotation,
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
                    .font(.system(size: FONT_SIZE.size * 2, weight: .bold))
                locationInfoView
            }
            Spacer()
            actionButtons
        }
    }
    
    private var locationInfoView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                distanceText
                policeTypeTag
            }
            Spacer()
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
                Text("\(policeBase.prefecture)\(policeBase.cityTownVillage) ･ \(policeViewModel.formatDistance(meters: distance))\(!policeBase.isCoordinatesTrustful ? " ･ \("coordinates_not_trustful".localized)" : "")")
            } else {
                Text("\(policeBase.prefecture)\(!policeBase.isCoordinatesTrustful ? " ･ \("coordinates_not_trustful".localized)" : "")")
            }
        }
        .font(.system(size: FONT_SIZE.size * 1.125))
        .foregroundColor(.secondary)
    }
    
    private var policeTypeTag: some View {
        HStack(spacing: 4) {
            Image(systemName: policeBase.policeType.iconName)
                .foregroundColor(.blue)
            Text(policeBase.policeType.localizedName)
                .font(.system(size: FONT_SIZE.size * 0.875))
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
                    .font(.system(size: FONT_SIZE.size * 2))
                    .foregroundColor(Color(.systemGray4))
            }
            Button(action: {
                previousSheet = activeSheet
                activeSheet = .bottomDrawer
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: FONT_SIZE.size * 2))
                    .foregroundColor(Color(.systemGray4))
            }
        }
    }
    
    // MARK: - Main Content Views
    private var mainContentView: some View {
        VStack(spacing: 20) {
            if networkReachability.isConnected {
                actionButtonsRow
            }
            
            informationCards
            
            if let parent = policeViewModel.getParentWithId(for: policeBase) {
                parentPoliceButton(parent)
            }
            
            if networkReachability.isConnected {
                mapButtons
            }
        }
        .task {
            isCalculatingWalkingTime = true
            walkingTimeText = await policeViewModel.calculateWalkingTime(to: policeBase)
            isCalculatingWalkingTime = false
        }
    }
    
    private var actionButtonsRow: some View {
        HStack(spacing: 12) {
            if !policeBase.phoneNumber.isEmpty && policeBase.phoneNumber != "nan" && policeBase.phoneNumber != "無し" && policeBase.phoneNumber != "なし" {
                emergencyCallButton
            }
            
            if policeViewModel.userLocation != nil {
                if isCalculatingWalkingTime {
                    walkingTimeLoadingButton
                } else if let walkingTimeText = walkingTimeText {
                    walkingTimeButton(walkingTimeText)
                }
            }
        }
    }
    
    private var emergencyCallButton: some View {
        Button(action: {
            guard let url = URL(string: "tel://\(policeBase.phoneNumber)") else { return }
            UIApplication.shared.open(url)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "phone.fill")
                    .font(.system(size: FONT_SIZE.size * 1.125))
                Text("発信")
                    .font(.system(size: FONT_SIZE.size * 1.125, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 2)
        }
    }
    
    private var walkingTimeLoadingButton: some View {
        HStack {
            Image(systemName: "figure.walk")
            Text("walking_time_loading".localized)
                .font(.system(size: FONT_SIZE.size * 1.125, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.blue.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 2)
    }
    
    private func walkingTimeButton(_ time: String) -> some View {
        Button(action: {
            previousSheet = activeSheet
            activeSheet = .navigation
        }) {
            HStack {
                Image(systemName: "figure.walk")
                    .transition(.slide)
                    .animation(.spring(response: 0.6), value: walkingTimeText)
                Text(String(format: "walking_time_format".localized, time))
                    .font(.system(size: FONT_SIZE.size * 1.125, weight: .semibold))
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
                .font(.system(size: FONT_SIZE.size * 0.875))
        }
        .foregroundColor(.orange)
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var informationCards: some View {
        VStack(spacing: 20) {
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
                let fullAddress = policeBase.policeType == .honbu 
                    ? policeBase.fullNotation 
                    : "\(policeBase.prefecture)\(policeBase.fullNotation)"
                UIPasteboard.general.string = fullAddress
                showingAddressCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showingAddressCopied = false
                }
            }) {
                HStack {
                    Text(policeBase.policeType == .honbu 
                        ? policeBase.fullNotation 
                        : "\(policeBase.prefecture)\(policeBase.fullNotation)")
                        .font(.system(size: FONT_SIZE.size))
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: FONT_SIZE.size * 1.125))
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
                    .font(.system(size: FONT_SIZE.size))
                    Spacer()
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: FONT_SIZE.size * 1.125))
                        .foregroundColor(.blue)
                }
            }
            .foregroundColor(.primary)
        }
    }
    
    private func parentPoliceButton(_ parent: PoliceBase) -> some View {
        Button(action: {
            previousSheet = activeSheet
            policeViewModel.selectedPoliceStation = parent
        }) {
            HStack {
                Text(String(format: "view_parent_police".localized, parent.policeType.localizedName))
                    .font(.system(size: FONT_SIZE.size))
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
            ScrollView {
                Text(policeBase.remarks)
                    .font(.system(size: FONT_SIZE.size))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: FONT_SIZE.size * 8)
        }
    }
    
    private func mapButton(title: String, icon: String, url: String) -> some View {
        Button(action: {
            guard let url = URL(string: url) else { return }
            UIApplication.shared.open(url)
        }) {
            Text(title)
                .font(.system(size: FONT_SIZE.size))
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
                    .font(.system(size: FONT_SIZE.size * 1.125))
                Text(title)
                    .font(.system(size: FONT_SIZE.size * 1.125, weight: .semibold))
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

