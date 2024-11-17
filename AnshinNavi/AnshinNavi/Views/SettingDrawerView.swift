import SwiftUI

struct SettingDrawerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with Title and Close Button
                HStack(alignment: .top) {
                    Text("setting")
                        .font(.system(size: 32, weight: .bold))
                    Spacer()
                }
                
                // Setting Options Section
                VStack(spacing: 20) {
                    // Example Setting options
                    ForEach(0..<5) { _ in
                        SettingCard {
                            HStack {
                                Text("Setting Option")
                                    .font(.system(size: 17))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func SettingCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}
