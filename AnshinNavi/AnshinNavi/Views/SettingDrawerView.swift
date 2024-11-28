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
                Text("プライバシーポリシー")
                    .font(.system(size: FONT_SIZE.size * 1.4))
                    .fontWeight(.bold)
                
                Text("最終更新日: 2024年11月27日")
                    .font(.system(size: FONT_SIZE.size * 0.875))
                    .foregroundColor(.gray)
                
                // Introduction
                Text("本プライバシーポリシーは、当社のサービスご利用時における個人情報の収集、使用、開示に関する方針を説明し、お客様のプライバシー権利と法的保護についてご案内するものです。")
                    .font(.system(size: FONT_SIZE.size))
                
                Text("当社は、サービスの提供および改善のためにお客様の個人情報を使用いたします。本サービスをご利用いただくことで、本プライバシーポリシーに従った情報の収集および使用にご同意いただいたものとみなされます。")
                    .font(.system(size: FONT_SIZE.size))
                
                // Interpretation and Definitions
                Group {
                    Text("解釈および定義")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("解釈")
                        .font(.system(size: FONT_SIZE.size * 1.1))
                        .fontWeight(.semibold)
                    
                    Text("大文字で始まる用語は、以下に定める意味を持ちます。以下の定義は、単数形でも複数形でも同じ意味を持つものとします。")
                        .font(.system(size: FONT_SIZE.size))
                    
                    Text("定義")
                        .font(.system(size: FONT_SIZE.size * 1.1))
                        .fontWeight(.semibold)
                        .padding(.top)
                }
                
                // Definitions List
                VStack(alignment: .leading, spacing: 12) {
                    definitionItem(term: "アカウント", definition: "当社のサービスまたはその一部にアクセスするために作成された固有のアカウントを指します。")
                    definitionItem(term: "アプリケーション", definition: "安心ナビ(Japan Safety Map)を指し、当社が提供するソフトウェアプログラムです。")
                    definitionItem(term: "会社", definition: "安心ナビ(Japan Safety Map)を指します。")
                    definitionItem(term: "国", definition: "日本を指します。")
                    definitionItem(term: "デバイス", definition: "コンピュータ、携帯電話、タブレットなど、サービスにアクセスできる機器を指します。")
                    definitionItem(term: "個人情報", definition: "特定の個人を識別できる、または識別可能な個人に関する情報を指します。")
                    definitionItem(term: "サービス", definition: "本アプリケーションを指します。")
                }
                
                // Data Collection Section
                Group {
                    Text("個人情報の収集および使用")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("収集する情報の種類")
                        .font(.system(size: FONT_SIZE.size * 1.1))
                        .fontWeight(.semibold)
                    
                    Text("個人情報")
                        .font(.system(size: FONT_SIZE.size * 1))
                        .fontWeight(.semibold)
                    
                    Text("当社のサービスをご利用いただく際、お客様を識別または連絡可能な個人情報の提供をお願いする場合があります。収集する個人情報には以下が含まれますが、これらに限定されません：")
                        .font(.system(size: FONT_SIZE.size))
                    
                    Text("• 利用データ")
                        .font(.system(size: FONT_SIZE.size))
                        .padding(.leading)
                }
                
                // Location Data Section
                Group {
                    Text("アプリケーション使用時に収集される情報")
                        .font(.system(size: FONT_SIZE.size * 1.1))
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text("当社のアプリケーションの機能を提供するため、お客様の事前の許可を得た上で、以下の情報を収集する場合があります：")
                        .font(.system(size: FONT_SIZE.size))
                    
                    Text("• 位置情報")
                        .font(.system(size: FONT_SIZE.size))
                        .padding(.leading)
                }
                
                // Usage Data Section
                Group {
                    Text("利用データ")
                        .font(.system(size: FONT_SIZE.size * 1.1))
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text("利用データは、サービスの使用時に自動的に収集されます。")
                        .font(.system(size: FONT_SIZE.size))
                    
                    Text("利用データには、お客様のデバイスのIPアドレス、ブラウザの種類、ブラウザのバージョン、閲覧したページ、閲覧日時、滞在時間、固有のデバイス識別子、その他の診断データなどが含まれる場合があります。")
                        .font(.system(size: FONT_SIZE.size))
                }
                
                // Security Section
                Group {
                    Text("個人情報のセキュリティ")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("お客様の個人情報の安全性は当社にとって重要ですが、インターネットを介した送信方法や電子的保存方法に100%の安全性を保証することはできません。当社は商業的に適切な手段を用いてお客様の個人情報を保護するよう努めておりますが、絶対的な安全性を保証することはできません。")
                        .font(.system(size: FONT_SIZE.size))
                }
                
                // Children's Privacy Section
                Group {
                    Text("お子様のプライバシー")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("当社のサービスは13歳未満のお子様を対象としていません。13歳未満のお子様から意図的に個人情報を収集することはありません。保護者の方で、お子様が当社に個人情報を提供したことにお気づきの場合は、当社までご連絡ください。")
                        .font(.system(size: FONT_SIZE.size))
                }
                
                // Changes to Privacy Policy Section
                Group {
                    Text("プライバシーポリシーの変更")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("当社は、必要に応じて本プライバシーポリシーを更新することがあります。変更があった場合は、このページに新しいプライバシーポリシーを掲載いたします。")
                        .font(.system(size: FONT_SIZE.size))
                    
                    Text("定期的に本ページをご確認いただき、変更点をご確認ください。プライバシーポリシーの変更は、このページに掲載された時点で有効となります。")
                        .font(.system(size: FONT_SIZE.size))
                }
                
                // Contact Section
                Group {
                    Text("お問い合わせ")
                        .font(.system(size: FONT_SIZE.size * 1.2))
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("本プライバシーポリシーに関するご質問がございましたら、お気軽にお問い合わせください。")
                        .font(.system(size: FONT_SIZE.size))
                }
            }
            .padding()
        }
        .navigationTitle("プライバシーポリシー")
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
}
