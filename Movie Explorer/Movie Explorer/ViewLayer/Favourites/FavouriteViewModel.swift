//
//  FavouriteViewModel.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//

import Foundation

enum FavouriteSection {
    case main
}

final class FavouriteViewModel {

    weak var delegate: FavouriteViewModelDelegate?
    private var favourites: [MovieDetailResponse] = []
    var isEditEnable: Bool = false
    var isAllFavSelected: Bool = false
    
    func fetchFavorites() {
        isAllFavSelected = false
        isEditEnable = false
        favourites = RealmHelper.shared.getAllFavourites()
        delegate?.didUpdateFavorites()
    }

    func removeFavorite(id: [Int]) {
        RealmHelper.shared.removeFavourites(ids: id) { [weak self] result in
            if let result = result as? Error {
                self?.delegate?.didFailWithError(result)
                return
            }
            self?.delegate?.removeFromFavorites()
            self?.fetchFavorites()
        }
    }
    
    func removeAllFavorites() {
        RealmHelper.shared.clearAllFavourites() { [weak self] result in
            if let result = result as? Error {
                self?.delegate?.didFailWithError(result)
                return
            }
            self?.delegate?.removeFromFavorites()
            self?.fetchFavorites()
        }
    }
    
    func getFavourites() -> [MovieDetailResponse] {
        return favourites
    }
    
    func getFavouritesByIndex(index: Int) -> MovieDetailResponse {
        return favourites[index]
    }
    
    func toggleEditMode(_ isEdit: Bool) {
        isEditEnable = isEdit
        favourites = favourites.map {
            var updated = $0
            updated.isEditEnable = isEdit
            return updated
        }
        delegate?.didUpdateFavorites()
    }
    
    func toggleAllFavourite(_ isSelectedAll: Bool) {
        isAllFavSelected = isSelectedAll
        favourites = favourites.map {
            var updated = $0
            updated.isEditEnable = true
            updated.isSelected = isSelectedAll
            return updated
        }
        delegate?.didUpdateFavorites()
    }
    
    func toggleSelection(at index: Int) {
        guard !favourites.isEmpty else { return }
        favourites[index].isSelected.toggle()
        isAllFavSelected = favourites.filter { $0.isSelected }.count == favourites.count
        delegate?.didUpdateFavorites()
    }
    
    func getSelectedFavourites() -> [Int] {
        favourites.filter { $0.isSelected }.map { $0.id ?? 0 }
    }
    
    func deleteSelectedFavourites() {
        let selectedIds = getSelectedFavourites()
        guard !selectedIds.isEmpty else { return }
        removeFavorite(id: selectedIds)
    }
}

