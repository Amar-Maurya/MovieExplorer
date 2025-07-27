//
//  DetailViewModel.swift
//  MovieExplorer
//
//  Created by 2674143 on 27/07/25.
//

protocol DetailViewModelDelegate: AnyObject {
    func didFetchMovieDetail(_ detail: MovieDetailResponse)
    func didFailWithError(_ error: Error)
}

final class DetailViewModel {
    private let movieID: Int
    weak var delegate: DetailViewModelDelegate?
    private var isLoading = false
    
    init(movieID: Int) {
        self.movieID = movieID
    }

    func fetchMovieDetail() {
        guard !isLoading else { return }
        isLoading = true
        let url = APIConstants.fullURL(for: APIEndpoints.movieDetail)
        let queryParams: [String: String] = [APIQueryKeys.apiKey: APIQueryValues.apiKey]

        NetworkManager.shared.request(url: "\(url)\(movieID)", queryParams: queryParams) { (result: Result<MovieDetailResponse, NetworkError>) in
            self.isLoading = false
            switch result {
            case .success(let response):
                self.delegate?.didFetchMovieDetail(response)
            case .failure(let error):
                self.delegate?.didFailWithError(error)
            }
        }
    }
}
