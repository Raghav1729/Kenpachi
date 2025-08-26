import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case decodingError
    case encodingError
    case noData
    case forbidden
    case notFound
    case serverError
    case timeout
    case noInternetConnection
    case downloadFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed:
            return "Request failed"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .noData:
            return "No data received"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error"
        case .timeout:
            return "Request timeout"
        case .noInternetConnection:
            return "No internet connection"
        case .downloadFailed:
            return "Download failed"
        case .unknown:
            return "Unknown error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noInternetConnection:
            return "Please check your internet connection and try again."
        case .timeout:
            return "The request timed out. Please try again."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        default:
            return "Please try again later."
        }
    }
}