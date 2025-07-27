//
//  FavouriteViewController.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//

import UIKit

class FavouriteViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noDataFoundView: UIStackView!
    private var dataSource: UITableViewDiffableDataSource<FavouriteSection, MovieDetailResponse>!
    var viewmodel = FavouriteViewModel()

    @IBOutlet weak var editDoneBtn: UIButton!
    @IBOutlet weak var selectedAllFavBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewmodel.delegate = self
        configureTableView()
        configureDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        editDoneBtn.setTitle(ButtonConstants.edit, for: .normal)
        selectedAllFavBtn.setTitle(ButtonConstants.selectedAll, for: .normal)
        selectedAllFavBtn.isHidden = true
        viewmodel.fetchFavorites()
    }
    
    @IBAction func selectedAllFavouriteAction(_ sender: UIButton) {
        let isSelectedAll = sender.titleLabel?.text == ButtonConstants.selectedAll
        sender.setTitle(isSelectedAll ? ButtonConstants.unSelectedAll : ButtonConstants.selectedAll, for: .normal)
        viewmodel.toggleAllFavourite(isSelectedAll)
    }

    @IBAction func updateFavouriteAction(_ sender: UIButton) {
        let isEditMode = sender.titleLabel?.text == ButtonConstants.edit
        sender.setTitle(isEditMode ? ButtonConstants.done : ButtonConstants.edit, for: .normal)
        viewmodel.toggleEditMode(isEditMode)
        selectedAllFavBtn.isHidden = !isEditMode
        if !isEditMode {
            viewmodel.deleteSelectedFavourites()
        }
    }
    
    private func configureTableView() {
        tableView.register(UINib(nibName: CellConstants.favouriteTVCell, bundle: nil), forCellReuseIdentifier:  CellConstants.favouriteTVCell)
        tableView.delegate = self
    }

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<FavouriteSection, MovieDetailResponse>(tableView: tableView) { tableView, indexPath, movie in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CellConstants.favouriteTVCell, for: indexPath) as? FavouriteTVCell else {
                return UITableViewCell()
            }
            cell.onEditButtonTapped = {
                self.viewmodel.toggleSelection(at: indexPath.row)
            }
            cell.setupUI(detail: movie)
            return cell
        }
    }

    private func applySnapshot(movies: [MovieDetailResponse]) {
        var snapshot = NSDiffableDataSourceSnapshot<FavouriteSection, MovieDetailResponse>()
        snapshot.appendSections([.main])
        snapshot.appendItems(movies)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


extension FavouriteViewController: FavouriteViewModelDelegate {
    
    
    func didUpdateFavorites() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let movies = self.viewmodel.getFavourites()
            self.noDataFoundView.isHidden = !movies.isEmpty
            self.editDoneBtn.isHidden = movies.isEmpty
            self.selectedAllFavBtn.setTitle(self.viewmodel.isAllFavSelected ? ButtonConstants.unSelectedAll : ButtonConstants.selectedAll, for: .normal)
            self.applySnapshot(movies: movies)
        }
    }
    
    func didFailWithError(_ error: any Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.showAlert(message: error.localizedDescription)
        }
    }
    
    func removeFromFavorites() {
        DispatchQueue.main.async { [weak self] in
            LocalNotificationHelper.shared.notifyFavoritesCleared()
        }
    }
}

extension FavouriteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !viewmodel.isEditEnable {
            let movie = viewmodel.getFavouritesByIndex(index: indexPath.row)
            guard let id = movie.id else { return }
            let detailVM = DetailViewModel(movieID: id, detailResponse: movie)
            let detailVC = DetailViewController.instantiate(with: detailVM)
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}
