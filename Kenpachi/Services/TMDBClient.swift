//
//  TMDBClient.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

import Foundation
import ComposableArchitecture // To extend DependencyValues for TCA

// MARK: - TMDB API Client Interface

struct TMDBAPIClient {
    // TMDB Movie methods
    var fetchMovies: @Sendable (_ category: MovieCategory, _ page: Int) async throws -> PaginatedResponse<Movie>
    var fetchMovieDetails: @Sendable (_ id: Int) async throws -> MovieDetails

    // TMDB TV Show methods
    var fetchTVShows: @Sendable (_ category: TVShowCategory, _ page: Int) async throws -> PaginatedResponse<TVShow>
    var fetchTVShowDetails: @Sendable (_ id: Int) async throws -> TVShowDetails

    // Search methods
    var searchMulti: @Sendable (_ query: String, _ page: Int) async throws -> PaginatedResponse<Movie> // TMDB search returns mixed results, for simplicity, we'll decode to Movie for now
}

// MARK: - Live TMDB API Client Implementation

extension TMDBAPIClient: DependencyKey {
    static let liveValue = Self(
        fetchMovies: { category, page in
            let urlString = "\(Constants.tmdbBaseURL)/\(category.endpoint)?api_key=\(Constants.tmdbAPIKey)&page=\(page)"
            guard let url = URL(string: urlString) else {
                throw NetworkError.invalidURL
            }
            let networkService = NetworkService()
            return try await networkService.request(url: url)
        },
        fetchMovieDetails: { id in
            let urlString = "\(Constants.tmdbBaseURL)/movie/\(id)?api_key=\(Constants.tmdbAPIKey)"
            guard let url = URL(string: urlString) else {
                throw NetworkError.invalidURL
            }
            let networkService = NetworkService()
            return try await networkService.request(url: url)
        },
        fetchTVShows: { category, page in
            let urlString = "\(Constants.tmdbBaseURL)/\(category.endpoint)?api_key=\(Constants.tmdbAPIKey)&page=\(page)"
            guard let url = URL(string: urlString) else {
                throw NetworkError.invalidURL
            }
            let networkService = NetworkService()
            return try await networkService.request(url: url)
        },
        fetchTVShowDetails: { id in
            let urlString = "\(Constants.tmdbBaseURL)/tv/\(id)?api_key=\(Constants.tmdbAPIKey)"
            guard let url = URL(string: urlString) else {
                throw NetworkError.invalidURL
            }
            let networkService = NetworkService()
            return try await networkService.request(url: url)
        },
        searchMulti: { query, page in
            // For TMDB search/multi, it returns a mix of media types.
            // For simplicity, we are decoding it into PaginatedResponse<Movie> which might contain nulls
            // for fields specific to movies if a TV show is returned.
            // A more robust solution would be a `SearchMultiResult` enum.
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "\(Constants.tmdbBaseURL)/search/multi?api_key=\(Constants.tmdbAPIKey)&query=\(encodedQuery)&page=\(page)"
            guard let url = URL(string: urlString) else {
                throw NetworkError.invalidURL
            }
            let networkService = NetworkService()
            return try await networkService.request(url: url)
        }
    )

    // MARK: - Mock TMDB API Client Implementation (for testing and previews)

    static let testValue = Self(
        fetchMovies: { category, page in
            // Return some mock data for testing/previews
            return PaginatedResponse(
                page: page,
                results: [
                    Movie(id: 1, title: "Mock Movie 1", overview: "Overview 1", posterPath: "/mock1.jpg", backdropPath: "/mock1_backdrop.jpg", releaseDate: "2023-01-01", voteAverage: 7.5, genreIds: [28, 12]),
                    Movie(id: 2, title: "Mock Movie 2", overview: "Overview 2", posterPath: "/mock2.jpg", backdropPath: "/mock2_backdrop.jpg", releaseDate: "2023-02-01", voteAverage: 8.0, genreIds: [35])
                ],
                totalPages: 1,
                totalResults: 2
            )
        },
        fetchMovieDetails: { id in
            return MovieDetails(id: id, title: "Mock Movie Details \(id)", overview: "Detailed overview for mock movie \(id).", posterPath: "/mock_detail.jpg", backdropPath: "/mock_detail_backdrop.jpg", releaseDate: "2023-01-01", runtime: 120, voteAverage: 8.0, genres: [Genre(id: 28, name: "Action")], tagline: "A mock cinematic experience.", homepage: nil, imdbId: nil)
        },
        fetchTVShows: { category, page in
            return PaginatedResponse(
                page: page,
                results: [
                    TVShow(id: 101, name: "Mock TV Show 1", overview: "TV Overview 1", posterPath: "/mock_tv1.jpg", backdropPath: "/mock_tv1_backdrop.jpg", firstAirDate: "2022-03-15", voteAverage: 8.2, genreIds: [18, 10759]),
                    TVShow(id: 102, name: "Mock TV Show 2", overview: "TV Overview 2", posterPath: "/mock_tv2.jpg", backdropPath: "/mock_tv2_backdrop.jpg", firstAirDate: "2021-07-20", voteAverage: 7.9, genreIds: [80])
                ],
                totalPages: 1,
                totalResults: 2
            )
        },
        fetchTVShowDetails: { id in
            return TVShowDetails(id: id, name: "Mock TV Show Details \(id)", overview: "Detailed overview for mock TV show \(id).", posterPath: "/mock_tv_detail.jpg", backdropPath: "/mock_tv_detail_backdrop.jpg", firstAirDate: "2022-01-01", lastAirDate: "2022-12-31", numberOfEpisodes: 10, numberOfSeasons: 1, voteAverage: 8.5, genres: [Genre(id: 18, name: "Drama")], tagline: "A mock series.", homepage: nil, episodeRunTime: [45])
        },
        searchMulti: { query, page in
            return PaginatedResponse(
                page: page,
                results: [
                    Movie(id: 301, title: "Search Movie A for \(query)", overview: "Overview A", posterPath: "/search_mock1.jpg", backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 7.0, genreIds: nil),
                    Movie(id: 302, title: "Search Movie B for \(query)", overview: "Overview B", posterPath: "/search_mock2.jpg", backdropPath: nil, releaseDate: "2023-02-01", voteAverage: 6.5, genreIds: nil)
                ],
                totalPages: 1,
                totalResults: 2
            )
        }
    )

    // For previews, we might want custom data passed in
    static func previewValue(movies: [Movie] = [], tvShows: [TVShow] = []) -> Self {
        Self(
            fetchMovies: { _, page in
                PaginatedResponse(page: page, results: movies, totalPages: 1, totalResults: movies.count)
            },
            fetchMovieDetails: { id in
                try await TMDBAPIClient.testValue.fetchMovieDetails(id)
            },
            fetchTVShows: { _, page in
                PaginatedResponse(page: page, results: tvShows, totalPages: 1, totalResults: tvShows.count)
            },
            fetchTVShowDetails: { id in
                try await TMDBAPIClient.testValue.fetchTVShowDetails(id)
            },
            searchMulti: { query, page in
                try await TMDBAPIClient.testValue.searchMulti(query, page)
            }
        )
    }
}

// MARK: - Dependency Values Extension

extension DependencyValues {
    var tmdbAPIClient: TMDBAPIClient {
        get { self[TMDBAPIClient.self] }
        set { self[TMDBAPIClient.self] = newValue }
    }
}
