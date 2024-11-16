import SwiftUI

struct MainBottomDrawerView: View {
    @Binding var selectedDetent: PresentationDetent
    
    // Custom detent for 10% height
    struct SmallDetent: CustomPresentationDetent {
        static func height(in context: Context) -> CGFloat? {
            return UIScreen.main.bounds.height * SMALL_DENT_WEIGHT
        }
    }
    
    // Custom detent for 40% height
    struct MediumDetent: CustomPresentationDetent {
        static func height(in context: Context) -> CGFloat? {
            return UIScreen.main.bounds.height * MEDIUM_DENT_WEIGHT
        }
    }
    
    // Get the current height based on the detent
    static func getCurrentHeight(for detent: PresentationDetent) -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        
        switch detent {
        case .custom(SmallDetent.self):
            return screenHeight * SMALL_DENT_WEIGHT
        case .custom(MediumDetent.self):
            return screenHeight * MEDIUM_DENT_WEIGHT
        case .large:
            return screenHeight
        default:
            return screenHeight * SMALL_DENT_WEIGHT
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Drag indicator
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                
                // Content goes here
                VStack(alignment: .leading, spacing: 20) {
                    Text("避難場所")
                        .font(.system(size: 24, weight: .bold))
                    
                    // Add your list or other content here
                    ForEach(0..<10) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 80)
                            .overlay(
                                Text("Content \(index + 1)")
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                .padding(.horizontal)
            }
        }
        .presentationDetents(
            [.custom(SmallDetent.self), .custom(MediumDetent.self), .large],
            selection: $selectedDetent
        )
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .interactiveDismissDisabled(true)
    }
}
