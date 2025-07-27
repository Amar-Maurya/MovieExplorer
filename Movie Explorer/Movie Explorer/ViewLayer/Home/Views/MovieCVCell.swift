//
//  MovieCVCell.swift
//  Movie Explorer
//
//  Created by amar maurya on 26/07/25.
//

import UIKit


class MovieCVCell: UICollectionViewCell {
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var posterTitle: UILabel!
    @IBOutlet weak var posterDate: UILabel!
    @IBOutlet weak var posterRatingProgress: UIProgressView!
    @IBOutlet weak var favouriteImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Optional UI styling
        posterImageView.layer.cornerRadius = 8
        posterImageView.clipsToBounds = true
        posterRatingProgress.layer.cornerRadius = 1
        posterRatingProgress.clipsToBounds = true
    }
    
    func setupCell(with model: MovieModel) {
        posterTitle.text = model.title ?? "-"
        posterDate.text = model.releaseDate ?? "-"
        setProgressBar(ratingValue: model.rating ?? 0)
        if let posterPath = model.posterImagePath {
            let fullURL = Constants.baseImageURL + posterPath
            ImageLoader.shared.loadImage(from: fullURL) { [weak self] image in
                self?.posterImageView.image = image
            }
        } else {
            posterImageView.image = UIImage(named: "placeholder")
        }
    }
    
    private func setProgressBar(ratingValue: Float) {
        let normalized = ratingValue / 10.0
        posterRatingProgress.setProgress(0.0, animated: false)
        posterRatingProgress.progressTintColor = CommonHelper.colorForRating(ratingValue)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.posterRatingProgress.setProgress(normalized, animated: true)
        }
    }
}

