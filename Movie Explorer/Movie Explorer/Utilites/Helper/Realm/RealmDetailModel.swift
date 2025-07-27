//
//  RealmDetailModel.swift
//  MovieExplorer
//
//  Created by 2674143 on 27/07/25.
//

import RealmSwift

class MovieDetailObject: Object {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var title: String = ""
    @Persisted var runTime: Int?
    @Persisted var releaseDate: String?
    @Persisted var voteAverage: Float?
    @Persisted var posterPath: String?
    @Persisted var backdropPath: String?
    @Persisted var overview: String = ""
    @Persisted var productionCompanies = List<ProductionCompanyObject>()
    @Persisted var genres = List<GenreObject>()
}

class ProductionCompanyObject: Object {
    @Persisted var name: String?
    @Persisted var logoPath: String?
}

class GenreObject: Object {
    @Persisted var name: String?
}

extension MovieDetailObject {
    convenience init(from response: MovieDetailResponse, id: Int) {
        self.init()
        self.id = id
        self.title = response.title
        self.runTime = response.runTime
        self.releaseDate = response.releaseDate
        self.voteAverage = response.voteAverage
        self.posterPath = response.posterPath
        self.backdropPath = response.backdropPath
        self.overview = response.overview
        
        self.productionCompanies.append(objectsIn: response.productionCompanies.map {
            let company = ProductionCompanyObject()
            company.name = $0.name
            company.logoPath = $0.logoPath
            return company
        })
        
        self.genres.append(objectsIn: response.genres.map {
            let genre = GenreObject()
            genre.name = $0.name
            return genre
        })
    }
}
