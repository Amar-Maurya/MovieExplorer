//
//  HeaderReusableView.swift
//  MovieExplorer
//
//  Created by amar maurya on 26/07/25.
//

import UIKit

class HeaderReusableView: UICollectionReusableView {
    @IBOutlet weak var titleLabel: UILabel!

    func setTitle(_ title: String) {
        titleLabel.text = title
    }
}
