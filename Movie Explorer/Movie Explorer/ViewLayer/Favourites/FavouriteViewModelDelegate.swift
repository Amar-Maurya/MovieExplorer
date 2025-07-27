//
//  FavouriteViewModelDelegate.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//

protocol FavouriteViewModelDelegate: AnyObject {
    func didUpdateFavorites()
    func removeFromFavorites()
    func didFailWithError(_ error: Error)
}
