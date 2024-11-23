import SwiftUI
import MapKit

struct MBDPoliceView: View {
    @EnvironmentObject var policeViewModel: PoliceViewModel
    @Binding var currentAnnotationType: CurrentAnnotationType
    let mapView: MKMapView
    let shelterMapHandler: ShelterMapHandler
    let policeMapHandler: PoliceMapHandler
    let isSmallDetent: Bool
    let selectedPoliceTypes: [PoliceType]
    @State private var localPolices: [PoliceBase] = []
    @State private var showingMorePolices = false
    @State private var closestPolice: PoliceBase?
    
    private var policeTypeText: String {
        "police_facility_lowercase".localized
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isSmallDetent {
                // Small detent content
                Button(action: {
                    if policeViewModel.visiblePoliceCount > 0 {
                        showingMorePolices = true
                    }
                }) {
                    VStack(alignment: .center, spacing: 4) {
                        Text("\(policeViewModel.visiblePoliceCount)件の\(policeTypeText)が検索されました")
                            .font(.system(size: dynamicSize(baseSize: FONT_SIZE.size * 1.125)))
                            .foregroundColor(.primary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        
                        if !selectedPoliceTypes.isEmpty {
                            Text(selectedPoliceTypes.map { $0.localizedName }.joined(separator: "・"))
                                .font(.system(size: dynamicSize(baseSize: BASE_FONT_SIZE)))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(policeViewModel.visiblePoliceCount == 0)
                .fullScreenCover(isPresented: $showingMorePolices) {
                    MBDViewMorePolices(selectedPoliceTypes: selectedPoliceTypes)
                }
            } else {
                // Regular content
                VStack(alignment: .leading, spacing: 0) {
                    // Header with count and type
                    HStack {
                        Text("\(policeViewModel.visiblePoliceCount)件の\(policeTypeText)")
                            .font(.system(size: FONT_SIZE.size * 1.25, weight: .bold))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Filter chips in horizontal scroll
                    if !selectedPoliceTypes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedPoliceTypes, id: \.self) { filter in
                                    Text(filter.localizedName)
                                        .font(.system(size: FONT_SIZE.size))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 12)
                    }
                    
                    Spacer()
                    
                    // Closest police facility card
                    if let userLocation = policeViewModel.userLocation,
                       let closestPolice = policeViewModel.getClosestPoliceStation(
                        to: userLocation,
                        matching: selectedPoliceTypes
                       ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("あなたと最寄りの\(policeTypeText)")
                                .font(.system(size: FONT_SIZE.size * 0.875))
                                .foregroundColor(Color(.systemGray))
                                .padding(.horizontal)
                            
                            Button(action: {
                                policeViewModel.selectedPoliceStation = closestPolice
                                self.closestPolice = closestPolice
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: FONT_SIZE.size * 1.75))
                                        .foregroundColor(Color(.systemBlue))
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(closestPolice.name)
                                            .font(.system(size: FONT_SIZE.size))
                                            .foregroundColor(.primary)
                                        
                                        let distance = policeViewModel.fastDistance(
                                            lat1: userLocation.coordinate.latitude,
                                            lon1: userLocation.coordinate.longitude,
                                            lat2: closestPolice.latitude,
                                            lon2: closestPolice.longitude
                                        )
                                        
                                        Text("\(closestPolice.prefecture) ･ \(policeViewModel.formatDistance(meters: distance))")
                                            .font(.system(size: FONT_SIZE.size * 0.875))
                                            .foregroundColor(Color(.systemGray))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                        .frame(height: 12)
                    
                    // Library section
                    MBDAnnotationCardView(currentAnnotationType: $currentAnnotationType, mapView: mapView, shelterMapHandler: shelterMapHandler, policeMapHandler: policeMapHandler)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Search Results section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if policeViewModel.currentVisiblePoliceStations.count <= 0 {
                                Text("検索結果がありません")
                                    .font(.system(size: FONT_SIZE.size * 0.875))
                                    .foregroundColor(Color(.systemGray))    
                            } else {
                                Text("検索結果")
                                    .font(.system(size: FONT_SIZE.size * 0.875))
                                    .foregroundColor(Color(.systemGray))
                            }
                            
                            Spacer()
                            
                            if policeViewModel.visiblePoliceCount > 3 {
                                Button(action: {
                                    showingMorePolices = true
                                }) {
                                    Text("もっと見る")
                                        .font(.system(size: FONT_SIZE.size * 0.875))
                                        .foregroundColor(.blue)
                                }
                                .fullScreenCover(isPresented: $showingMorePolices) {
                                    MBDViewMorePolices(selectedPoliceTypes: selectedPoliceTypes)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Results cards (limited to 3)
                        VStack(spacing: 1) {
                            ForEach(policeViewModel.currentVisiblePoliceStations.prefix(3), id: \.id) { police in
                                Button(action: {
                                    policeViewModel.selectedPoliceStation = police
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: FONT_SIZE.size * 1.75))
                                            .foregroundColor(Color(.systemBlue))
                                            .frame(width: 40)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(police.name)
                                                .font(.system(size: FONT_SIZE.size))
                                                .foregroundColor(.primary)
                                            
                                            if let userLocation = policeViewModel.userLocation {
                                                let distance = policeViewModel.fastDistance(
                                                    lat1: userLocation.coordinate.latitude,
                                                    lon1: userLocation.coordinate.longitude,
                                                    lat2: police.latitude,
                                                    lon2: police.longitude
                                                )
                                                
                                                Text("\(police.prefecture) ･ \(policeViewModel.formatDistance(meters: distance))")
                                                    .font(.system(size: FONT_SIZE.size * 0.875))
                                                    .foregroundColor(Color(.systemGray))
                                            } else {
                                                Text(police.prefecture)
                                                    .font(.system(size: FONT_SIZE.size * 0.875))
                                                    .foregroundColor(Color(.systemGray))
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                }
                            }
                        }
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Share button
                        Button(action: {
                            shareLocation()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("現在地を共有")
                                    .font(.system(size: FONT_SIZE.size))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                        .frame(height: 24)
                }
            }
        }
        .onAppear {
            updateClosestPolice()
        }
        .onChange(of: policeViewModel.userLocation) { _ in
            updateClosestPolice()
        }
    }
    
    private func updateClosestPolice() {
        if let userLocation = policeViewModel.userLocation {
            closestPolice = policeViewModel.getClosestPoliceStation(
                to: userLocation,
                matching: selectedPoliceTypes
            )
        }
    }
    
    private func shareLocation() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController,
              let userLocation = policeViewModel.userLocation else { return }
        
        var topController = rootVC
        while let presentedVC = topController.presentedViewController {
            topController = presentedVC
        }
        
        var shareItems: [Any] = []
        
        let coordinates = String(format: "%.6f, %.6f", 
            userLocation.coordinate.latitude,
            userLocation.coordinate.longitude
        )
        
        let appleMapsURL = String(format: SHARE_APPLE_MAPS_URL_TEMPLATE,
            userLocation.coordinate.latitude,
            userLocation.coordinate.longitude
        )     
        let googleMapsURL = String(format: SHARE_GOOGLE_MAPS_URL_TEMPLATE,
            userLocation.coordinate.latitude,
            userLocation.coordinate.longitude
        )
        
        let message = String(format: SHARE_MESSAGE_TEMPLATE,
            coordinates,
            appleMapsURL,
            googleMapsURL
        )
        
        shareItems.append(message)
        
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(
                activityItems: shareItems,
                applicationActivities: nil
            )
            
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = window
                popoverController.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            topController.present(activityVC, animated: true)
        }
    }
}
