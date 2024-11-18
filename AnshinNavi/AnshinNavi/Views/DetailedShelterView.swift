import SwiftUI

struct DetailedShelterView: View {
    let shelter: Shelter
    @Binding var activeSheet: CurrentSheet?
    @StateObject private var networkReachability = NetworkReachability()
    @State private var showingCoordinatesCopied = false
    @State private var showingAddressCopied = false
    
    private var shareText: String {
        """
        避難場所の位置情報を共有します
        
        \(shelter.name)
        \(shelter.address)
        
        Apple Maps:
        https://maps.apple.com/?q=\(shelter.latitude),\(shelter.longitude)
        
        Google Maps:
        https://www.google.com/maps/search/?api=1&query=\(shelter.latitude),\(shelter.longitude)
        """
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with Share and Close Buttons
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(shelter.name)
                            .font(.system(size: 32, weight: .bold))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shelter.regionName)
                                .font(.system(size: 17))
                                .foregroundColor(.secondary)
                            if shelter.isSameAsEvacuationCenter {
                                Spacer()
                                    .frame(height: 4)
                                    HStack(spacing: 4) {
                                        Button(action: {
                                            // TODO: Show explanation about evacuation center
                                        }) {
                                            Image(systemName: "questionmark.circle")
                                                .font(.system(size: 14))
                                                .foregroundColor(.blue)
                                        }
                                        Text(shelter.trueSafetyFeatures.last!.rawValue)
                                            .font(.system(size: 13))
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    Spacer()
                    // Share and Close buttons with matching style
                    HStack(spacing: 4) {
                        ShareLink(item: shareText) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(.systemGray4))
                        }
                        Button(action: {
                            activeSheet = .bottomDrawer
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(.systemGray4))
                        }
                    }
                }
                
                // Main Information Section
                VStack(spacing: 20) {
                    Group {
                        // Address with Copy Button
                        informationCard(title: "住所", icon: "mappin.circle.fill") {
                            Button(action: {
                                UIPasteboard.general.string = shelter.address
                                showingAddressCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showingAddressCopied = false
                                }
                            }) {
                                HStack {
                                    Text(shelter.address)
                                        .font(.system(size: 17))
                                    Spacer()
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                        
                        // Coordinates with Integrated Copy
                        informationCard(title: "位置座標", icon: "location.circle.fill") {
                            Button(action: {
                                let coordinates = "緯度: \(String(format: "%.6f", shelter.latitude)), 軽度: \(String(format: "%.6f", shelter.longitude))" // TODO - change copy form depends on setting
                                UIPasteboard.general.string = coordinates
                                showingCoordinatesCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showingCoordinatesCopied = false
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("緯度: \(String(format: "%.6f", shelter.latitude))")
                                            .font(.system(size: 17))
                                        Text("軽度: \(String(format: "%.6f", shelter.longitude))")
                                            .font(.system(size: 17))
                                    }
                                    Spacer()
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                    
                    // Safety Features
                    if !shelter.trueSafetyFeatures.isEmpty {
                        informationCard(title: "対応災害", icon: "shield.fill") {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(shelter.trueSafetyFeatures, id: \.self) { feature in
                                    HStack(spacing: 8) {
                                        if feature != .isSameAsEvacuationCenter {
                                            Image(systemName: feature.iconName)
                                                .foregroundColor(.blue)
                                                .font(.system(size: 16))
                                            Text(feature.rawValue)
                                                .font(.system(size: 15))
                                            Spacer()
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color(.systemGray6).opacity(0.5))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Additional Info
                    if !shelter.additionalInfo.isEmpty {
                        informationCard(title: "追加情報", icon: "info.circle.fill") {
                            Text(shelter.additionalInfo)
                                .font(.system(size: 17))
                        }
                    }
                }
                if networkReachability.isConnected {
                    VStack(spacing: 12) {
                        Button(action: {
                            openInAppleMaps()
                        }) {
                            Text("Apple マップで開く")
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
                        
                        Button(action: {
                            openInGoogleMaps()
                        }) {
                            Text("Google マップで開く")
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
                    .padding(.top, 10)
                }
                }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .overlay(
            Group {
                ToastView(message: "位置座標をコピーしました", isShowing: $showingCoordinatesCopied)
                ToastView(message: "住所をコピーしました", isShowing: $showingAddressCopied)
            }
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func informationCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
            }
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // Helper functions for opening maps
    private func openInAppleMaps() {
        let coordinates = "\(shelter.latitude),\(shelter.longitude)"
        if let encodedName = shelter.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "http://maps.apple.com/?q=\(encodedName)&ll=\(coordinates)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openInGoogleMaps() {
        let coordinates = "\(shelter.latitude),\(shelter.longitude)"
        if let encodedName = shelter.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encodedName)&ll=\(coordinates)") {
            UIApplication.shared.open(url)
        }
    }
}

struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        if isShowing {
            VStack {
                Spacer()
                Text(message)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
                    .padding(.bottom, 20)
            }
            .transition(.move(edge: .bottom))
            .animation(.spring(), value: isShowing)
        }
    }
}

struct MapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}
