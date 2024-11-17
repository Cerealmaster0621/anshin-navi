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
}
