//
//  Constants.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

import Foundation

/// A centralized structure for all application-wide constants.
enum Constants {

    // MARK: - API Keys & Endpoints

    /// The API key for The Movie Database (TMDB).
    ///
    /// **IMPORTANT:** Replace "YOUR_TMDB_API_KEY" with your actual TMDB API key.
    /// You can obtain one by signing up at themoviedb.org.
    static let tmdbAPIKey = "7915349ed68b69af11002f5ea38aa8c6"

    /// The base URL for the TMDB API.
    static let tmdbBaseURL = "https://api.themoviedb.org/3"

    /// The base URL for TMDB image assets (posters, backdrops).
    /// `w500` indicates a common width for displaying images.
    static let tmdbImageBaseURL = "https://image.tmdb.org/t/p/w500"

    /// The GraphQL endpoint for the AniList API.
    static let aniListGraphQLURL = "https://graphql.anilist.co"

    // AniList Client ID and Secret are typically used for OAuth flows,
    // which might not be strictly necessary for basic data fetching but are included
    // as placeholders if advanced authenticated queries are needed.
    // static let aniListClientID = "YOUR_ANILIST_CLIENT_ID"
    // static let aniListClientSecret = "YOUR_ANILIST_CLIENT_SECRET"

    // MARK: - App Configuration

    /// The display name of the application.
    static let appName = "Kenpachi"

    /// The duration for the splash screen animation or display.
    static let splashScreenDuration: TimeInterval = 2.0

    // MARK: - Cache & Storage Keys

    /// Keys used for local caching mechanisms (e.g., UserDefaults, CoreData, file system).
    enum CacheKeys {
        static let movies = "cachedMovies"
        static let tvShows = "cachedTVShows"
        static let anime = "cachedAnime"
        static let manga = "cachedManga"
        // Add more as needed for different data types to be cached
    }

    // MARK: - Notification Identifiers

    /// Identifiers for local and push notifications.
    enum NotificationIdentifiers {
        static let newContent = "newContentNotification"
        static let downloadComplete = "downloadCompleteNotification"
        // Add more as needed for different notification types
    }

    // MARK: - UI Constants

    /// Common padding values for UI elements.
    enum UI {
        static let defaultPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
    }
}
