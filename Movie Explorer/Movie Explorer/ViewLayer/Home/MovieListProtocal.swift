//
//  MovieListProtocal.swift
//  Movie Explorer
//
//  Created by amar maurya on 26/07/25.
//

protocol MovieListViewModelDelegate: AnyObject {
    func didReceiveMovies()
    func didFailWithError(_ error: Error)
}
