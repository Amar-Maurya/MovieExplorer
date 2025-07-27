//
//  RealmHelper.swift
//  MovieExplorer
//
//  Created by 2674143 on 27/07/25.
//

class RealmHelper {
    static let shared = RealmHelper()
    private let realm = try! Realm()

    // Add or Update Favorite
    func addToFavorites(_ response: MovieDetailResponse, id: Int) {
        let movie = MovieDetailObject(from: response, id: id)
        try? realm.write {
            realm.add(movie, update: .modified)
        }
    }

    // Remove Favorite
    func removeFromFavorites(id: Int) {
        if let movie = realm.object(ofType: MovieDetailObject.self, forPrimaryKey: id) {
            try? realm.write {
                realm.delete(movie)
            }
        }
    }

    // Get All Favorites
    func getAllFavorites() -> [MovieDetailResponse] {
        let results = realm.objects(MovieDetailObject.self)
        return results.map { MovieDetailResponse(from: $0) }
    }

    // Check if movie is already favorite
    func isFavorite(id: Int) -> Bool {
        return realm.object(ofType: MovieDetailObject.self, forPrimaryKey: id) != nil
    }
}
