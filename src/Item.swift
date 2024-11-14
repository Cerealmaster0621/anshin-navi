//
//  Item.swift
//  anshin-navi
//
//  Created by YoungJune Kang on 2024/11/14.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
