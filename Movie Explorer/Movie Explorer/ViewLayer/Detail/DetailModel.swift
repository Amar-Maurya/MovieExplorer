//
//  DetailModel.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//

struct MovieDetailResponse: Decodable, Hashable {
    let id: Int?
    let title: String?
    let runTime: Int?
    let releaseDate: String?
    let voteAverage: Float?
    let posterPath: String?
    let backdropPath: String?
    let overview: String?
    let productionCompanies: [ProductionCompany]?
    let genres: [Genre]?
    var isFavourite: Bool = false
    var isEditEnable: Bool = false
    var isSelected: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case runTime = "runtime"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case overview
        case productionCompanies = "production_companies"
        case genres
    }
    
    static func == (lhs: MovieDetailResponse, rhs: MovieDetailResponse) -> Bool {
        lhs.id == rhs.id && lhs.isEditEnable == rhs.isEditEnable && lhs.isSelected == rhs.isSelected
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isEditEnable)
        hasher.combine(isSelected)
    }
    
}

struct ProductionCompany: Decodable {
    let name: String?
    let logoPath: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case logoPath = "logo_path"
    }
}

struct Genre: Decodable {
    let name: String?
}

extension MovieDetailResponse {
    init(from object: MovieDetailObject) {
        self.id = object.id
        self.title = object.title
        self.runTime = object.runTime
        self.releaseDate = object.releaseDate
        self.voteAverage = object.voteAverage
        self.posterPath = object.posterPath
        self.backdropPath = object.backdropPath
        self.overview = object.overview
        self.productionCompanies = object.productionCompanies.map {
            ProductionCompany(name: $0.name, logoPath: $0.logoPath)
        }
        self.genres = object.genres.map {
            Genre(name: $0.name)
        }
    }
}
