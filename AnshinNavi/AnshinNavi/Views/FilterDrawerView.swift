import SwiftUI

struct FilterDrawerView: View {
    let currentAnnotationType: CurrentAnnotationType
    @Binding var selectedShelterFilterTypes: [ShelterFilterType]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if currentAnnotationType == .shelter {
                    Section(header: Text("災害種別")) {
                        ForEach(ShelterFilterType.allCases, id: \.self) { filterType in
                            FilterToggleRow(
                                filterType: filterType,
                                isSelected: selectedShelterFilterTypes.contains(filterType),
                                onToggle: { isSelected in
                                    handleFilterToggle(filterType: filterType, isSelected: isSelected)
                                }
                            )
                        }
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
    
    private func handleFilterToggle(filterType: ShelterFilterType, isSelected: Bool) {
        if isSelected {
            if !selectedShelterFilterTypes.contains(filterType) {
                selectedShelterFilterTypes.append(filterType)
            }
        } else {
            selectedShelterFilterTypes.removeAll { $0 == filterType }
        }
    }
}

// Extracted toggle row for better reusability and cleaner code
struct FilterToggleRow: View {
    let filterType: ShelterFilterType
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Toggle(filterType.rawValue, isOn: Binding(
            get: { isSelected },
            set: { onToggle($0) }
        ))
    }
}
