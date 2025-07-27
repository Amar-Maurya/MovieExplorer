//
//  MovieListProtocal.swift
//  Movie Explorer
//
//  Created by 2674143 on 26/07/25.
//

protocol MovieListViewModelDelegate: AnyObject {
    func didReceiveMovies()
    func didFailWithError(_ error: Error)
}
