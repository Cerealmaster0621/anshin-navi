import Foundation
import CoreLocation

struct PoliceBase: Identifiable, Codable, Equatable {
    let id: String // Unique identifier
    var policeType: PoliceType // Type of police facility (koban, keisatsusho, honbu)
    var name: String // 名称 from honbu, keisatsusho, koban
    var phoneNumber: String // 電話番号 from honbu, keisatsusho, koban
    var furigana: String // フリガナ from keisatsusho, 交番・駐在所頭名（フリガナ） from koban
    var postalCode: String // 郵便番号 from honbu, keisatsusho, koban
    var prefecture: String // 都道府県 from honbu, keisatsusho, 都道府県名 from koban
    var cityTownVillage: String // 市区町村 from honbu, keisatsusho, koban
    var nationalLocalGovernmentCode: String // 全国地方公共団体コード from honbu, keisatsusho, koban
    var fullNotation: String // 全体表記 from honbu, keisatsusho, koban
    var townOrVillageOnwards: String // 町又は大字以降 from honbu, keisatsusho, koban
    var remarks: String // 備考 from honbu, keisatsusho, koban
    var longitude: Double // Longitude from honbu, keisatsusho, koban
    var latitude: Double // Latitude from honbu, keisatsusho, koban
    var isCoordinatesTrustful: Bool // isTrustful from honbu, keisatsusho, koban
    var parent: String? // Parent ID: nil for honbu, honbu ID for keisatsusho, keisatsusho ID for koban

    init(
        id: UUID = UUID(),
        policeType: PoliceType,
        name: String,
        phoneNumber: String,
        furigana: String,
        postalCode: String,
        prefecture: String,
        cityTownVillage: String,
        nationalLocalGovernmentCode: String,
        fullNotation: String,
        townOrVillageOnwards: String,
        remarks: String,
        longitude: Double,
        latitude: Double,
        isCoordinatesTrustful: Bool,
        parent: String? = nil
    ) {
        self.id = id.uuidString
        self.policeType = policeType
        self.name = name
        self.phoneNumber = phoneNumber
        self.furigana = furigana
        self.postalCode = postalCode
        self.prefecture = prefecture
        self.cityTownVillage = cityTownVillage
        self.nationalLocalGovernmentCode = nationalLocalGovernmentCode
        self.fullNotation = fullNotation
        self.townOrVillageOnwards = townOrVillageOnwards
        self.remarks = remarks
        self.longitude = longitude
        self.latitude = latitude
        self.isCoordinatesTrustful = isCoordinatesTrustful
        self.parent = parent
    }
    
    static func == (lhs: PoliceBase, rhs: PoliceBase) -> Bool {
        lhs.id == rhs.id
    }
}

enum PoliceType: String, Codable {
    case koban       // 交番
    case keisatsusho // 警察署
    case honbu       // 本部
    
    var iconName: String {
        switch self {
        case .koban:
            return "building.columns.fill"
        case .keisatsusho:
            return "shield.fill"
        case .honbu:
            return "star.circle.fill"
        }
    }
    
    var localizedName: String {
        switch self {
        case .koban:
            return "koban".localized
        case .keisatsusho:
            return "keisatsusho".localized
        case .honbu:
            return "honbu".localized
        }
    }
}
