//
//  MovieListViewController.swift
//  Movie Explorer
//
//  Created by 2674143 on 25/07/25.
//

import UIKit

class MovieListViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var dataSource: UICollectionViewDiffableDataSource<MovieSection, MovieModel>!
    private var viewModel: MovieListViewModel = MovieListViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        configureCollectionView()
        configureDataSource()
        viewModel.fetchMovies()
    }
    
    private func configureCollectionView() {
        collectionView.register(UINib(nibName: CellConstants.movieCVCell, bundle: nil), forCellWithReuseIdentifier: CellConstants.movieCVCell)
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width / 2 - 16, height: 300)
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        collectionView.collectionViewLayout = layout
    }
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<MovieSection, MovieModel>(collectionView: collectionView) { collectionView, indexPath, movie in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellConstants.movieCVCell, for: indexPath) as? MovieCVCell else {
                return UICollectionViewCell()
            }
            cell.setupCell(with: movie)
            return cell
        }
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<MovieSection, MovieModel>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.movies)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}


extension MovieListViewController: MovieListViewModelDelegate {
    
    func didReceiveMovies() {
        applySnapshot()
    }
    
    func didFailWithError(_ error: Error) {
        print("Error: \(error)")
    }
}

extension MovieListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let lastIndex = viewModel.movies.count - 1
        if indexPath.item == lastIndex && viewModel.canLoadMore() {
            viewModel.fetchMovies()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = viewModel.movies[indexPath.item]
        guard let id = movie.id else { return }
        let detailVM = DetailViewModel(movieID: id)
        let detailVC = DetailViewController.instantiate(with: detailVM)
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
}
