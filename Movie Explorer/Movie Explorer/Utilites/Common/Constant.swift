//
//  Constant.swift
//  Movie Explorer
//
//  Created by amar maurya on 26/07/25.
//

enum CellConstants {
    static let movieCVCell = "MovieCVCell"
    static let searchCVCell = "SearchCVCell"
    static let headerReusableView = "HeaderReusableView"
    static let favouriteTVCell = "FavouriteTVCell"
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


enum NotificationConstants {
    enum Titles {
        static let added = "Added to Favorites"
        static let removed = "Removed from Favorites"
        static let cleared = "Favorites Cleared"
        static let disabled = "Notifications Disabled"
    }

    enum Messages {
        static func added(movie: String) -> String {
            return "🎬 '\(movie)' was added to your favorites."
        }

        static func removed(movie: String) -> String {
            return "🗑️ '\(movie)' was removed from your favorites."
        }

        static let cleared = "🧹favorite movie were removed."
        static let permissionRequired = "Please enable notifications in Settings to receive updates."
    }

    enum AlertActions {
        static let cancel = "Cancel"
        static let settings = "Settings"
    }
}

enum ButtonConstants {
    static let edit = "Edit"
    static let done = "Done"
    static let selectedAll = "Selected All"
    static let unSelectedAll = "UnSelected All"
}

enum NetworkError: Error {
    case noInternet
    case invalidURL
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(Int)
    case unknown(Error)

    var localizedDescription: String {
        switch self {
        case .noInternet: return "No internet connection."
        case .invalidURL: return "Invalid URL."
        case .invalidResponse: return "Invalid response from server."
        case .noData: return "No data received."
        case .decodingError(let error): return "Decoding failed: \(error.localizedDescription)"
        case .serverError(let code): return "Server returned error code \(code)."
        case .unknown(let error): return "Something went wrong: \(error.localizedDescription)"
        }
    }
}
