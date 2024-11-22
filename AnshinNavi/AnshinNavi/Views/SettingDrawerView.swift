import SwiftUI

struct SettingDrawerView: View {
    var body: some View {
        NavigationView {
            List {
                // First Section
                Section {
                    SettingToggleRow(
                        icon: "location.fill",
                        iconBackground: .blue,
                        title: "location_services".localized,
                        isOn: .constant(true)
                    )
                    
                    SettingToggleRow(
                        icon: "bell.fill",
                        iconBackground: .red,
                        title: "notifications".localized,
                        isOn: .constant(false)
                    )
                } header: {
                    Text("general".localized)
                }
                
                // Second Section
                Section {
                    SettingToggleRow(
                        icon: "map.fill",
                        iconBackground: .green,
                        title: "default_map".localized,
                        isOn: .constant(true)
                    )
                    
                    SettingToggleRow(
                        icon: "ruler.fill",
                        iconBackground: .orange,
                        title: "distance_unit".localized,
                        isOn: .constant(true)
                    )
                } header: {
                    Text("map_settings".localized)
                } footer: {
                    Text("map_settings_description".localized)
                }
                
                // Third Section
                Section {
                    SettingLinkRow(
                        icon: "doc.text.fill",
                        iconBackground: .gray,
                        title: "privacy_policy".localized
                    )
                    
                    SettingLinkRow(
                        icon: "info.circle.fill",
                        iconBackground: .gray,
                        title: "about".localized
                    )
                } header: {
                    Text("about".localized)
                }
            }
            .navigationTitle("settings".localized)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Setting Row Views
private struct SettingToggleRow: View {
    let icon: String
    let iconBackground: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconBackground)
                .cornerRadius(6)
            
            Text(title)
                .padding(.leading, 8)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
        }
    }
}

private struct SettingLinkRow: View {
    let icon: String
    let iconBackground: Color
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconBackground)
                .cornerRadius(6)
            
            Text(title)
                .padding(.leading, 8)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .semibold))
        }
    }
}
