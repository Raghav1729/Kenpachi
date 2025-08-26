import Foundation
import Combine

final class TMDBService {
    private let networkService: NetworkServiceProtocol
    private let apiKey: String
    
    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        apiKey: String = "YOUR_TMDB_API_KEY" // Replace with actual API key
    ) {
        self.networkService = networkService
        self.apiKey = apiKey
    }
    
    func getTrending(timeWindow: TimeWindow) -> AnyPublisher<TMDBResponse<TMDBContent>, Error> {
        let endpoint = TMDBEndpoint.trending(timeWindow: timeWindow, apiKey: apiKey)
        return networkService.request(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func getPopularMovies(page: Int) -> AnyPublisher<TMDBResponse<TMDBMovie>, Error> {
        let endpoint = TMDBEndpoint.popularMovies(page: page, apiKey: apiKey)
        return networkService.request(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func getPopularTVShows(page: Int) -> AnyPublisher<TMDBResponse<TMDBTVShow>, Error> {
        let endpoint = TMDBEndpoint.popularTVShows(page: page, apiKey: apiKey)
        return networkService.request(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func getMovieDetails(id: String) -> AnyPublisher<TMDBMovie, Error> {
        let endpoint = TMDBEndpoint.movieDetails(id: id, apiKey: apiKey)
        return networkService.request(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func getTVShowDetails(id: String) -> AnyPublisher<TMDBTVShow, Error> {
        let endpoint = TMDBEndpoint.tvShowDetails(id: id, apiKey: apiKey)
        return networkService.request(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

// MARK: - TMDB Models

struct TMDBResponse<T: Codable>: Codable {
    let page: Int
    let results: [T]
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBContent: Codable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let mediaType: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case mediaType = "media_type"
    }
}

struct TMDBMovie: Codable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let runtime: Int?
    let genres: [TMDBGenre]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, genres
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
    }
}

struct TMDBTVShow: Codable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let genres: [TMDBGenre]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, overview, genres
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case numberOfSeasons = "number_of_seasons"
        case numberOfEpisodes = "number_of_episodes"
    }
}

struct TMDBGenre: Codable {
    let id: Int
    let name: String
}

// MARK: - TMDB Endpoints

enum TMDBEndpoint: Endpoint {
    case trending(timeWindow: TimeWindow, apiKey: String)
    case popularMovies(page: Int, apiKey: String)
    case popularTVShows(page: Int, apiKey: String)
    case movieDetails(id: String, apiKey: String)
    case tvShowDetails(id: String, apiKey: String)
    
    var baseURL: String {
        return APIConstants.tmdbBaseURL
    }
    
    var path: String {
        switch self {
        case .trending(let timeWindow, _):
            return "/trending/all/\(timeWindow.rawValue)"
        case .popularMovies:
            return "/movie/popular"
        case .popularTVShows:
            return "/tv/popular"
        case .movieDetails(let id, _):
            return "/movie/\(id)"
        case .tvShowDetails(let id, _):
            return "/tv/\(id)"
        }
    }
    
    var method: HTTPMethod {
        return .GET
    }
    
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "User-Agent": APIConstants.userAgent
        ]
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .trending(_, let apiKey):
            return ["api_key": apiKey]
        case .popularMovies(let page, let apiKey):
            return ["api_key": apiKey, "page": page]
        case .popularTVShows(let page, let apiKey):
            return ["api_key": apiKey, "page": page]
        case .movieDetails(_, let apiKey):
            return ["api_key": apiKey]
        case .tvShowDetails(_, let apiKey):
            return ["api_key": apiKey]
        }
    }
}