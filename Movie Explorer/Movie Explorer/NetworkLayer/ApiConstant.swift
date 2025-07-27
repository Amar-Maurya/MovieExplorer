//
//  ApiConstant.swift
//  Movie Explorer
//
//  Created by 2674143 on 26/07/25.
//

import Foundation



struct APIConstants {
    static let baseURL = "https://api.themoviedb.org/3"
    static let apiKey = "399c618dc9335469e3527e97a56f6157"
    static let authorizationToken = "Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIzOTljNjE4ZGM5MzM1NDY5ZTM1MjdlOTdhNTZmNjE1NyIsIm5iZiI6MTc1MzQ0MjA5NC4wMTYsInN1YiI6IjY4ODM2NzJlMWRiMjMyMmRiMDM4ZWUzNiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.VRVz_eSGd8Fjb9owGUL2UCL952Pk8S9EAXayqG9Ox1I"
}

extension APIConstants {
    static func fullURL(for endpoint: String) -> String {
        return baseURL + endpoint
    }
}


struct APIEndpoints {
    static let movies = "/discover/movie"
    static let topRatedMovies = "/movie/top_rated"
    static let searchMovie = "/search/movie"
    static let movieDetail = "/movie/"
    static let popularMovies = "/movie/popular"
    static let upcomingMovies = "/movie/upcoming"
    static let nowPlayingMovies = "/movie/now_playing"
   
    static let latestMovie = "/movie/latest"
   

    static func movieDetail(id: Int) -> String {
        return "/movie/\(id)"
    }

    static func discoverMovies() -> String {
        return "/discover/movie"
    }

    static func movieImages(id: Int) -> String {
        return "/movie/\(id)/images"
    }

    static func movieVideos(id: Int) -> String {
        return "/movie/\(id)/videos"
    }
}
