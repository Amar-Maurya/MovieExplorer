//
//  StringExt.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//

import Foundation

extension String {
    
    var toYearOnly: String {
        return self.split(separator: "-").first.map(String.init) ?? self
    }

    var toHourMinuteFormat: String {
        guard let minutes = Int(self) else { return self }
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }

    var toOneDecimal: String {
        guard let doubleValue = Double(self) else { return self }
        return String(format: "%.1f", doubleValue)
    }
}
