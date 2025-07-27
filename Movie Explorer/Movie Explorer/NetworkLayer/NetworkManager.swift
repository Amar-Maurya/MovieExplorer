//
//  NetworkManager.swift
//  Movie Explorer
//
//  Created by amar maurya on 26/07/25.
//

import Foundation
import Alamofire

class NetworkManager {
    
    static let shared = NetworkManager()
    private init() {}

    private let reachabilityManager = NetworkReachabilityManager()
    
    var isInternetAvailable: Bool {
        return reachabilityManager?.isReachable ?? false
    }

    func request<T: Decodable>(
        url: String,
        method: String = "GET",
        queryParams: [String: String]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // Check internet first
        guard isInternetAvailable else {
            completion(.failure(.noInternet))
            return
        }

        guard var components = URLComponents(string: url) else {
            completion(.failure(.invalidURL))
            return
        }

        if let queryParams = queryParams {
            components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let finalURL = components.url else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method
        request.allHTTPHeaderFields = [
            APIQueryKeys.accept: APIQueryValues.acceptJsonValue,
            APIQueryKeys.authorization: APIConstants.authorizationToken
        ]

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.unknown(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.serverError(httpResponse.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
}
