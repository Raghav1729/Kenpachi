//
//  TMDBModels.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

import Foundation

// MARK: - Common TMDB Structures

/// A generic paginated response from TMDB APIs.
struct PaginatedResponse<T: Decodable>: Decodable {
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

/// Represents a genre (e.g., Action, Drama).
struct Genre: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
}

// MARK: - Movie Models

/// Represents a simplified movie preview, suitable for lists.
struct Movie: Decodable, Identifiable, Hashable, Equatable {
    let id: Int
    let title: String? // Title can be null for some obscure entries
    let overview: String?
    let posterPath: String? // Relative path to image
    let backdropPath: String? // Relative path to image
    let releaseDate: String? // YYYY-MM-DD
    let voteAverage: Double?
    let genreIds: [Int]? // List of genre IDs

    var fullPosterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: Constants.tmdbImageBaseURL + posterPath)
    }

    var fullBackdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: Constants.tmdbImageBaseURL + backdropPath)
    }

    // Custom CodingKeys if needed for specific fields
    // enum CodingKeys: String, CodingKey { ... }
}

/// Represents detailed information for a single movie.
struct MovieDetails: Decodable, Identifiable, Hashable, Equatable {
    let id: Int
    let title: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let runtime: Int? // In minutes
    let voteAverage: Double?
    let genres: [Genre]?
    let tagline: String?
    let homepage: String? // URL
    let imdbId: String? // IMDb ID

    var fullPosterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: Constants.tmdbImageBaseURL + posterPath)
    }

    var fullBackdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: Constants.tmdbImageBaseURL + backdropPath)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, genres, tagline, homepage
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case imdbId = "imdb_id"
    }
}

// Helper for TMDB Movie categories
enum MovieCategory: String, CaseIterable, Identifiable {
    case popular = "Popular"
    case nowPlaying = "Now Playing"
    case topRated = "Top Rated"
    case upcoming = "Upcoming"

    var id: String { self.rawValue }
    var endpoint: String {
        switch self {
        case .popular: return "movie/popular"
        case .nowPlaying: return "movie/now_playing"
        case .topRated: return "movie/top_rated"
        case .upcoming: return "movie/upcoming"
        }
    }
}

// MARK: - TV Show Models

/// Represents a simplified TV show preview, suitable for lists.
struct TVShow: Decodable, Identifiable, Hashable, Equatable {
    let id: Int
    let name: String? // TV shows use 'name' instead of 'title'
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String? // YYYY-MM-DD
    let voteAverage: Double?
    let genreIds: [Int]?

    var fullPosterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: Constants.tmdbImageBaseURL + posterPath)
    }

    var fullBackdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: Constants.tmdbImageBaseURL + backdropPath)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case genreIds = "genre_ids"
    }
}

/// Represents detailed information for a single TV show.
struct TVShowDetails: Decodable, Identifiable, Hashable, Equatable {
    let id: Int
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let lastAirDate: String?
    let numberOfEpisodes: Int?
    let numberOfSeasons: Int?
    let voteAverage: Double?
    let genres: [Genre]?
    let tagline: String?
    let homepage: String?
    let episodeRunTime: [Int]? // Typically 1 element array for average run time

    var fullPosterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: Constants.tmdbImageBaseURL + posterPath)
    }

    var fullBackdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: Constants.tmdbImageBaseURL + backdropPath)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, overview, genres, tagline, homepage
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case lastAirDate = "last_air_date"
        case numberOfEpisodes = "number_of_episodes"
        case numberOfSeasons = "number_of_seasons"
        case voteAverage = "vote_average"
        case episodeRunTime = "episode_run_time"
    }
}

// Helper for TMDB TV Show categories
enum TVShowCategory: String, CaseIterable, Identifiable {
    case popular = "Popular"
    case airingToday = "Airing Today"
    case topRated = "Top Rated"
    case onTheAir = "On The Air" // Currently airing
    var id: String { self.rawValue }
    var endpoint: String {
        switch self {
        case .popular: return "tv/popular"
        case .airingToday: return "tv/airing_today"
        case .topRated: return "tv/top_rated"
        case .onTheAir: return "tv/on_the_air"
        }
    }
}
