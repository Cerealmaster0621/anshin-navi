import SwiftUI

struct DetailedShelterView: View {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    let shelter: Shelter
    @Binding var activeSheet: CurrentSheet?
    @StateObject private var networkReachability = NetworkReachability()
    @State private var showingCoordinatesCopied = false
    @State private var showingAddressCopied = false
    
    private var shareText: String {
        String(format: "shelter_share_message".localized,
               shelter.name,
               shelter.address,
               "https://maps.apple.com/?q=\(shelter.latitude),\(shelter.longitude)",
               "https://www.google.com/maps/search/?api=1&query=\(shelter.latitude),\(shelter.longitude)")
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
        .overlay(
            Group {
                ToastView(message: "coordinates_copied".localized, isShowing: $showingCoordinatesCopied)
                ToastView(message: "address_copied".localized, isShowing: $showingAddressCopied)
            }
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(shelter.name)
                    .font(.system(size: FONT_SIZE.size * 2, weight: .bold))
                locationInfoView
            }
            Spacer()
            actionButtons
        }
    }
    
    private var locationInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            distanceText
            if shelter.isSameAsEvacuationCenter {
                evacuationCenterTag
            }
        }
    }
    
    private var distanceText: some View {
        Group {
            if let userLocation = shelterViewModel.userLocation {
                let distance = shelterViewModel.fastDistance(
                    lat1: userLocation.coordinate.latitude,
                    lon1: userLocation.coordinate.longitude,
                    lat2: shelter.latitude,
                    lon2: shelter.longitude
                )
                Text("\(shelter.regionName) ･ \(shelterViewModel.formatDistance(meters: distance))")
            } else {
                Text(shelter.regionName)
            }
        }
        .font(.system(size: FONT_SIZE.size * 1.0))
        .foregroundColor(.secondary)
    }
    
    private var evacuationCenterTag: some View {
        HStack(spacing: 4) {
            Button(action: {
                // TODO: Show explanation about evacuation center
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: FONT_SIZE.size * 0.875))
                    .foregroundColor(.blue)
            }
            Text(shelter.trueSafetyFeatures.last!.rawValue)
                .font(.system(size: FONT_SIZE.size * 0.75))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
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
            Button(action: { activeSheet = .bottomDrawer }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: FONT_SIZE.size * 2))
                    .foregroundColor(Color(.systemGray4))
            }
        }
    }
    
    // MARK: - Main Content Views
    private var mainContentView: some View {
        VStack(spacing: 20) {
            informationCards
            
            if networkReachability.isConnected {
                mapButtons
            }
        }
    }
    
    private var informationCards: some View {
        Group {
            addressCard
            coordinatesCard
            if !shelter.trueSafetyFeatures.isEmpty {
                safetyFeaturesCard
            }
            if !shelter.additionalInfo.isEmpty {
                additionalInfoCard
            }
        }
    }
    
    // MARK: - Information Cards
    private var addressCard: some View {
        InformationCard(title: "address".localized, icon: "mappin.circle.fill") {
            Button(action: {
                UIPasteboard.general.string = shelter.address
                showingAddressCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showingAddressCopied = false
                }
            }) {
                HStack {
                    Text(shelter.address)
                        .font(.system(size: FONT_SIZE.size))
                    Spacer()
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: FONT_SIZE.size * 1.25))
                        .foregroundColor(.blue)
                }
            }
            .foregroundColor(.primary)
        }
    }
    
    private var coordinatesCard: some View {
        InformationCard(title: "coordinates".localized, icon: "location.circle.fill") {
            Button(action: {
                let coordinates = "\(String(format: "latitude".localized)): \(String(format: "%.6f", shelter.latitude)), \(String(format: "longitude".localized)): \(String(format: "%.6f", shelter.longitude))"
                UIPasteboard.general.string = coordinates
                showingCoordinatesCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showingCoordinatesCopied = false
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(String(format: "latitude".localized)): \(String(format: "%.6f", shelter.latitude))")
                        Text("\(String(format: "longitude".localized)): \(String(format: "%.6f", shelter.longitude))")
                    }
                    .font(.system(size: FONT_SIZE.size))
                    Spacer()
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: FONT_SIZE.size * 1.25))
                        .foregroundColor(.blue)
                }
            }
            .foregroundColor(.primary)
        }
    }
    
    private var safetyFeaturesCard: some View {
        InformationCard(title: "supported_disasters".localized, icon: "shield.fill") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(shelter.trueSafetyFeatures, id: \.self) { feature in
                    if feature != .isSameAsEvacuationCenter {
                        HStack(spacing: 8) {
                            Image(systemName: feature.iconName)
                                .foregroundColor(.blue)
                                .font(.system(size: FONT_SIZE.size))
                            Text(feature.rawValue)
                                .font(.system(size: FONT_SIZE.size * 0.875))
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var additionalInfoCard: some View {
        InformationCard(title: "additional_info".localized, icon: "info.circle.fill") {
            Text(shelter.additionalInfo)
                .font(.system(size: FONT_SIZE.size))
        }
    }
    
    private var mapButtons: some View {
        VStack(spacing: 12) {
            mapButton(
                title: "open_in_apple_maps".localized,
                icon: "map.fill",
                url: "http://maps.apple.com/?q=\(shelter.latitude),\(shelter.longitude)"
            )
            
            mapButton(
                title: "open_in_google_maps".localized,
                icon: "globe",
                url: "https://www.google.com/maps/search/?api=1&query=\(shelter.latitude),\(shelter.longitude)"
            )
        }
        .padding(.top, 10)
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
}

struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        if isShowing {
            VStack {
                Spacer()
                Text(message)
                    .font(.system(size: FONT_SIZE.size))
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
                    .font(.system(size: FONT_SIZE.size * 0.875, weight: .semibold))
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
