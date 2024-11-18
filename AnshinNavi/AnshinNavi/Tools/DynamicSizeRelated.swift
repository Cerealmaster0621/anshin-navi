import SwiftUI
import Foundation


func dynamicSize(baseSize : CGFloat) -> CGFloat {
    let screenHeight = UIScreen.main.bounds.height
    
    switch screenHeight {
    case 0..<670:  // iPhone SE, mini
        return baseSize * 0.8
    case 670..<800:  // Standard iPhones
        return baseSize
    default:  // Larger iPhones
        return baseSize * 1.2
    }
}
