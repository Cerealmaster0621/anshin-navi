import SwiftUI

struct FilterDrawerView: View {
    let currentAnnotationType: CurrentAnnotationType
    @Binding var selectedShelterFilterTypes: [ShelterFilterType]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            switch currentAnnotationType {
                case .shelter:
                    FilterShelterView(selectedShelterFilterTypes: $selectedShelterFilterTypes)
                case .police:
                    EmptyView()
                case .none:
                    EmptyView()
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
