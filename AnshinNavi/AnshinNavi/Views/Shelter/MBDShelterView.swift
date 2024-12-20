import Foundation
import SwiftUI
import MapKit

struct MBDShelterView: View {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @Binding var currentAnnotationType: CurrentAnnotationType
    let mapView: MKMapView
    let shelterMapHandler: ShelterMapHandler
    let policeMapHandler: PoliceMapHandler
    let isSmallDetent: Bool
    let selectedShelterFilterTypes: [ShelterFilterType]
    @State private var showingMoreShelters = false
    
    private var shelterTypeText: String {
        if let lastFilter = selectedShelterFilterTypes.last,
           lastFilter == .isSameAsEvacuationCenter {
            return "shelter_lowercase".localized
        }
        return "evacuation_area_lowercase".localized
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isSmallDetent {
                // Small detent content
                Button(action: {
                    if shelterViewModel.visibleShelterCount > 0 {
                        showingMoreShelters = true
                    }
                }) {
                    VStack(alignment: .center, spacing: 4) {
                        Text("\(shelterViewModel.visibleShelterCount)件の\(shelterTypeText)が検索されました")
                            .font(.system(size: dynamicSize(baseSize: FONT_SIZE.size * 1.125)))
                            .foregroundColor(.primary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        
                        if !selectedShelterFilterTypes.isEmpty {
                            Text(selectedShelterFilterTypes.map { $0.rawValue }.joined(separator: "・"))
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
                .disabled(shelterViewModel.visibleShelterCount == 0)
                .fullScreenCover(isPresented: $showingMoreShelters) {
                    MBDViewMoreShelters(selectedFilterTypes: selectedShelterFilterTypes)
                }
            } else {
                // regular content
                VStack(alignment: .leading, spacing: 0) {
                    // Header with count and type
                    HStack {
                        Text("\(shelterViewModel.visibleShelterCount)件の指定\(shelterTypeText)")
                            .font(.system(size: FONT_SIZE.size * 1.5, weight: .bold))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Filter chips in horizontal scroll
                    if !selectedShelterFilterTypes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedShelterFilterTypes, id: \.self) { filter in
                                    Text(filter.rawValue)
                                        .font(.system(size: FONT_SIZE.size * 0.875))
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
                    
                    // Closest shelter card
                    if let userLocation = shelterViewModel.userLocation,
                       let closestShelter = shelterViewModel.getClosestShelter(
                        to: userLocation,
                        matching: selectedShelterFilterTypes
                       ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("あなたと最寄りの\(shelterTypeText)")
                                .font(.system(size: FONT_SIZE.size * 0.875))
                                .foregroundColor(Color(.systemGray))
                                .padding(.horizontal)
                            
                            Button(action: {
                                shelterViewModel.selectedShelter = closestShelter
                            }) {
                                HStack(spacing: 16) {
                                    // Location icon
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: FONT_SIZE.size * 1.75))
                                        .foregroundColor(Color(.systemGreen))
                                        .frame(width: 40)
                                    
                                    // Shelter information
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(closestShelter.name)
                                            .font(.system(size: FONT_SIZE.size))
                                            .foregroundColor(.primary)
                                        
                                        let distance = shelterViewModel.fastDistance(
                                            lat1: userLocation.coordinate.latitude,
                                            lon1: userLocation.coordinate.longitude,
                                            lat2: closestShelter.latitude,
                                            lon2: closestShelter.longitude
                                        )
                                        
                                        Text("\(closestShelter.regionName) ･ \(shelterViewModel.formatDistance(meters: distance))")
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
                        .frame(height:12)
                    
                    // Library section
                    MBDAnnotationCardView(currentAnnotationType: $currentAnnotationType, mapView: mapView, shelterMapHandler: shelterMapHandler, policeMapHandler: policeMapHandler)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Search Results section
                    VStack(alignment: .leading, spacing: 8) {
                        // Header with "View More" button
                        HStack {
                            if shelterViewModel.currentVisibleShelters.count <= 0 {
                                Text("検索結果がありません")
                                    .font(.system(size: FONT_SIZE.size * 0.875))
                                    .foregroundColor(Color(.systemGray))    
                            } else{
                                Text("検索結果")
                                    .font(.system(size: FONT_SIZE.size * 0.875))
                                    .foregroundColor(Color(.systemGray))
                            }
                            
                            Spacer()
                            
                            if shelterViewModel.currentVisibleShelters.count > 3 {
                                Button(action: {
                                    showingMoreShelters = true
                                }) {
                                    Text("もっと見る")
                                        .font(.system(size: FONT_SIZE.size * 0.875))
                                        .foregroundColor(.blue)
                                }
                                .fullScreenCover(isPresented: $showingMoreShelters) {
                                    MBDViewMoreShelters(selectedFilterTypes: selectedShelterFilterTypes)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Results cards (limited to 3)
                        VStack(spacing: 1) {
                            ForEach(shelterViewModel.currentVisibleShelters.prefix(3), id: \.id) { shelter in
                                Button(action: {
                                    shelterViewModel.selectedShelter = shelter
                                }) {
                                    HStack(spacing: 16) {
                                        // Location icon
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: FONT_SIZE.size * 1.75))
                                            .foregroundColor(Color(.systemGreen))
                                            .frame(width: 40)
                                        
                                        // Shelter information
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(shelter.name)
                                                .font(.system(size: FONT_SIZE.size))
                                                .foregroundColor(.primary)
                                            
                                            if let userLocation = shelterViewModel.userLocation {
                                                let distance = shelterViewModel.fastDistance(
                                                    lat1: userLocation.coordinate.latitude,
                                                    lon1: userLocation.coordinate.longitude,
                                                    lat2: shelter.latitude,
                                                    lon2: shelter.longitude
                                                )
                                                
                                                Text("\(shelter.regionName) ･ \(shelterViewModel.formatDistance(meters: distance))")
                                                    .font(.system(size: FONT_SIZE.size * 0.875))
                                                    .foregroundColor(Color(.systemGray))
                                            } else {
                                                Text(shelter.regionName)
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
                            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                  let window = windowScene.windows.first,
                                  let rootVC = window.rootViewController,
                                  let userLocation = shelterViewModel.userLocation else { return }
                            
                            var topController = rootVC
                            while let presentedVC = topController.presentedViewController {
                                topController = presentedVC
                            }
                            
                            var shareItems: [Any] = []
                            
                            // Format coordinates
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
                            
                            // Present share sheet
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
    }
}
