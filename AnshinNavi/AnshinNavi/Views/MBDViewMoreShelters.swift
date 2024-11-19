import SwiftUI

struct MBDViewMoreShelters: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @State private var showingFilters = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // Header section
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center) {
                        Text("避難所一覧")
                            .font(.system(size: 28, weight: .bold))
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color(.systemGray4))
                        }
                    }
                    
                    Text("\(shelterViewModel.visibleShelterCount)件の検索結果")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Filter section (placeholder)
                Button(action: {
                    showingFilters.toggle()
                }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 20))
                        Text("絞り込み")
                            .font(.system(size: 17))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                }
                .padding(.top, 16)
                
                // Shelter list
                LazyVStack(spacing: 1) {
                    ForEach(shelterViewModel.currentVisibleShelters) { shelter in
                        Button(action: {
                            shelterViewModel.selectedShelter = shelter
                            dismiss()
                        }) {
                            HStack(spacing: 16) {
                                // Location icon with background
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
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
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    MBDViewMoreShelters()
        .environmentObject(ShelterViewModel())
}