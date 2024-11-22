import Foundation
import SwiftUI

struct FilterShelterView: View {
    @Binding var selectedShelterFilterTypes: [ShelterFilterType]
    
    var body: some View {
        List {
            // Reset button section
            Section {
                Button(action: {
                    selectedShelterFilterTypes.removeAll()
                }) {
                    Text("フィルターをリセット")
                        .foregroundColor(.blue)
                }
                .disabled(selectedShelterFilterTypes.isEmpty)
            }
            
            // First section for disaster types
            Section(header: Text("災害種別")) {
                ForEach(ShelterFilterType.allCases.filter { $0 != .isSameAsEvacuationCenter }, id: \.self) { filterType in
                    FilterToggleRowShelter(
                        filterType: filterType,
                        isSelected: selectedShelterFilterTypes.contains(filterType),
                        onToggle: { isSelected in
                            handleShelterFilterToggle(filterType: filterType, isSelected: isSelected)
                        }
                    )
                }
            }
            
            // Second section for evacuation center
            Section(footer: Text(WHAT_IS_SHELTER_FILTER)
                .font(.footnote)
                .padding(.top, 2)
                .foregroundColor(.secondary)) {
                FilterToggleRow(
                    filterType: .isSameAsEvacuationCenter,
                    isSelected: selectedShelterFilterTypes.contains(.isSameAsEvacuationCenter),
                    onToggle: { isSelected in
                        handleShelterFilterToggle(filterType: .isSameAsEvacuationCenter, isSelected: isSelected)
                    }
                )
            }
        }
    }
    
    private func handleShelterFilterToggle(filterType: ShelterFilterType, isSelected: Bool) {
        if isSelected {
            if !selectedShelterFilterTypes.contains(filterType) {
                selectedShelterFilterTypes.append(filterType)
            }
        } else {
            selectedShelterFilterTypes.removeAll { $0 == filterType }
        }
    }
}

private struct FilterToggleRowShelter: View {
    let filterType: ShelterFilterType
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack(spacing: 12) {
                Image(systemName: filterType.iconName)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(filterType.localizedName)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .frame(width: 24)
            }
        }
    }
}
