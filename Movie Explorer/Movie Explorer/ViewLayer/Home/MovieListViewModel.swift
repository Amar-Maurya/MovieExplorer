//
//  MovieListViewModel.swift
//  Movie Explorer
//
//  Created by 2674143 on 26/07/25.
//

import Foundation

enum MovieSection {
    case main
}

class MovieListViewModel {
    
    weak var delegate: MovieListViewModelDelegate?
    private var currentPage = 1
    private var totalPages = 1
    private var isLoading = false
    var movies: [MovieModel] = []
    
    func fetchMovies() {
        guard !isLoading else { return }
        let url = APIConstants.fullURL(for: APIEndpoints.movies)
        let queryParams: [String: String] = [
            APIQueryKeys.apiKey: APIQueryValues.apiKey,
            APIQueryKeys.page: "\(currentPage)"
        ]
        guard currentPage <= totalPages else { return }
        isLoading = true

        NetworkManager.shared.request(
            url: url,
            queryParams: queryParams
        ) { (result: Result<MovieListResponse, NetworkError>) in
            self.isLoading = false
            switch result {
            case .success(let response):
                self.totalPages = response.totalPage ?? 0
                if let result = response.results {
                    self.movies += result.filter { newMovie in
                        !self.movies.contains(where: { $0.id == newMovie.id })
                    }
                    self.delegate?.didReceiveMovies()
                }
                self.currentPage += 1
            case .failure(let error):
                self.delegate?.didFailWithError(error)
            }
        }
    }
    
    func canLoadMore() -> Bool {
           return currentPage <= totalPages && !isLoading
       }
}
