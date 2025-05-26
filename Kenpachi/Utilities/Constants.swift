//
//  Constants.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

import Foundation
import SwiftUI // Import SwiftUI to use Color

/// A centralized structure for all application-wide constants.
enum Constants {

    // MARK: - API Keys & Endpoints

    /// The API key for The Movie Database (TMDB).
    ///
    /// **IMPORTANT:** Replace "YOUR_TMDB_API_KEY" with your actual TMDB API key.
    /// You can obtain one by signing up at themoviedb.org.
    static let tmdbAPIKey = "YOUR_TMDB_API_KEY"

    /// The base URL for the TMDB API.
    static let tmdbBaseURL = "https://api.themoviedb.org/3"

    /// The base URL for TMDB image assets (posters, backdrops).
    /// `w500` indicates a common width for displaying images.
    static let tmdbImageBaseURL = "https://image.tmdb.org/t/p/w500"

    /// The GraphQL endpoint for the AniList API.
    static let aniListGraphQLURL = "https://graphql.anilist.co"

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

    // MARK: - Theme Colors

    /// Defines the primary color palette for the app.
    /// This can be extended later for full Light/Dark mode support.
    enum Theme {
        /// The main background color for most screens (dark grey).
        static let backgroundColor = Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 1.0) // A very dark grey
        // For a slightly lighter dark gray, you could use:
        // static let backgroundColor = Color(red: 0.15, green: 0.15, blue: 0.15, opacity: 1.0)

        /// The primary foreground color for text and icons (white).
        static let primaryTextColor = Color.white

        /// Accent color for highlights, buttons, and loading indicators (JioHotstar red).
        static let accentColor = Color(red: 0.8, green: 0.1, blue: 0.15, opacity: 1.0) // A distinct red
    }
}
