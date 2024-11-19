
import SwiftUI

struct MBDAnnotationCardView: View {
    private enum FacilityType {
        case shelter
        case police
        
        var icon: String {
            switch self {
            case .shelter: return "house.fill"
            case .police: return "building.columns.fill"
            }
        }
        
        var title: String {
            switch self {
            case .shelter: return "避難施設"
            case .police: return "警察署"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("表示する施設")
                .font(.system(size: 14))
                .foregroundColor(Color(.systemGray))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    //<-----SHELTER CIRCLE----->
                    VStack(spacing: 6) {
                        Circle()
                            .fill(Color(.systemGreen))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: FacilityType.shelter.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                        Text(FacilityType.shelter.title)
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                    }
                    
                    //<-----POLICE CIRCLE----->
                    VStack(spacing: 6) {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: FacilityType.police.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(.systemGray2))
                            )
                        Text(FacilityType.police.title)
                            .font(.system(size: 12))
                            .foregroundColor(Color(.systemGray))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}
