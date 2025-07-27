//
//  SearchViewController.swift
//  Movie Explorer
//
//  Created by 2674143 on 26/07/25.
//

import UIKit

class SearchViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var noResultsLabel: UILabel!

     var dataSource: UICollectionViewDiffableDataSource<SearchMovieSection, SearchMovieModel>!
     var viewModel: SearchViewModel = SearchViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        searchBar.delegate = self
        configureCollectionView()
        configureDataSource()
        addTapGesture()
        viewModel.fetchPopularMovies()
    }

}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchMovies(query: searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {[weak self] in
                guard let self else { return }
            searchBar.text = ""
            self.viewModel.isSearching = false
            self.noResultsLabel.isHidden = true
            self.applySnapshot()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
}

extension SearchViewController: MovieListViewModelDelegate {
    func didReceiveMovies() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.applySnapshot()
            self.noResultsLabel.isHidden = !self.viewModel.isSearching || !self.viewModel.searchResults.isEmpty
            if self.viewModel.isSearching {
                self.collectionView.setContentOffset(.zero, animated: true)
            }
        }
    }

    func didFailWithError(_ error: Error) {
        print("Error: \(error)")
    }
}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard !viewModel.isSearching else { return }
        let currentMovies = viewModel.getCurrentTopMovies()
        let lastIndex = currentMovies.count - 1
        if indexPath.item == lastIndex && viewModel.canLoadMore() {
            viewModel.fetchPopularMovies()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = viewModel.getCurrentTopMovies()[indexPath.row]
        guard let id = movie.id else { return }
        let detailVM = DetailViewModel(movieID: id)
        let detailVC = DetailViewController.instantiate(with: detailVM)
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension SearchViewController {
    func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
