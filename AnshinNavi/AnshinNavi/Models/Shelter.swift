//
//  Shelter.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/14.
//

import Foundation
import SwiftData
import CoreLocation

struct Shelter: Codable, Identifiable {
    var id: UUID = UUID()
    var regionCode: String
    var regionName: String
    var number: String
    var name: String
    var generalFlooding: Bool
    var landslide: Bool
    var earthquake: Bool
    var tsunami: Bool
    var fire: Bool
    var internalFlooding: Bool
    var isSameAsRegion: Bool
    var latitude: Double
    var longitude: Double
    var additionalInfo: String
}
