import SwiftUI

struct MainBottomDrawerView: View {
    @EnvironmentObject var shelterViewModel: ShelterViewModel
    @Binding var selectedDetent: PresentationDetent
    @Binding var currentAnnotationType: CurrentAnnotationType
    @Binding var selectedShelterFilterTypes: [ShelterFilterType]
    
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

                // <------ ANNOTATION SHELTER ------>
                if currentAnnotationType == .shelter {
                    // Use a single container with conditional content
                    VStack(alignment: .leading, spacing: isSmallDetent ? 8 : 20) {
                        if isSmallDetent {
                            // Small detent content
                            VStack(alignment: .center, spacing: 4) {
                                Text("\(shelterViewModel.visibleShelterCount)件の\(shelterTypeText)が検索されました")
                                    .font(.system(size: dynamicSize(baseSize:20)))
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                
                                if !selectedShelterFilterTypes.isEmpty {
                                    Text(selectedShelterFilterTypes.map { $0.rawValue }.joined(separator: "・"))
                                        .font(.system(size: dynamicSize(baseSize:BASE_FONT_SIZE)))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            // Regular content
                            VStack(spacing: 16) {
                                // Title section
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("指定緊急\(shelterTypeText)")
                                            .font(.system(size: 24, weight: .bold))
                                        Spacer()
                                        Text("\(shelterViewModel.visibleShelterCount)件")
                                            .foregroundColor(.secondary)
                                    }
                                    if !selectedShelterFilterTypes.isEmpty {
                                        Text(selectedShelterFilterTypes.map { $0.rawValue }.joined(separator: "・"))
                                            .font(.system(size: dynamicSize(baseSize:BASE_FONT_SIZE)))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                                            .padding(.horizontal)
                                    }
                                }
                                // Spacer()
                                
                                // Closest shelter card
                                if let userLocation = shelterViewModel.userLocation,
                                   let closestShelter = shelterViewModel.getClosestShelter(
                                    to: userLocation,
                                    matching: selectedShelterFilterTypes
                                   ) {
                                    Button(action: {
                                        shelterViewModel.selectedShelter = closestShelter
                                    }) {
                                        VStack(spacing: 0) {
                                            // Header
                                            HStack {
                                                Image(systemName: "location.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.system(size: 12))
                                                Text("あなたと一番近い\(shelterTypeText)")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.blue)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color(.systemGray6))
                                            
                                            // Shelter info
                                            HStack(alignment: .center, spacing: 12) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.red.opacity(0.1))
                                                        .frame(width: 40, height: 40)
                                                    Image(systemName: "mappin.circle.fill")
                                                        .font(.system(size: 32))
                                                        .foregroundColor(.red)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(closestShelter.name)
                                                        .font(.system(size: 17, weight: .regular))
                                                        .foregroundColor(.primary)
                                                        .lineLimit(1)
                                                    
                                                    Text(closestShelter.regionName)
                                                        .font(.system(size: 15))
                                                        .foregroundColor(Color(.systemGray))
                                                        .lineLimit(1)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(Color(.systemGray3))
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                        }
                                    }
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                }
                            }
                            .padding(.horizontal)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSmallDetent)
                        }
                    }
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
