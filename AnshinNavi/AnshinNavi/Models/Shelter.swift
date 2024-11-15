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
    @Attribute(.unique) var id: UUID = UUID()
    var regionCode: String
    var regionName: String
    var number: String
    var name: String
    var address: String
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
    
      init(
          regionCode: String,
          regionName: String,
          number: String,
          name: String,
          address: String,
          generalFlooding: Bool,
          landslide: Bool,
          earthquake: Bool,
          tsunami: Bool,
          fire: Bool,
          internalFlooding: Bool,
          isSameAsRegion: Bool,
          latitude: Double,
          longitude: Double,
          additionalInfo: String = ""
      ) {
          self.regionCode = regionCode
          self.regionName = regionName
          self.number = number
          self.name = name
          self.address = address
          self.generalFlooding = generalFlooding
          self.landslide = landslide
          self.earthquake = earthquake
          self.tsunami = tsunami
          self.fire = fire
          self.internalFlooding = internalFlooding
          self.isSameAsRegion = isSameAsRegion
          self.latitude = latitude
          self.longitude = longitude
          self.additionalInfo = additionalInfo
      }
  }
