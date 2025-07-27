//
//  LoaderView.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//

import UIKit

class LoaderView: UIView {
    
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    
    static let shared = LoaderView()
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = UIScreen.main.bounds
        self.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        activityIndicator.center = center
        activityIndicator.color = .secondaryLabel
        activityIndicator.startAnimating()
        addSubview(activityIndicator)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        DispatchQueue.main.async {
            if let window = UIApplication.topWindow {
                window.addSubview(self)
            }
        }
    }
    
    func hide() {
        DispatchQueue.main.async {
            self.removeFromSuperview()
        }
    }
}

extension UIApplication {
    static var topWindow: UIWindow? {
        return UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
