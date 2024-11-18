import SwiftUI

struct FilterDrawerView: View {
    let currentAnnotationType: CurrentAnnotationType
    @Binding var selectedShelterFilterTypes: [ShelterFilterType]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if currentAnnotationType == .shelter {
                    // First section for disaster types
                    Section(header: Text("災害種別")) {
                        ForEach(ShelterFilterType.allCases.filter { $0 != .isSameAsEvacuationCenter }, id: \.self) { filterType in
                            FilterToggleRow(
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
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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

struct FilterToggleRow: View {
    let filterType: ShelterFilterType
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { isSelected },
            set: { onToggle($0) }
        )) {
            HStack(spacing: 12) {
                Image(systemName: filterType.iconName)
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .frame(width: 24, alignment: .center)
                
                Text(filterType.rawValue)
                    .font(.system(size: 15))
            }
        }
    }
}
