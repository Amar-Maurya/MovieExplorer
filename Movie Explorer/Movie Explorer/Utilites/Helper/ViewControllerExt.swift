//
//  ViewControllerExt.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//

import UIKit

extension UIViewController {
    func showAlert(title: String = "Error", message: String, buttonTitle: String = "OK") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: buttonTitle, style: .default))
        self.present(alert, animated: true)
    }
}
