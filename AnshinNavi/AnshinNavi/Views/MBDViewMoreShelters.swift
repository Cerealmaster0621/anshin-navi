import SwiftUI

struct MBDViewMoreShelters: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @State private var searchText = ""
    @State private var localShelters: [Shelter]
    @State private var isFilterExpanded = false
    @State private var selectedFilters: Set<ShelterFilterType>

    
    private let horizontalPadding: CGFloat = 16
    private let verticalSpacing: CGFloat = 24
    
    init(selectedFilterTypes: [ShelterFilterType]) {
        _localShelters = State(initialValue: [])
        _selectedFilters = State(initialValue: Set(selectedFilterTypes))
    }
    
    private var shelterTypeText: String {
        if selectedFilters.contains(.isSameAsEvacuationCenter) {
            return "避難所"
        }
        return "避難場所"
    }
    
    private var filteredShelters: [Shelter] {
        // First filter by selected filter types
        let sheltersFilteredByType = selectedFilters.isEmpty ? localShelters : localShelters.filter { shelter in
            selectedFilters.allSatisfy { filterType in
                filterType.matches(shelter)
            }
        }
        
        // Then filter by search text
        if searchText.isEmpty {
            return sheltersFilteredByType
        } else {
            return shelterViewModel.searchShelters(sheltersFilteredByType, keyword: searchText)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header section
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center) {
                        Text("\(shelterTypeText)一覧")
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
                                TextField("\(shelterTypeText)を検索", text: $searchText)
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
                            .background(Color(.systemGray5)) // Darker background
                            .cornerRadius(10)
                        }
                        
                        Text("\(filteredShelters.count)件の検索結果")
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
                            
                            // Filter count indicator
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
                                // Reset local shelters to original state
                                localShelters = shelterViewModel.currentVisibleShelters
                            }) {
                                Text("フィルターをリセット")
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 8)
                            
                            // Filter type section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("災害種別")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                ForEach(ShelterFilterType.allCases.filter { $0 != .isSameAsEvacuationCenter }, id: \.self) { filterType in
                                    Button(action: {
                                        if selectedFilters.contains(filterType) {
                                            selectedFilters.remove(filterType)
                                        } else {
                                            selectedFilters.insert(filterType)
                                        }
                                        // Update local shelters based on new filters
                                        localShelters = shelterViewModel.currentVisibleShelters.filter { shelter in
                                            selectedFilters.isEmpty || selectedFilters.allSatisfy { filterType in
                                                filterType.matches(shelter)
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: filterType.iconName)
                                                .foregroundColor(.blue)
                                                .frame(width: 24)
                                            Text(filterType.rawValue)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "checkmark")
                                                .foregroundColor(selectedFilters.contains(filterType) ? .blue : .clear)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            
                            Divider()
                            
                            // Evacuation center toggle
                            Button(action: {
                                let evacuationCenter = ShelterFilterType.isSameAsEvacuationCenter
                                if selectedFilters.contains(evacuationCenter) {
                                    selectedFilters.remove(evacuationCenter)
                                } else {
                                    selectedFilters.insert(evacuationCenter)
                                }
                                // Update local shelters based on new filters
                                localShelters = shelterViewModel.currentVisibleShelters.filter { shelter in
                                    selectedFilters.isEmpty || selectedFilters.allSatisfy { filterType in
                                        filterType.matches(shelter)
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: ShelterFilterType.isSameAsEvacuationCenter.iconName)
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    Text(ShelterFilterType.isSameAsEvacuationCenter.rawValue)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(selectedFilters.contains(.isSameAsEvacuationCenter) ? .blue : .clear)
                                }
                            }
                            .padding(.vertical, 8)
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
                
                // Shelter list
                LazyVStack(spacing: 12) {
                    ForEach(filteredShelters) { shelter in
                        Button(action: {
                            shelterViewModel.selectedShelter = shelter
                            dismiss()
                        }) {
                            HStack(spacing: 16) {
                                // Location icon with background
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(Color(.systemGreen))
                                }
                                
                                // Shelter information
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(shelter.name)
                                        .font(.system(size: 17))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    HStack(spacing: 4) {
                                        Text(shelter.regionName)
                                        
                                        if let userLocation = shelterViewModel.userLocation {
                                            Text("･")
                                            Text(shelterViewModel.formatDistance(meters: shelterViewModel.fastDistance(
                                                lat1: userLocation.coordinate.latitude,
                                                lon1: userLocation.coordinate.longitude,
                                                lat2: shelter.latitude,
                                                lon2: shelter.longitude
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
            localShelters = shelterViewModel.currentVisibleShelters
        }
    }
}
