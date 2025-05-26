//
//  NetworkService.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

import Foundation

/// A generic service for making network requests and decoding responses.
class NetworkService {

    private let session: URLSession

    /// Initializes the NetworkService with a given URLSession.
    /// - Parameter session: The URLSession to use for requests. Defaults to `URLSession.shared`.
    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Performs a generic network request and decodes the JSON response into a `Decodable` type.
    /// - Parameters:
    ///   - url: The URL for the request.
    ///   - type: The `Decodable` type to decode the response into.
    /// - Returns: An instance of the decoded type.
    /// - Throws: `NetworkError` if the request fails, the server responds with an error, or decoding fails.
    func request<T: Decodable>(url: URL) async throws -> T {
        return try await executeRequest(urlRequest: URLRequest(url: url))
    }

    /// Performs a POST request with a JSON body and decodes the response.
    /// Useful for GraphQL queries where the request body is JSON.
    /// - Parameters:
    ///   - url: The URL for the request.
    ///   - body: The `Encodable` object to be sent as the request body.
    ///   - type: The `Decodable` type to decode the response into.
    /// - Returns: An instance of the decoded type.
    /// - Throws: `NetworkError` if the request fails, the server responds with an error, or decoding fails.
    func postRequest<T: Decodable, U: Encodable>(url: URL, body: U) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw NetworkError.decodingError(error) // Encoding error
        }

        return try await executeRequest(urlRequest: request)
    }

    /// Internal helper to execute a URLRequest and decode the response.
    private func executeRequest<T: Decodable>(urlRequest: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: urlRequest)

            // Log response for debugging (can be removed or made conditional in production)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("--- API Response for \(urlRequest.url?.absoluteString ?? "N/A") ---")
                print(jsonString)
                print("---------------------------------------")
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(nil) // Should not happen with valid URLSession
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            // TMDB uses snake_case keys (e.g., "poster_path"), so we set this strategy.
            // AniList typically uses camelCase, so this strategy won't harm it.
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601 // Or .deferredToDate for dynamic date formats

            return try decoder.decode(T.self, from: data)

        } catch let urlError as URLError {
            throw NetworkError.networkConnectionError(urlError)
        } catch let decodingError as DecodingError {
            print("Decoding failed for \(T.self): \(decodingError)")
            // Detailed decoding error logging
            switch decodingError {
            case .typeMismatch(let type, let context):
                print("Type mismatch for type \(type) at key path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("Value not found for type \(type) at key path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("Key '\(key.stringValue)' not found at key path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription)")
            @unknown default:
                break
            }
            throw NetworkError.decodingError(decodingError)
        } catch let networkError as NetworkError {
            throw networkError // Re-throw our custom errors directly
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}
