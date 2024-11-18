import SwiftUI

struct MainBottomDrawerView: View {
    @Binding var selectedDetent: PresentationDetent
    @Binding var currentAnnotationType: CurrentAnnotationType
    @Binding var selectedShelterFilterTypes: [ShelterFilterType]
    let visibleShelterCount: Int
    
    
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
    
    private var isSmallDetent: Bool {
        selectedDetent == .custom(SmallDetent.self)
    }
    
    private var shelterTypeText: String {
        if let lastFilter = selectedShelterFilterTypes.last,
           lastFilter == .isSameAsEvacuationCenter {
            return "避難所"
        }
        return "避難場所"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Drag indicator
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                if currentAnnotationType == .shelter {
                    // Use a single container with conditional content
                    VStack(alignment: .leading, spacing: isSmallDetent ? 8 : 20) {
                        if isSmallDetent {
                            // Small detent content
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(visibleShelterCount)件の\(shelterTypeText)が検索されました")
                                    .font(.system(size: dynamicSize(baseSize:20)))
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                
                                if !selectedShelterFilterTypes.isEmpty {
                                    Text(selectedShelterFilterTypes.map { $0.rawValue }.joined(separator: "・"))
                                        .font(.system(size: dynamicSize(baseSize:14)))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                        } else {
                            // Regular content
                            HStack {
                                Text("指定緊急\(shelterTypeText)")
                                    .font(.system(size: 24, weight: .bold))
                                Spacer()
                                Text("\(visibleShelterCount)件")
                                    .foregroundColor(.secondary)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            
                            // Your list content here...
                        }
                    }
                    .padding(.horizontal)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSmallDetent)
                }
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
