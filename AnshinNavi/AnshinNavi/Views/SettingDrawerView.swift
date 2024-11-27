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
                    
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        SettingRow(
                            icon: "lock.shield.fill",
                            iconColor: .purple,
                            title: "privacy_policy".localized
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

// PRIVACY_POLICY
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text("Privacy Policy")
                    .font(.system(size: FONT_SIZE.size * 1.4))
                    .fontWeight(.bold)
                
                Text("Last updated: November 27, 2024")
                    .font(.system(size: FONT_SIZE.size * 0.875))
                    .foregroundColor(.gray)
                
                // Introduction
                Text("This Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your information when You use the Service and tells You about Your privacy rights and how the law protects You.")
                    .font(.system(size: FONT_SIZE.size))
                
                Text("We use Your Personal data to provide and improve the Service. By using the Service, You agree to the collection and use of information in accordance with this Privacy Policy.")
                    .font(.system(size: FONT_SIZE.size))
                
                // Interpretation and Definitions
                Group {
                    Text("Interpretation and Definitions")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Interpretation")
                        .font(.system(size: FONT_SIZE.size * 1.1))
                        .fontWeight(.semibold)
                    
                    Text("The words of which the initial letter is capitalized have meanings defined under the following conditions. The following definitions shall have the same meaning regardless of whether they appear in singular or in plural.")
                        .font(.system(size: FONT_SIZE.size))
                    
                    Text("Definitions")
                        .font(.system(size: FONT_SIZE.size * 1.1))
                        .fontWeight(.semibold)
                        .padding(.top)
                }
                
                // Definitions List
                VStack(alignment: .leading, spacing: 12) {
                    definitionItem(term: "Account", definition: "means a unique account created for You to access our Service or parts of our Service.")
                    definitionItem(term: "Application", definition: "refers to 安心ナビ(Japan Safety Map), the software program provided by the Company.")
                    definitionItem(term: "Company", definition: "refers to 安心ナビ(Japan Safety Map).")
                    definitionItem(term: "Country", definition: "refers to: Japan")
                    definitionItem(term: "Device", definition: "means any device that can access the Service such as a computer, a cellphone or a digital tablet.")
                    definitionItem(term: "Personal Data", definition: "is any information that relates to an identified or identifiable individual.")
                    definitionItem(term: "Service", definition: "refers to the Application.")
                }
                
                // Data Collection Section
                Group {
                    Text("Collecting and Using Your Personal Data")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Types of Data Collected")
                        .font(.system(size: FONT_SIZE.size * 1.1))
                        .fontWeight(.semibold)
                    
                    Text("Personal Data")
                        .font(.system(size: FONT_SIZE.size * 1))
                        .fontWeight(.semibold)
                    
                    Text("While using Our Service, We may ask You to provide Us with certain personally identifiable information that can be used to contact or identify You. Personally identifiable information may include, but is not limited to:")
                        .font(.system(size: FONT_SIZE.size))
                    
                    Text("• Usage Data")
                        .font(.system(size: FONT_SIZE.size))
                        .padding(.leading)
                }
                
                // Location Data Section
                Group {
                    Text("Information Collected while Using the Application")
                        .font(.system(size: FONT_SIZE.size * 1.1))
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text("While using Our Application, in order to provide features of Our Application, We may collect, with Your prior permission:")
                        .font(.system(size: FONT_SIZE.size))
                    
                    Text("• Information regarding your location")
                        .font(.system(size: FONT_SIZE.size))
                        .padding(.leading)
                }
                
                // Usage Data Section
                Group {
                    Text("Usage Data")
                        .font(.system(size: FONT_SIZE.size * 1.1))
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text("Usage Data is collected automatically when using the Service.")
                        .font(.system(size: FONT_SIZE.size))
                    
                    Text("Usage Data may include information such as Your Device's Internet Protocol address (e.g. IP address), browser type, browser version, the pages of our Service that You visit, the time and date of Your visit, the time spent on those pages, unique device identifiers and other diagnostic data.")
                        .font(.system(size: FONT_SIZE.size))
                    
                    Text("When You access the Service by or through a mobile device, We may collect certain information automatically, including, but not limited to, the type of mobile device You use, Your mobile device unique ID, the IP address of Your mobile device, Your mobile operating system, the type of mobile Internet browser You use, unique device identifiers and other diagnostic data.")
                        .font(.system(size: FONT_SIZE.size))
                }
                
                // Use of Personal Data Section
                Group {
                    Text("Use of Your Personal Data")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("The Company may use Personal Data for the following purposes:")
                        .font(.system(size: FONT_SIZE.size))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        bulletPoint("To provide and maintain our Service", "including to monitor the usage of our Service.")
                        bulletPoint("To manage Your Account", "to manage Your registration as a user of the Service. The Personal Data You provide can give You access to different functionalities of the Service that are available to You as a registered user.")
                        bulletPoint("For the performance of a contract", "the development, compliance and undertaking of the purchase contract for the products, items or services You have purchased or of any other contract with Us through the Service.")
                        bulletPoint("To contact You", "To contact You by email, telephone calls, SMS, or other equivalent forms of electronic communication, such as a mobile application's push notifications regarding updates or informative communications related to the functionalities, products or contracted services, including the security updates, when necessary or reasonable for their implementation.")
                    }
                }
                
                // Data Sharing Section
                Group {
                    Text("We may share Your personal information in the following situations:")
                        .font(.system(size: FONT_SIZE.size))
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        bulletPoint("With Service Providers", "We may share Your personal information with Service Providers to monitor and analyze the use of our Service, to contact You.")
                        bulletPoint("For business transfers", "We may share or transfer Your personal information in connection with, or during negotiations of, any merger, sale of Company assets, financing, or acquisition of all or a portion of Our business to another company.")
                        bulletPoint("With Affiliates", "We may share Your information with Our affiliates, in which case we will require those affiliates to honor this Privacy Policy.")
                        bulletPoint("With business partners", "We may share Your information with Our business partners to offer You certain products, services or promotions.")
                        bulletPoint("With other users", "when You share personal information or otherwise interact in the public areas with other users, such information may be viewed by all users and may be publicly distributed outside.")
                    }
                }
                
                // Data Retention Section
                Group {
                    Text("Retention of Your Personal Data")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("The Company will retain Your Personal Data only for as long as is necessary for the purposes set out in this Privacy Policy. We will retain and use Your Personal Data to the extent necessary to comply with our legal obligations, resolve disputes, and enforce our legal agreements and policies.")
                        .font(.system(size: FONT_SIZE.size))
                }
                
                // Security Section
                Group {
                    Text("Security of Your Personal Data")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("The security of Your Personal Data is important to Us, but remember that no method of transmission over the Internet, or method of electronic storage is 100% secure. While We strive to use commercially acceptable means to protect Your Personal Data, We cannot guarantee its absolute security.")
                        .font(.system(size: FONT_SIZE.size))
                }
                
                // Children's Privacy Section
                Group {
                    Text("Children's Privacy")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Our Service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from anyone under the age of 13. If You are a parent or guardian and You are aware that Your child has provided Us with Personal Data, please contact Us.")
                        .font(.system(size: FONT_SIZE.size))
                }
                
                // Links to Other Websites Section
                Group {
                    Text("Links to Other Websites")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Our Service may contain links to other websites that are not operated by Us. If You click on a third party link, You will be directed to that third party's site. We strongly advise You to review the Privacy Policy of every site You visit.")
                        .font(.system(size: FONT_SIZE.size))
                }
                
                // Changes to Privacy Policy Section
                Group {
                    Text("Changes to this Privacy Policy")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("We may update Our Privacy Policy from time to time. We will notify You of any changes by posting the new Privacy Policy on this page.")
                        .font(.system(size: FONT_SIZE.size))
                    
                    Text("You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.")
                        .font(.system(size: FONT_SIZE.size))
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
    
    private func definitionItem(term: String, definition: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(term)
                .font(.system(size: FONT_SIZE.size))
                .fontWeight(.semibold)
            Text(definition)
                .font(.system(size: FONT_SIZE.size))
                .foregroundColor(.secondary)
        }
        .padding(.leading)
    }
    
    private func bulletPoint(_ title: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: FONT_SIZE.size))
                .fontWeight(.semibold)
            Text(description)
                .font(.system(size: FONT_SIZE.size))
                .foregroundColor(.secondary)
        }
        .padding(.leading)
    }
}
