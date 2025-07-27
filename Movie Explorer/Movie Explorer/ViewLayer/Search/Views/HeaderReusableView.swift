//
//  HeaderReusableView.swift
//  MovieExplorer
//
//  Created by 2674143 on 26/07/25.
//

import UIKit

class HeaderReusableView: UICollectionReusableView {
    @IBOutlet weak var titleLabel: UILabel!

    func setTitle(_ title: String) {
        titleLabel.text = title
    }
}
