//
//  ButtonAnimation.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//

import UIKit

extension UIButton {
    func animatePop(duration: TimeInterval = 0.1, scale: CGFloat = 1.2) {
        UIView.animate(withDuration: duration,
                       animations: {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        },
                       completion: { _ in
            UIView.animate(withDuration: duration) {
                self.transform = CGAffineTransform.identity
            }
        })
    }
    
    func animatePopWithHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        animatePop()
    }
}
