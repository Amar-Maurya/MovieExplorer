//
//  UserDefaultsManager.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//

import Foundation

final class UserDefaultsManager {
    
    static let shared = UserDefaultsManager()
    private init() {}
    
    private let hasSeenDetailTipKey = "hasSeenDetailTip"

    var hasSeenDetailTip: Bool {
        return UserDefaults.standard.bool(forKey: hasSeenDetailTipKey)
    }

    func markDetailTipAsSeen() {
        UserDefaults.standard.set(true, forKey: hasSeenDetailTipKey)
    }

    func resetDetailTipFlag() {
        UserDefaults.standard.removeObject(forKey: hasSeenDetailTipKey)
    }
}
