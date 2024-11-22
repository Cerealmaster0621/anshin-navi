import Foundation
import SwiftUI

struct MBDViewMorePolices: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var policeViewModel: PoliceViewModel
    @State private var searchText = ""
    @State private var localPolices: [PoliceBase]
    @State private var isFilterExpanded = false
    @State private var selectedFilters: Set<PoliceType>
    
    private let horizontalPadding: CGFloat = 16
    private let verticalSpacing: CGFloat = 24
    
    init(selectedPoliceTypes: [PoliceType]) {
        _localPolices = State(initialValue: [])
        _selectedFilters = State(initialValue: Set(selectedPoliceTypes))
    }
    
    private var policeTypeText: String {
        "police_facility_lowercase".localized
    }
    
    private var filteredPolices: [PoliceBase] {
        // First filter by selected filter types
        let policesFilteredByType = selectedFilters.isEmpty ? localPolices : localPolices.filter { police in
            selectedFilters.contains(police.policeType)
        }
        
        // Then filter by search text
        if searchText.isEmpty {
            return policesFilteredByType
        } else {
            return policeViewModel.searchPoliceStations(policesFilteredByType, keyword: searchText)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header section
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center) {
                        Text("\(policeTypeText)一覧")
                            .font(.system(size: 28, weight: .bold))
                        Spacer()
                        Button(action: { 
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Search bar with darker background
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                TextField("\(policeTypeText)を検索", text: $searchText)
                                    .font(.system(size: 17))
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                        }
                        
                        Text("\(filteredPolices.count)件の検索結果")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, verticalSpacing)
                
                // Filter section with drawer
                VStack(spacing: 0) {
                    // Filter button with count indicator
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isFilterExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .font(.system(size: 20))
                            Text("絞り込み")
                                .font(.system(size: 17))
                            Spacer()
                            
                            if !selectedFilters.isEmpty {
                                Text("\(selectedFilters.count)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                                    .padding(.trailing, 8)
                            }
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isFilterExpanded ? 180 : 0))
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .padding(.horizontal, horizontalPadding)
                    }
                    
                    // Filter drawer
                    if isFilterExpanded {
                        VStack(alignment: .leading, spacing: 16) {
                            // Reset button
                            Button(action: {
                                selectedFilters.removeAll()
                                localPolices = policeViewModel.currentUnfilteredPoliceStations
                            }) {
                                Text("フィルターをリセット")
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 8)
                            
                            // Filter type section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("施設種別")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                ForEach([PoliceType.honbu, .keisatsusho, .koban], id: \.self) { policeType in
                                    Button(action: {
                                        if selectedFilters.contains(policeType) {
                                            selectedFilters.remove(policeType)
                                        } else {
                                            selectedFilters.insert(policeType)
                                        }
                                        localPolices = policeViewModel.currentUnfilteredPoliceStations.filter { police in
                                            selectedFilters.isEmpty || selectedFilters.contains(police.policeType)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: policeType.iconName)
                                                .foregroundColor(.blue)
                                                .frame(width: 24)
                                            Text(policeType.localizedName)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "checkmark")
                                                .foregroundColor(selectedFilters.contains(policeType) ? .blue : .clear)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 1)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.bottom, verticalSpacing)
                
                // Police list
                LazyVStack(spacing: 12) {
                    ForEach(filteredPolices) { police in
                        Button(action: {
                            policeViewModel.selectedPoliceStation = police
                            dismiss()
                        }) {
                            HStack(spacing: 16) {
                                // Location icon with background
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: police.policeType.iconName)
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
                                }
                                
                                // Police information
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(police.name)
                                        .font(.system(size: 17))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    HStack(spacing: 4) {
                                        Text(police.prefecture)
                                        
                                        if let userLocation = policeViewModel.userLocation {
                                            Text("･")
                                            Text(policeViewModel.formatDistance(meters: policeViewModel.fastDistance(
                                                lat1: userLocation.coordinate.latitude,
                                                lon1: userLocation.coordinate.longitude,
                                                lat2: police.latitude,
                                                lon2: police.longitude
                                            )))
                                        }
                                    }
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                            .padding(.horizontal, horizontalPadding)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            localPolices = policeViewModel.currentUnfilteredPoliceStations
        }
    }
}

