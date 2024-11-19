//
//  MBDShelterView.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/19.
//

import Foundation
import SwiftUI

struct MBDShelterView: View {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @State private var selectedFacility: FacilityType = .shelter
    let isSmallDetent: Bool
    let selectedShelterFilterTypes: [ShelterFilterType]
    @State private var showingMoreShelters = false
    
    private var shelterTypeText: String {
        if let lastFilter = selectedShelterFilterTypes.last,
           lastFilter == .isSameAsEvacuationCenter {
            return "避難所"
        }
        return "避難場所"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isSmallDetent {
                // Small detent content
                VStack(alignment: .center, spacing: 4) {
                    Text("\(shelterViewModel.visibleShelterCount)件の\(shelterTypeText)が検索されました")
                        .font(.system(size: dynamicSize(baseSize: 20)))
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
            } else {
                // regular content
                VStack(alignment: .leading, spacing: 0) {
                    // Header with count and type
                    HStack {
                        Text("\(shelterViewModel.visibleShelterCount)件の指定\(shelterTypeText)")
                            .font(.system(size: 24, weight: .bold))
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
                                        .font(.system(size: 15))
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
                                .font(.system(size: 14))
                                .foregroundColor(Color(.systemGray))
                                .padding(.horizontal)
                            
                            Button(action: {
                                shelterViewModel.selectedShelter = closestShelter
                            }) {
                                HStack(spacing: 16) {
                                    // Location icon
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(.systemGreen))
                                        .frame(width: 40)
                                    
                                    // Shelter information
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(closestShelter.name)
                                            .font(.system(size: 17))
                                            .foregroundColor(.primary)
                                        
                                        let distance = shelterViewModel.fastDistance(
                                            lat1: userLocation.coordinate.latitude,
                                            lon1: userLocation.coordinate.longitude,
                                            lat2: closestShelter.latitude,
                                            lon2: closestShelter.longitude
                                        )
                                        
                                        Text("\(closestShelter.regionName) ･ \(shelterViewModel.formatDistance(meters: distance))")
                                            .font(.system(size: 14))
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
                    MBDAnnotationCardView()
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Search Results section
                    VStack(alignment: .leading, spacing: 8) {
                        // Header with "View More" button
                        HStack {
                            if shelterViewModel.currentVisibleShelters.count <= 0 {
                                Text("検索結果がありません")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.systemGray))    
                            } else{
                                Text("検索結果")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.systemGray))
                            }
                            
                            Spacer()
                            
                            if shelterViewModel.currentVisibleShelters.count > 3 {
                                Button(action: {
                                    showingMoreShelters = true
                                }) {
                                    Text("もっと見る")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                }
                                .fullScreenCover(isPresented: $showingMoreShelters) {
                                    MBDViewMoreShelters()
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
                                            .font(.system(size: 28))
                                            .foregroundColor(Color(.systemGreen))
                                            .frame(width: 40)
                                        
                                        // Shelter information
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(shelter.name)
                                                .font(.system(size: 17))
                                                .foregroundColor(.primary)
                                            
                                            if let userLocation = shelterViewModel.userLocation {
                                                let distance = shelterViewModel.fastDistance(
                                                    lat1: userLocation.coordinate.latitude,
                                                    lon1: userLocation.coordinate.longitude,
                                                    lat2: shelter.latitude,
                                                    lon2: shelter.longitude
                                                )
                                                
                                                Text("\(shelter.regionName) ･ \(shelterViewModel.formatDistance(meters: distance))")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color(.systemGray))
                                            } else {
                                                Text(shelter.regionName)
                                                    .font(.system(size: 14))
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
                    }
                    
                    Spacer()
                        .frame(height: 24)
                }
            }
        }
    }
}
