//
//  SearchViewModel.swift
//  Movie Explorer
//
//  Created by amar maurya on 26/07/25.
//
import Foundation

enum SearchMovieSection: Hashable {
    case topRated
    case searchResults

    var title: String {
        switch self {
        case .topRated: return "Top Rated Movies"
        case .searchResults: return "Search Results"
        }
    }
}

class SearchViewModel {
    
    weak var delegate: MovieListViewModelDelegate?
    private var currentPage = 1
    private var totalPages = 1
    private var isLoading = false
    var topRatedMovies: [SearchMovieModel] = []
    var searchResults: [SearchMovieModel] = []
    var isSearching: Bool = false
    private var debounceTimer: Timer?
    
    func fetchPopularMovies() {
        guard !isLoading, currentPage <= totalPages else { return }
        
        isLoading = true
        let url = APIConstants.fullURL(for: APIEndpoints.topRatedMovies)
        let queryParams: [String: String] = [
            APIQueryKeys.apiKey: APIQueryValues.apiKey,
            APIQueryKeys.page: "\(currentPage)"
        ]

        NetworkManager.shared.request(url: url, queryParams: queryParams) { (result: Result<SearchMovieListResponse, NetworkError>) in
            self.isLoading = false
            switch result {
            case .success(let response):
                self.totalPages = response.totalPage ?? 1
                if let result = response.results {
                    self.topRatedMovies += result.filter { newMovie in
                        !self.topRatedMovies.contains(where: { $0.id == newMovie.id })
                    }
                    self.delegate?.didReceiveMovies()
                }
                self.currentPage += 1
            case .failure(let error):
                self.delegate?.didFailWithError(error)
            }
        }
    }
    
    func searchMovies(query: String) {
        debounceTimer?.invalidate()
        isSearching = true
        
        guard !query.isEmpty else {
            isSearching = false
            delegate?.didReceiveMovies()
            return
        }
        
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {[weak self] _ in
            guard let self else {return }
            let url = APIConstants.fullURL(for: APIEndpoints.searchMovie)
            let queryParams: [String: String] = [
                APIQueryKeys.apiKey: APIQueryValues.apiKey,
                APIQueryKeys.query: query
            ]
            
            NetworkManager.shared.request(url: url, queryParams: queryParams) { (result: Result<SearchMovieListResponse, NetworkError>) in
                switch result {
                case .success(let response):
                    self.searchResults = response.results ?? []
                    self.delegate?.didReceiveMovies()
                case .failure(let error):
                    self.delegate?.didFailWithError(error)
                }
            }
        }
    }

    func getCurrentTopMovies() -> [SearchMovieModel] {
        return isSearching ? searchResults : topRatedMovies
    }

    func canLoadMore() -> Bool {
        return currentPage <= totalPages && !isLoading && !isSearching
    }
}
