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
                            Toggle(filterType.rawValue, isOn: Binding(
                                get: { selectedShelterFilterTypes.contains(filterType) },
                                set: { isSelected in
                                    if isSelected {
                                        if !selectedShelterFilterTypes.contains(filterType) {
                                            selectedShelterFilterTypes.append(filterType)
                                        }
                                    } else {
                                        selectedShelterFilterTypes.removeAll { $0 == filterType }
                                    }
                                    print("Current filters: \(selectedShelterFilterTypes)")
                                }
                            ))
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
}
