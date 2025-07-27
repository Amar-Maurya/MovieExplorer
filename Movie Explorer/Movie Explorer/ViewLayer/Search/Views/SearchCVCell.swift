//
//  SearchCVCell.swift
//  MovieExplorer
//
//  Created by 2674143 on 27/07/25.
//

import UIKit

class SearchCVCell: UICollectionViewCell {
    @IBOutlet weak var posterImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        posterImageView.layer.cornerRadius = 8
        posterImageView.clipsToBounds = true
    }
    
    func setupCell(with model: SearchMovieModel) {
        if let posterPath = model.posterImagePath {
            let fullURL = Constants.baseImageURL + posterPath
            ImageLoader.shared.loadImage(from: fullURL) { [weak self] image in
                self?.posterImageView.image = image
            }
        } else {
            posterImageView.image = UIImage(named: "placeholder")
        }
    }

}
