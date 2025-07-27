//
//  FavouriteTVCell.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//

import UIKit

class FavouriteTVCell: UITableViewCell {
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var watchTimeLabel: UILabel!
    @IBOutlet weak var genresLabel: UILabel!
    @IBOutlet weak var editCellButton: UIButton!
    var onEditButtonTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        onEditButtonTapped?()
    }
    
    func setupUI(detail: MovieDetailResponse) {
        if let posterPath = detail.posterPath {
            let fullURL = Constants.baseImageURL + posterPath
            ImageLoader.shared.loadImage(from: fullURL) { [weak self] image in
                self?.posterImageView.image = image
            }
        } else {
            posterImageView.image = UIImage(named: "placeholder")
        }
        titleLabel.text = detail.title
        releaseDateLabel.text = detail.releaseDate?.toYearOnly
        watchTimeLabel.text = "\(detail.runTime ?? 0)".toHourMinuteFormat
        ratingLabel.text = "★ " + "\(detail.voteAverage ?? 0.0)".toOneDecimal
        ratingLabel.textColor = CommonHelper.colorForRating(detail.voteAverage ?? 0.0)
        genresLabel.text = detail.genres?.first?.name
        editCellButton.isHidden = !detail.isEditEnable
        let image = detail.isSelected ? UIImage(systemName: "checkmark.square") : UIImage(systemName: "square")
        editCellButton.setBackgroundImage( image, for: .normal)
    }
    
}
