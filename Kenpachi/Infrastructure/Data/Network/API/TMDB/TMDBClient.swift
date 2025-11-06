// TMDBClient.swift
// TMDB API client for fetching movie and TV show data
// Provides methods for trending content, search, and details

import Foundation

/// Client for interacting with The Movie Database API
final class TMDBClient {
  /// Shared singleton instance
  static let shared = TMDBClient()

  /// Network client for making requests
  private let networkClient: NetworkClientProtocol

  /// Initializer with dependency injection
  init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
    self.networkClient = networkClient
  }

  /// Fetches top-rated movies
  /// - Returns: Array of movies (released only)
  func fetchTopRatedMovies() async throws -> [Content] {
    let endpoint = TMDBEndpoint.topRatedMovies
    let response: TMDBPagedResponse<TMDBMovie> = try await networkClient.request(endpoint)
    return response.results
      .filter { $0.isReleased() }
      .map { $0.toContent() }
  }

  /// Fetches top-rated TV shows
  /// - Returns: Array of TV shows (released only)
  func fetchTopRatedTVShows() async throws -> [Content] {
    let endpoint = TMDBEndpoint.topRatedTVShows
    let response: TMDBPagedResponse<TMDBTVShow> = try await networkClient.request(endpoint)
    return response.results
      .filter { $0.isReleased() }
      .map { $0.toContent() }
  }

  /// Fetches popular movies
  /// - Returns: Array of movies (released only)
  func fetchPopularMovies() async throws -> [Content] {
    let endpoint = TMDBEndpoint.popularMovies
    let response: TMDBPagedResponse<TMDBMovie> = try await networkClient.request(endpoint)
    return response.results
      .filter { $0.isReleased() }
      .map { $0.toContent() }
  }

  /// Fetches popular TV shows
  /// - Returns: Array of TV shows (released only)
  func fetchPopularTVShows() async throws -> [Content] {
    let endpoint = TMDBEndpoint.popularTVShows
    let response: TMDBPagedResponse<TMDBTVShow> = try await networkClient.request(endpoint)
    return response.results
      .filter { $0.isReleased() }
      .map { $0.toContent() }
  }

  /// Fetches trending movies
  /// - Parameter timeWindow: Time window for trending (day or week)
  /// - Returns: Array of trending movies (only released)
  func fetchTrendingMovies(timeWindow: TrendingTimeWindow = .day) async throws -> [Content] {
    let endpoint = TMDBEndpoint.trendingMovies(timeWindow: timeWindow)
    let response: TMDBPagedResponse<TMDBMovie> = try await networkClient.request(endpoint)
    // Filter to only include released movies
    return response.results
      .filter { $0.isReleased() }
      .map { $0.toContent() }
  }

  /// Fetches trending TV shows
  /// - Parameter timeWindow: Time window for trending (day or week)
  /// - Returns: Array of trending TV shows (only released)
  func fetchTrendingTVShows(timeWindow: TrendingTimeWindow = .day) async throws -> [Content] {
    let endpoint = TMDBEndpoint.trendingTVShows(timeWindow: timeWindow)
    let response: TMDBPagedResponse<TMDBTVShow> = try await networkClient.request(endpoint)
    // Filter to only include released TV shows
    return response.results
      .filter { $0.isReleased() }
      .map { $0.toContent() }
  }

  /// Fetches movie details
  /// - Parameter id: Movie ID
  /// - Returns: Detailed movie content
  func fetchMovieDetails(id: String) async throws -> Content {
    let endpoint = TMDBEndpoint.movieDetails(id: id)
    let movie: TMDBMovie = try await networkClient.request(endpoint)
    return movie.toContent()
  }

  /// Fetches TV show details with seasons and episodes
  /// - Parameter id: TV show ID
  /// - Returns: Detailed TV show content with full episode data
  func fetchTVShowDetails(id: String) async throws -> Content {
    // First, fetch the basic TV show details with credits, recommendations, and videos
    let endpoint = TMDBEndpoint.tvShowDetails(id: id)
    var tvShow: TMDBTVShow = try await networkClient.request(endpoint)

    // If the TV show has seasons, fetch detailed episode information for each season
    if let numberOfSeasons = tvShow.numberOfSeasons, numberOfSeasons > 0 {
      var detailedSeasons: [TMDBSeason] = []

      // Fetch details for each season (skip season 0 which is usually specials)
      for seasonNumber in 1...numberOfSeasons {
        do {
          let seasonEndpoint = TMDBEndpoint.seasonDetails(tvShowId: id, seasonNumber: seasonNumber)
          let season: TMDBSeason = try await networkClient.request(seasonEndpoint)
          detailedSeasons.append(season)
        } catch {
          // Log error but continue with other seasons
          AppLogger.shared.log(
            "Failed to fetch season \(seasonNumber) for TV show \(id): \(error.localizedDescription)",
            level: .warning
          )
        }
      }

      // Update TV show with detailed season information
      tvShow.seasons = detailedSeasons
    }

    return tvShow.toContent()
  }

  /// Fetches season details with episodes
  /// - Parameters:
  ///   - tvShowId: TV show ID
  ///   - seasonNumber: Season number
  /// - Returns: Season with episode details
  func fetchSeasonDetails(tvShowId: String, seasonNumber: Int) async throws -> Season {
    let endpoint = TMDBEndpoint.seasonDetails(tvShowId: tvShowId, seasonNumber: seasonNumber)
    let season: TMDBSeason = try await networkClient.request(endpoint)
    return season.toSeason()
  }

  /// Search for movies and TV shows using TMDB /search/multi
  /// - Parameters:
  ///   - query: Search query string
  ///   - page: Page number
  /// - Returns: TMDB paged response with mixed results
  func search(query: String, page: Int) async throws -> TMDBPagedResponse<TMDBMultiResult> {
    let endpoint = TMDBEndpoint.search(query: query, page: page)
    let response: TMDBPagedResponse<TMDBMultiResult> = try await networkClient.request(endpoint)
    return response
  }
}

/// Time window for trending content
enum TrendingTimeWindow: String {
  case day
  case week
}
