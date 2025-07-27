//
//  SearchModel.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//

struct SearchMovieListResponse: Codable {
    let page: Int?
    let results: [SearchMovieModel]?
    let totalPage: Int?
    
    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPage = "total_pages"
    }
}


struct SearchMovieModel: Codable, Hashable {
    var id: Int?
    var posterImagePath: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case posterImagePath = "poster_path"
    }
}
