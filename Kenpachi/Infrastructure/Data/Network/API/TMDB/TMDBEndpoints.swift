// TMDBEndpoints.swift
// TMDB API endpoint definitions
// Provides type-safe endpoint construction for TMDB requests

import Foundation

/// Enum defining all TMDB API endpoints
enum TMDBEndpoint: Endpoint {
    case trendingMovies(timeWindow: TrendingTimeWindow)
    case trendingTVShows(timeWindow: TrendingTimeWindow)
    case topRatedMovies
    case topRatedTVShows
    case popularMovies
    case popularTVShows
    case movieDetails(id: String)
    case tvShowDetails(id: String)
    case seasonDetails(tvShowId: String, seasonNumber: Int)
    case search(query: String, page: Int)
    
    var baseURL: String {
        APIConstants.TMDB.baseURL
    }
    
    var path: String {
        switch self {
        case .trendingMovies(let timeWindow):
            return "/trending/movie/\(timeWindow.rawValue)"
        case .trendingTVShows(let timeWindow):
            return "/trending/tv/\(timeWindow.rawValue)"
        case .topRatedMovies:
            return "/movie/top_rated"
        case .topRatedTVShows:
            return "/tv/top_rated"
        case .popularMovies:
            return "/movie/popular"
        case .popularTVShows:
            return "/tv/popular"
        case .movieDetails(let id):
            return "/movie/\(id)"
        case .tvShowDetails(let id):
            return "/tv/\(id)"
        case .seasonDetails(let tvShowId, let seasonNumber):
            return "/tv/\(tvShowId)/season/\(seasonNumber)"
        case .search:
            return "/search/multi"
        }
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var queryItems: [URLQueryItem]? {
        var items = [URLQueryItem(name: "api_key", value: APIConstants.TMDB.apiKey)]
        
        switch self {
        case .movieDetails:
            // Append credits, recommendations, and videos to movie details
            items.append(URLQueryItem(name: "append_to_response", value: "credits,recommendations,videos"))
            
        case .tvShowDetails:
            // Append credits, recommendations, videos, and seasons to TV show details
            items.append(URLQueryItem(name: "append_to_response", value: "credits,recommendations,videos"))
            
        case .search(let query, let page):
            items.append(URLQueryItem(name: "query", value: query))
            items.append(URLQueryItem(name: "page", value: String(page)))
            
        default:
            break
        }
        
        return items
    }
    
    var headers: [String: String]? {
        [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    var body: Data? {
        nil
    }
}
