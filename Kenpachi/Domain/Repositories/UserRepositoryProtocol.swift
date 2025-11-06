// UserRepositoryProtocol.swift
// Protocol defining user repository interface
// Abstracts user data access and management

import Foundation

/// Protocol for user repository operations
protocol UserRepositoryProtocol {
  /// Fetch user profile
  func fetchUserProfile() async throws -> UserProfile?

  /// Update user profile
  func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile

  /// Fetch watchlist
  func fetchWatchlist() async throws -> Watchlist

  /// Add content to watchlist
  func addToWatchlist(
    contentId: String,
    title: String,
    imageURL: URL?,
    contentType: ContentType
  ) async throws

  /// Remove from watchlist
  func removeFromWatchlist(contentId: String, contentType: ContentType) async throws

  /// Check if content is in watchlist for current scraper
  func isInWatchlist(contentId: String, contentType: ContentType) async throws -> Bool

  /// Clear watchlist for the current scraper
  func clearWatchlist() async throws

  /// Fetch watch history
  func fetchWatchHistory() async throws -> WatchHistory

  /// Update watch history entry
  func updateWatchHistoryEntry(_ entry: WatchHistoryEntry) async throws

  /// Remove watch history entry
  func removeWatchHistoryEntry(contentId: String, contentType: ContentType) async throws

  /// Clear watch history
  func clearWatchHistory() async throws

  /// Get user statistics
  func getUserStatistics() async throws -> (
    watchTime: TimeInterval, contentCount: Int, favoriteGenres: [String]
  )

  /// Fetch user preferences
  func fetchUserPreferences() async throws -> UserPreferences

  /// Update user preferences
  func updateUserPreferences(_ preferences: UserPreferences) async throws

  /// Fetch app state
  func fetchAppState() async throws -> AppState

  /// Update app state
  func updateAppState(_ state: AppState) async throws
}
