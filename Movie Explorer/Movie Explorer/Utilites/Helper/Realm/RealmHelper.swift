//
//  RealmHelper.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//

import RealmSwift

class RealmHelper {
    static let shared = RealmHelper()
    private let realm = try! Realm()
    
    // MARK: - Add or Update Favorite
    func addToFavourites(_ response: MovieDetailResponse, id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let movie = MovieDetailObject(from: response, id: id)
        do {
            try realm.write {
                realm.add(movie, update: .modified)
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Remove Favorite
    func removeFromFavourites(id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        if let movie = realm.object(ofType: MovieDetailObject.self, forPrimaryKey: id) {
            do {
                try realm.write {
                    realm.delete(movie)
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        } else {
            completion(.failure(NSError(domain: "RealmHelper", code: 404, userInfo: [NSLocalizedDescriptionKey: "Movie not found"])))
        }
    }
    
    // MARK: - Remove Multiple Favorites
    func removeFavourites(ids: [Int], completion: @escaping (Result<Void, Error>) -> Void) {
        let movies = realm.objects(MovieDetailObject.self).filter("id IN %@", ids)
        do {
            try realm.write {
                realm.delete(movies)
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Clear All Favorites
    func clearAllFavourites(completion: @escaping (Result<Void, Error>) -> Void) {
        let allMovies = realm.objects(MovieDetailObject.self)
        do {
            try realm.write {
                realm.delete(allMovies)
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Get All Favorites
    func getAllFavourites() -> [MovieDetailResponse] {
        let results = realm.objects(MovieDetailObject.self)
        return results.map { MovieDetailResponse(from: $0) }
    }

    // MARK: - Check if Favorite
    func isFavourite(id: Int) -> Bool {
        return realm.object(ofType: MovieDetailObject.self, forPrimaryKey: id) != nil
    }
}

