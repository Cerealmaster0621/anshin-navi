import SwiftUI

struct SettingDrawerView: View {
    @State private var selectedMapType: MapType = UserDefaults.standard.string(forKey: "MapType").flatMap { MapType(rawValue: $0) } ?? MAP_TYPE
    @State private var fontSize: FontSize = UserDefaults.standard.string(forKey: "FontSize").flatMap { FontSize(rawValue: $0) } ?? FONT_SIZE
    @State private var defaultAnnotationType: CurrentAnnotationType = {
        if let savedValue = UserDefaults.standard.object(forKey: "DefaultAnnotationType") as? Int,
           let annotationType = CurrentAnnotationType(rawValue: savedValue) {
            return annotationType
        }
        return ANNOTATION_TYPE
    }()
    @State private var maxAnnotations: Double = {
        let savedValue = UserDefaults.standard.integer(forKey: "MaxAnnotations")
        return savedValue > 0 ? Double(savedValue) : Double(MAX_ANNOTATIONS)
    }()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Map Settings Section
                Section(header: Text("map_settings".localized)
                    .font(.system(size: FONT_SIZE.size * 0.875))) {
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
                        .onChange(of: maxAnnotations) { newValue in
                            MAX_ANNOTATIONS = Int(newValue)
                            NotificationCenter.default.post(
                                name: Notification.Name("search_region_notification".localized),
                                object: nil
                            )
                        }
                    }
                    
                    NavigationLink {
                        DefaultAnnotationSelectionView(selection: $defaultAnnotationType)
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
                Section(header: Text("accessibility".localized)
                    .font(.system(size: FONT_SIZE.size * 0.875))) {
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
                Section(header: Text("safety_guides".localized)
                    .font(.system(size: FONT_SIZE.size * 0.875))) {
                    Button(action: {
                        if let url = URL(string: "https://www.maff.go.jp/j/pr/aff/1909/spe1_03.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        SettingRow(
                            icon: "questionmark.circle.fill",
                            iconColor: .blue,
                            title: "disaster_response".localized
                        )
                    }
                }
                
                // About Section
                Section(header: Text("about".localized)
                    .font(.system(size: FONT_SIZE.size * 0.875))) {
                    NavigationLink {
                        DataSourcesView()
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
            .font(.system(size: FONT_SIZE.size * 1.25))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .font(.system(size: FONT_SIZE.size))
                }
            }
            .onChange(of: selectedMapType) { newValue in
                // Update global constant
                MAP_TYPE = newValue
                // Save to UserDefaults
                UserDefaults.standard.set(newValue.rawValue, forKey: "MapType")
                // Post notification to update map immediately
                NotificationCenter.default.post(
                    name: Notification.Name("settings_updated"),
                    object: nil,
                    userInfo: ["mapType": newValue]
                )
            }
        }
        .presentationDetents(SETTING_DETENTS)
        .onDisappear {
            saveSettings()
        }
    }
    
    private func saveSettings() {
        // Save all settings to UserDefaults
        UserDefaults.standard.set(selectedMapType.rawValue, forKey: "MapType")
        UserDefaults.standard.set(fontSize.rawValue, forKey: "FontSize")
        UserDefaults.standard.set(defaultAnnotationType.rawValue, forKey: "DefaultAnnotationType")
        UserDefaults.standard.set(Int(maxAnnotations), forKey: "MaxAnnotations")
        
        // Update global constants
        MAX_ANNOTATIONS = Int(maxAnnotations)
        ANNOTATION_TYPE = defaultAnnotationType
        MAP_TYPE = selectedMapType
        FONT_SIZE = fontSize
        
        // Synchronize UserDefaults to ensure changes are saved immediately
        UserDefaults.standard.synchronize()
        
        // Post notification for map to update
        NotificationCenter.default.post(
            name: Notification.Name("settings_updated"),
            object: nil,
            userInfo: [
                "maxAnnotations": Int(maxAnnotations),
                "defaultAnnotationType": defaultAnnotationType,
                "mapType": selectedMapType,
                "fontSize": fontSize
            ]
        )
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
                .font(.system(size: FONT_SIZE.size))
                .padding(.leading, 8)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.system(size: FONT_SIZE.size))
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
            Section {
                ForEach(MapType.allCases) { type in
                    SelectionRow(
                        title: type.name,
                        isSelected: type == selection
                    ) {
                        selection = type
                    }
                }
            } footer: {
                Text("map_type_explanation".localized)
                    .font(.system(size: FONT_SIZE.size * 0.875))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
        .navigationTitle("map_type".localized)
        .font(.system(size: FONT_SIZE.size * 1.25))
    }
}

struct FontSizeSelectionView: View {
    @Binding var selection: FontSize
    
    var body: some View {
        List {
            Section {
                ForEach(FontSize.allCases) { size in
                    SelectionRow(
                        title: size.name,
                        isSelected: size == selection
                    ) {
                        selection = size
                    }
                }
            } footer: {
                Text("font_size_explanation".localized)
                    .font(.system(size: FONT_SIZE.size * 0.875))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
        .navigationTitle("font_size".localized)
        .font(.system(size: FONT_SIZE.size * 1.25))
    }
}

struct DefaultAnnotationSelectionView: View {
    @Binding var selection: CurrentAnnotationType
    
    var body: some View {
        List {
            Section {
                ForEach(CurrentAnnotationType.allCases.filter { $0 != .none }, id: \.self) { type in
                    SelectionRow(
                        title: type.name,
                        isSelected: type == selection
                    ) {
                        selection = type
                    }
                }
            } footer: {
                Text("default_annotation_explanation".localized)
                    .font(.system(size: FONT_SIZE.size * 0.875))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
        .navigationTitle("default_annotation".localized)
        .font(.system(size: FONT_SIZE.size * 1.25))
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
                    .font(.system(size: FONT_SIZE.size))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: FONT_SIZE.size))
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct DataSourcesView: View {
    var body: some View {
        List {
            Section(header: Text("shelter_data_source".localized)
                .font(.system(size: FONT_SIZE.size * 0.875))) {
                Link("国土地理院", destination: URL(string: "https://www.gsi.go.jp/top.html")!)
                    .font(.system(size: FONT_SIZE.size))
                    .foregroundColor(.blue)
            }
            
            Section(header: Text("police_data_source".localized)
                .font(.system(size: FONT_SIZE.size * 0.875))) {
                Link("警察庁", destination: URL(string: "https://www.npa.go.jp/index.html")!)
                    .font(.system(size: FONT_SIZE.size))
                    .foregroundColor(.blue)
            }
        }
        .navigationTitle("data_sources".localized)
        .font(.system(size: FONT_SIZE.size * 1.25))
    }
}
