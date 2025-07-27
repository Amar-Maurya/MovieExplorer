//
//  DetailViewModel.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//
import UIKit

protocol DetailViewModelDelegate: AnyObject {
    func didFetchMovieDetail()
    func updateFavouriteUI()
    func didFailWithError(_ error: Error)
}

final class DetailViewModel {
    private let movieID: Int
    weak var delegate: DetailViewModelDelegate?
    private var isLoading = false
    var detailResponse: MovieDetailResponse?
    init(movieID: Int, detailResponse: MovieDetailResponse) {
        self.movieID = movieID
        self.detailResponse = detailResponse
        self.detailResponse?.isFavourite = RealmHelper.shared.isFavourite(id: self.movieID)
    }
    
    init(movieID: Int) {
        self.movieID = movieID
    }

    func fetchMovieDetail() {
        guard !isLoading else { return }
        isLoading = true
        let url = APIConstants.fullURL(for: APIEndpoints.movieDetail)
        let queryParams: [String: String] = [APIQueryKeys.apiKey: APIQueryValues.apiKey]

        NetworkManager.shared.request(url: "\(url)\(movieID)", queryParams: queryParams) { (result: Result<MovieDetailResponse, NetworkError>) in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(var response):
                    response.isFavourite = RealmHelper.shared.isFavourite(id: self.movieID)
                    self.detailResponse = response
                    self.delegate?.didFetchMovieDetail()
                case .failure(let error):
                    self.delegate?.didFailWithError(error)
                }
            }
        }
    }
    
    func addRemoveFavourite() {
        guard let detailResponse = detailResponse else { return }
        if detailResponse.isFavourite {
            RealmHelper.shared.removeFromFavourites(id: movieID) { [weak self] result in
                guard let self else { return }
                self.detailResponse?.isFavourite = false
                self.delegate?.updateFavouriteUI()
                LocalNotificationHelper.shared.notifyMovieRemoved(detailResponse.title ?? "" )
            }
        } else {
            RealmHelper.shared.addToFavourites(detailResponse, id: movieID) { result in
                self.detailResponse?.isFavourite = true
                self.delegate?.updateFavouriteUI()
                LocalNotificationHelper.shared.notifyMovieAdded(detailResponse.title ?? "")
            }
        }
    }
}
