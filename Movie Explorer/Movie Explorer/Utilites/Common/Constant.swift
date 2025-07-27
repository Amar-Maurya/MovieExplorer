//
//  Constant.swift
//  Movie Explorer
//
//  Created by 2674143 on 26/07/25.
//

enum CellConstants {
    static let movieCVCell = "MovieCVCell"
    static let searchCVCell = "SearchCVCell"
    static let headerReusableView = "HeaderReusableView"
}


enum APIQueryKeys {
    static let apiKey = "api_key"
    static let language = "language"
    static let page = "page"
    static let authorization = "Authorization"
    static let accept = "accept"
    static let query = "query"
    static let movieId = "movie_id"
}

enum APIQueryValues {
    static let apiKey = APIConstants.apiKey
    static let defaultLanguage = "en-US"
    static let acceptJsonValue = "application/json"
}


enum Constants {
    static let baseImageURL = "https://image.tmdb.org/t/p/w500"
    static let headerBaseImageURL = "https://image.tmdb.org/t/p/original"
}

