// UserRepository.swift
// Implementation of user repository
// Manages user data persistence and operations

import Foundation

/// Repository for managing user data
final class UserRepository: UserRepositoryProtocol {
  /// Shared singleton instance
  static let shared = UserRepository()

  /// UserDefaults key for user profile
  private let profileKey = "user_profile"
  /// UserDefaults key for watchlist
  private let watchlistKey = "user_watchlist"
  /// UserDefaults key for watch history
  private let watchHistoryKey = "user_watch_history"
  /// UserDefaults key for user preferences
  private let preferencesKey = "user_preferences"
  /// UserDefaults key for app state
  private let appStateKey = "app_state"

  /// UserDefaults instance
  private let userDefaults: UserDefaults

  /// JSON encoder
  private let encoder = JSONEncoder()
  /// JSON decoder
  private let decoder = JSONDecoder()

  /// Private initializer for singleton
  private init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  // MARK: - User Profile

  /// Fetch user profile
  func fetchUserProfile() async throws -> UserProfile? {
    guard let data = userDefaults.data(forKey: profileKey) else { return nil }
    return try decoder.decode(UserProfile.self, from: data)
  }

  /// Update user profile
  func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
    let data = try encoder.encode(profile)
    userDefaults.set(data, forKey: profileKey)
    return profile
  }

  // MARK: - Watchlist

  /// Fetch watchlist for current scraper (filtered view)
  func fetchWatchlist() async throws -> Watchlist {
    let currentScraper = ScraperManager.shared.getActiveScraper()?.name ?? "default"
    let scraperKey = "\(watchlistKey)"

    if let data = userDefaults.data(forKey: scraperKey),
      let watchlist = try? decoder.decode(Watchlist.self, from: data)
    {
      /// Filter entries to only include those from the current scraper
      let filteredEntries = watchlist.entriesForScraper(currentScraper)

      AppLogger.shared.log(
        "Fetched watchlist for scraper \(currentScraper): \(filteredEntries.count) items",
        level: .debug
      )

      /// Return a new watchlist with filtered entries, preserving the original
      return Watchlist(
        id: watchlist.id,
        userId: watchlist.userId,
        entries: filteredEntries,
        createdAt: watchlist.createdAt,
        updatedAt: watchlist.updatedAt
      )
    }

    /// Return empty watchlist if none exists
    AppLogger.shared.log(
      "No watchlist found, creating new empty watchlist for scraper \(currentScraper)",
      level: .debug
    )
    return Watchlist(userId: "default-user")
  }

  /// Fetch full watchlist (all scrapers) - internal use only
  private func fetchFullWatchlist() async throws -> Watchlist {
    let scraperKey = "\(watchlistKey)"

    if let data = userDefaults.data(forKey: scraperKey),
      let watchlist = try? decoder.decode(Watchlist.self, from: data)
    {
      return watchlist
    }

    /// Return empty watchlist if none exists
    return Watchlist(userId: "default-user")
  }

  /// Add content to watchlist
  func addToWatchlist(
    contentId: String,
    title: String,
    imageURL: URL?,
    contentType: ContentType
  ) async throws {
    let currentScraper = ScraperManager.shared.getActiveScraper()?.name ?? "default"
    let scraperKey = "\(watchlistKey)"

    /// Fetch full watchlist to preserve entries from other scrapers
    var watchlist = try await fetchFullWatchlist()

    /// Check if content already exists in watchlist
    if watchlist.contains(
      contentId: contentId, scraperSource: currentScraper, contentType: contentType)
    {
      AppLogger.shared.log(
        "Content \(contentId) already exists in watchlist for scraper \(currentScraper)",
        level: .debug
      )
      return
    }

    /// Add content to watchlist
    watchlist.add(
      contentId: contentId,
      scraperSource: currentScraper,
      title: title,
      fullPosterURL: imageURL,
      contentType: contentType
    )

    /// Save updated watchlist
    let data = try encoder.encode(watchlist)
    userDefaults.set(data, forKey: scraperKey)

    AppLogger.shared.log(
      "Added content \(contentId) to watchlist for scraper \(currentScraper)",
      level: .info
    )
  }

  /// Remove from watchlist
  func removeFromWatchlist(contentId: String, contentType: ContentType) async throws {
    let currentScraper = ScraperManager.shared.getActiveScraper()?.name ?? "default"
    let scraperKey = "\(watchlistKey)"

    /// Fetch full watchlist to preserve entries from other scrapers
    var watchlist = try await fetchFullWatchlist()
    watchlist.remove(contentId: contentId, scraperSource: currentScraper, contentType: contentType)

    /// Save updated watchlist
    let data = try encoder.encode(watchlist)
    userDefaults.set(data, forKey: scraperKey)

    AppLogger.shared.log(
      "Removed content \(contentId) from watchlist for scraper \(currentScraper)",
      level: .info
    )
  }

  /// Check if content is in watchlist for current scraper
  func isInWatchlist(contentId: String, contentType: ContentType) async throws -> Bool {
    let currentScraper = ScraperManager.shared.getActiveScraper()?.name ?? "default"
    let watchlist = try await fetchWatchlist()
    return watchlist.contains(
      contentId: contentId, scraperSource: currentScraper, contentType: contentType)
  }

  // MARK: - Watch History

  /// Fetch watch history
  func fetchWatchHistory() async throws -> WatchHistory {
    let currentScraper = ScraperManager.shared.getActiveScraper()?.name ?? "FlixHQ"

    if let data = userDefaults.data(forKey: watchHistoryKey),
      let history = try? decoder.decode(WatchHistory.self, from: data)
    {
      // Filter entries to only include those from the current scraper
      let filteredEntries = history.entries.filter { entry in
        entry.scraperSource == currentScraper && entry.isInProgress
      }

      // Return history with filtered entries
      return WatchHistory(
        id: history.id,
        userId: history.userId,
        entries: filteredEntries,
        createdAt: history.createdAt,
        updatedAt: history.updatedAt
      )
    }
    /// Return empty history if none exists
    return WatchHistory(userId: "default-user")
  }

  /// Update watch history entry
  func updateWatchHistoryEntry(_ entry: WatchHistoryEntry) async throws {
    var history = try await fetchWatchHistory()

    // Check if an entry with matching contentId, seasonId, and episodeId already exists
    if let existingIndex = history.entries.firstIndex(where: { existingEntry in
      existingEntry.contentId == entry.contentId && existingEntry.seasonId == entry.seasonId
        && existingEntry.episodeId == entry.episodeId
    }) {
      // Update the existing entry
      history.entries[existingIndex] = entry
    } else {
      // Insert new entry
      history.entries.append(entry)
    }

    history.updatedAt = Date()
    let data = try encoder.encode(history)
    userDefaults.set(data, forKey: watchHistoryKey)
  }

  /// Remove watch history entry
  func removeWatchHistoryEntry(id: String) async throws {
    var history = try await fetchWatchHistory()
    history.removeEntry(id)
    let data = try encoder.encode(history)
    userDefaults.set(data, forKey: watchHistoryKey)
  }

  /// Clear watch history
  func clearWatchHistory() async throws {
    var history = try await fetchWatchHistory()
    history.clear()
    let data = try encoder.encode(history)
    userDefaults.set(data, forKey: watchHistoryKey)
  }

  // MARK: - Statistics

  /// Get user statistics
  func getUserStatistics() async throws -> (
    watchTime: TimeInterval, contentCount: Int, favoriteGenres: [String]
  ) {
    let history = try await fetchWatchHistory()

    /// Calculate total watch time
    let watchTime = history.totalWatchTime

    /// Count unique content watched
    let uniqueContentIds = Set(history.entries.map { $0.contentId })
    let contentCount = uniqueContentIds.count

    /// TODO: Calculate favorite genres from watch history
    /// For now, return empty array
    let favoriteGenres: [String] = []

    return (watchTime, contentCount, favoriteGenres)
  }

  // MARK: - User Preferences

  /// Fetch user preferences
  func fetchUserPreferences() async throws -> UserPreferences {
    if let data = userDefaults.data(forKey: preferencesKey),
      let preferences = try? decoder.decode(UserPreferences.self, from: data)
    {
      return preferences
    }
    /// Return default preferences if none exist
    return UserPreferences()
  }

  /// Update user preferences
  func updateUserPreferences(_ preferences: UserPreferences) async throws {
    let data = try encoder.encode(preferences)
    userDefaults.set(data, forKey: preferencesKey)
  }

  // MARK: - App State

  /// Fetch app state
  func fetchAppState() async throws -> AppState {
    if let data = userDefaults.data(forKey: appStateKey),
      let state = try? decoder.decode(AppState.self, from: data)
    {
      return state
    }
    /// Return default state if none exists
    return AppState()
  }

  /// Update app state
  func updateAppState(_ state: AppState) async throws {
    let data = try encoder.encode(state)
    userDefaults.set(data, forKey: appStateKey)
  }
}
