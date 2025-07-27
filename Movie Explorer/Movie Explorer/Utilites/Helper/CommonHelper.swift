//
//  CommonHelper.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//
import UIKit

struct CommonHelper {
    
    static func colorForRating(_ rating: Float) -> UIColor {
        switch rating {
        case 8.0...10.0:
            return UIColor.systemGreen // Excellent
        case 6.0..<8.0:
            return UIColor.systemYellow // Good
        case 4.0..<6.0:
            return UIColor.orange // Average
        case 0.1..<4.0:
            return UIColor.red // Poor
        default:
            return UIColor.lightGray // No rating or invalid
        }
    }
}
