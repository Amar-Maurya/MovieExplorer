//
//  DetailViewController.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
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
    @IBOutlet weak var favouriteButton: UIButton!
    @IBOutlet weak var favouriteTipView: UIView!
    
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
        tabBarController?.tabBar.isHidden = true
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showTip()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func addFavouriteAction(_ sender: UIButton) {
        sender.animatePopWithHaptic()
        updateFavouriteButtonImage(isFavourite: sender.isSelected)
        viewModel?.addRemoveFavourite()
    }
    
    private func showTip() {
        if !UserDefaultsManager.shared.hasSeenDetailTip {
            favouriteTipView.isHidden = false
            animateTipShake()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {[weak self] in
                guard let self else { return }
                self.favouriteTipView.isHidden = true
                UserDefaultsManager.shared.markDetailTipAsSeen()
            }
        } else {
            favouriteTipView.isHidden = true
        }
    }
    
    private func animateTipShake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 5
        animation.values = [-8, 8, -6, 6, -4, 4, 0] // Oscillating left & right
        favouriteTipView.layer.add(animation, forKey: "shake")
    }
    
    private func setupUI() {
        guard let detail = viewModel?.detailResponse else { return }
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
        genresLabel.text = detail.genres?.first?.name
        updateFavouriteButtonImage(isFavourite: detail.isFavourite)
    }
    
    func updateFavouriteButtonImage(isFavourite: Bool) {
        let imageName = isFavourite ? "heart.fill" : "heart"
        favouriteButton.tintColor = isFavourite ? .systemPink : .gray
        favouriteButton.setBackgroundImage(UIImage(systemName: imageName), for: .normal)
    }
    
    
}

extension DetailViewController: DetailViewModelDelegate {
    func didFetchMovieDetail() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.setupUI()
        }
      
    }

    func didFailWithError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self, viewModel?.detailResponse != nil else { return }
            self.setupUI()
            self.showAlert(message: error.localizedDescription)
        }
    }
    
    func updateFavouriteUI() {
        updateFavouriteButtonImage(isFavourite: viewModel?.detailResponse?.isFavourite ?? false)
    }
    
}

