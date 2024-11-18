import Foundation
import CoreLocation

struct Shelter: Identifiable, Codable, Equatable {
    let id: String
    var regionCode: String
    var regionName: String
    var number: String
    var name: String
    var address: String
    var generalFlooding: Bool
    var landslide: Bool
    var highTide: Bool
    var earthquake: Bool
    var tsunami: Bool
    var fire: Bool
    var internalFlooding: Bool
    var volcano: Bool
    var isSameAsEvacuationCenter: Bool
    var latitude: Double
    var longitude: Double
    var additionalInfo: String
    
    init(
        id: UUID = UUID(),
        regionCode: String,
        regionName: String,
        number: String,
        name: String,
        address: String,
        generalFlooding: Bool,
        landslide: Bool,
        highTide: Bool,
        earthquake: Bool,
        tsunami: Bool,
        fire: Bool,
        internalFlooding: Bool,
        volcano: Bool,
        isSameAsEvacuationCenter: Bool,
        latitude: Double,
        longitude: Double,
        additionalInfo: String
    ) {
        self.id = id.uuidString
        self.regionCode = regionCode
        self.regionName = regionName
        self.number = number
        self.name = name
        self.address = address
        self.generalFlooding = generalFlooding
        self.landslide = landslide
        self.highTide = highTide
        self.earthquake = earthquake
        self.tsunami = tsunami
        self.fire = fire
        self.internalFlooding = internalFlooding
        self.volcano = volcano
        self.isSameAsEvacuationCenter = isSameAsEvacuationCenter
        self.latitude = latitude
        self.longitude = longitude
        self.additionalInfo = additionalInfo
    }
    
    static func == (lhs: Shelter, rhs: Shelter) -> Bool {
        lhs.id == rhs.id
    }
    
    var trueSafetyFeatures: [ShelterFilterType] {
        ShelterFilterType.allCases.filter { filterType in
            filterType.matches(self)
        }
    }
}

enum ShelterFilterType: String, CaseIterable {
    case generalFlooding = "洪水"
    case landslide = "土砂崩れ"
    case highTide = "高潮"
    case earthquake = "地震"
    case tsunami = "津波"
    case fire = "大規模な火事"
    case internalFlooding = "内水氾濫"
    case volcano = "火山"
    case isSameAsEvacuationCenter = "指定避難所"
    
    var iconName: String {
        switch self {
        case .generalFlooding: return "drop.fill"
        case .landslide: return "triangle.fill"
        case .highTide: return "water.waves.and.arrow.up"
        case .earthquake: return "waveform.path.ecg.rectangle"
        case .tsunami: return "water.waves"
        case .fire: return "flame.fill"
        case .internalFlooding: return "drop.triangle.fill"
        case .volcano: return "mountain.2.fill"
        case .isSameAsEvacuationCenter: return "person.3.fill"
        }
    }
    
    func matches(_ shelter: Shelter) -> Bool {
        switch self {
        case .generalFlooding: return shelter.generalFlooding
        case .landslide: return shelter.landslide
        case .highTide: return shelter.highTide
        case .earthquake: return shelter.earthquake
        case .tsunami: return shelter.tsunami
        case .fire: return shelter.fire
        case .internalFlooding: return shelter.internalFlooding
        case .volcano: return shelter.volcano
        case .isSameAsEvacuationCenter: return shelter.isSameAsEvacuationCenter
        }
    }
}