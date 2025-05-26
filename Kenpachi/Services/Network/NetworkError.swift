//
//  NetworkError.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

import Foundation

/// Custom error types for network operations.
enum NetworkError: Error, Equatable, LocalizedError {
    /// Indicates that the URL for the request could not be constructed or is invalid.
    case invalidURL

    /// Indicates a problem with the server's response (e.g., non-2xx status code).
    /// - Parameter statusCode: The HTTP status code received from the server.
    case serverError(statusCode: Int)

    /// Indicates an issue with decoding the API response into a Swift model.
    /// - Parameter error: The underlying `DecodingError` or other related error.
    case decodingError(Error)

    /// Indicates a generic network connectivity issue (e.g., no internet, timeout).
    /// - Parameter error: The underlying `URLError`.
    case networkConnectionError(URLError)

    /// An unknown error occurred during the network request.
    /// - Parameter error: The underlying `Error` if available.
    case unknown(Error?)

    // Conformance to Equatable for easier testing and comparison.
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): return true
        case (.serverError(let sc1), .serverError(let sc2)): return sc1 == sc2
        case (.networkConnectionError(let urle1), .networkConnectionError(let urle2)):
            // Compare URLError codes for better equality check
            return urle1.code == urle2.code // Simplified check
        case (.decodingError, .decodingError): return true // For simplicity, just check type
        case (.unknown, .unknown): return true // For simplicity, just check type
        default: return false
        }
    }

    // Conformance to LocalizedError for user-friendly descriptions.
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .serverError(let statusCode):
            return "Server error: Status code \(statusCode)."
        case .decodingError(let error):
            return "Failed to decode the response: \(error.localizedDescription)"
        case .networkConnectionError(let error):
            return "Network connection error: \(error.localizedDescription)"
        case .unknown(let error):
            return "An unknown error occurred: \(error?.localizedDescription ?? "No description available")."
        }
    }
}
