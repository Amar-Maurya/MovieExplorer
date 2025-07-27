//
//  DetailViewController.swift
//  MovieExplorer
//
//  Created by 2674143 on 27/07/25.
//

import UIKit

class DetailViewController: UIViewController {
    private var viewModel: DetailViewModel?
    
    @IBOutlet weak var bannerImageView: UIImageView!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var watchTimeLabel: UILabel!
    @IBOutlet weak var genresLabel: UILabel!
    
    static func instantiate(with viewModel: DetailViewModel) -> DetailViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        vc.viewModel = viewModel
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.delegate = self
        viewModel?.fetchMovieDetail()
    }

    private func setupUI(detail: MovieDetailResponse) {
        if let posterPath = detail.posterPath {
            let fullURL = Constants.baseImageURL + posterPath
            ImageLoader.shared.loadImage(from: fullURL) { [weak self] image in
                self?.posterImageView.image = image
            }
        } else {
            posterImageView.image = UIImage(named: "placeholder")
        }
        
        if let backdropPath = detail.backdropPath {
            let fullURL = Constants.headerBaseImageURL + backdropPath
            ImageLoader.shared.loadImage(from: fullURL) { [weak self] image in
                self?.bannerImageView.image = image
            }
        } else {
            bannerImageView.image = UIImage(named: "placeholder")
        }
        titleLabel.text = detail.title
        releaseDateLabel.text = detail.releaseDate?.toYearOnly
        watchTimeLabel.text = "\(detail.runTime ?? 0)".toHourMinuteFormat
        ratingLabel.text = "★ " + "\(detail.voteAverage ?? 0.0)".toOneDecimal
        ratingLabel.textColor = CommonHelper.colorForRating(detail.voteAverage ?? 0.0)
        overviewLabel.text = detail.overview
        genresLabel.text = detail.genres.first?.name
    }
}

extension DetailViewController: DetailViewModelDelegate {
    func didFetchMovieDetail(_ detail: MovieDetailResponse) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.setupUI(detail: detail)
        }
      
    }

    func didFailWithError(_ error: Error) {
    }
}

