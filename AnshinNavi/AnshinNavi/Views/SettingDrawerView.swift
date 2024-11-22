import SwiftUI

struct SettingDrawerView: View {
    @State private var selectedMapType: MapType = DEFAULT_MAP_TYPE
    @State private var maxAnnotations: Double = DEFAULT_MAX_ANNOTATIONS
    @State private var defaultAnnotationType: AnnotationType = DEFAULT_ANNOTATION_TYPE
    @State private var fontSize: FontSize = DEFAULT_FONT_SIZE
    
    var body: some View {
        NavigationView {
            List {
                // Map Settings Section
                Section(header: Text("map_settings".localized)) {
                    NavigationLink {
                        MapTypeSelectionView(selection: $selectedMapType)
                    } label: {
                        SettingRow(
                            icon: SETTING_ICONS["map"]!,
                            iconColor: SETTING_COLORS["map"]!,
                            title: "map_type".localized,
                            value: selectedMapType.name
                        )
                    }
                    
                    VStack(alignment: .leading) {
                        SettingRow(
                            icon: SETTING_ICONS["annotation"]!,
                            iconColor: SETTING_COLORS["annotation"]!,
                            title: "max_annotations".localized,
                            value: "\(Int(maxAnnotations))"
                        )
                        Slider(
                            value: $maxAnnotations,
                            in: MAX_ANNOTATION_RANGE,
                            step: ANNOTATION_STEP
                        )
                    }
                    
                    NavigationLink {
                        DefaultAnnotationView(selection: $defaultAnnotationType)
                    } label: {
                        SettingRow(
                            icon: SETTING_ICONS["defaultAnnotation"]!,
                            iconColor: SETTING_COLORS["defaultAnnotation"]!,
                            title: "default_annotation".localized,
                            value: defaultAnnotationType.name
                        )
                    }
                }
                
                // Accessibility Section
                Section(header: Text("accessibility".localized)) {
                    NavigationLink {
                        FontSizeSelectionView(selection: $fontSize)
                    } label: {
                        SettingRow(
                            icon: SETTING_ICONS["fontSize"]!,
                            iconColor: SETTING_COLORS["fontSize"]!,
                            title: "font_size".localized,
                            value: fontSize.name
                        )
                    }
                }
                
                // Safety Guides Section
                Section(header: Text("safety_guides".localized)) {
                    NavigationLink {
//                        SafetyGuideView(type: .tsunami)
                    } label: {
                        SettingRow(
                            icon: SETTING_ICONS["tsunami"]!,
                            iconColor: SETTING_COLORS["tsunami"]!,
                            title: "tsunami_guide".localized
                        )
                    }
                    
                    NavigationLink {
//                        SafetyGuideView(type: .earthquake)
                    } label: {
                        SettingRow(
                            icon: SETTING_ICONS["earthquake"]!,
                            iconColor: SETTING_COLORS["earthquake"]!,
                            title: "earthquake_guide".localized
                        )
                    }
                    
                    NavigationLink {
//                        SafetyGuideView(type: .fire)
                    } label: {
                        SettingRow(
                            icon: SETTING_ICONS["fire"]!,
                            iconColor: SETTING_COLORS["fire"]!,
                            title: "fire_guide".localized
                        )
                    }
                }
                
                // About Section
                Section(header: Text("about".localized)) {
                    NavigationLink {
//                        DataSourcesView()
                    } label: {
                        SettingRow(
                            icon: SETTING_ICONS["dataSources"]!,
                            iconColor: SETTING_COLORS["dataSources"]!,
                            title: "data_sources".localized
                        )
                    }
                }
            }
            .navigationTitle("settings".localized)
        }
        .presentationDetents(SETTING_DETENTS)
    }
}

// Helper View for consistent setting row styling
private struct SettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var value: String? = nil
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .cornerRadius(6)
            
            Text(title)
                .padding(.leading, 8)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .foregroundColor(.gray)
            }
        }
    }
}

// Selection Views remain the same but with updated styling
struct MapTypeSelectionView: View {
    @Binding var selection: MapType
    
    var body: some View {
        List {
            ForEach(MapType.allCases) { type in
                SelectionRow(
                    title: type.name,
                    isSelected: type == selection
                ) {
                    selection = type
                }
            }
        }
        .navigationTitle("map_type".localized)
    }
}

struct DefaultAnnotationView: View {
    @Binding var selection: AnnotationType
    
    var body: some View {
        List {
            ForEach(AnnotationType.allCases) { type in
                SelectionRow(
                    title: type.name,
                    isSelected: type == selection
                ) {
                    selection = type
                }
            }
        }
        .navigationTitle("default_annotation".localized)
    }
}

struct FontSizeSelectionView: View {
    @Binding var selection: FontSize
    
    var body: some View {
        List {
            ForEach(FontSize.allCases) { size in
                SelectionRow(
                    title: size.name,
                    isSelected: size == selection
                ) {
                    selection = size
                }
            }
        }
        .navigationTitle("font_size".localized)
    }
}

// Helper View for consistent selection row styling
private struct SelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}
