// WatchlistManager.swift
// Service for managing user watchlist
// Provides centralized watchlist operations

import Foundation

/// Manager for watchlist operations
final class WatchlistManager {
  /// Shared singleton instance
  static let shared = WatchlistManager()

  /// User repository
  private let userRepository: UserRepositoryProtocol
  /// Content repository
  private let contentRepository: ContentRepositoryProtocol

  /// Initializer with dependency injection
  init(
    userRepository: UserRepositoryProtocol = UserRepository.shared,
    contentRepository: ContentRepositoryProtocol = ContentRepository()
  ) {
    self.userRepository = userRepository
    self.contentRepository = contentRepository

    AppLogger.shared.log("WatchlistManager initialized", level: .debug)
  }

  // MARK: - Watchlist Operations

  /// Fetch watchlist entries for current scraper
  func fetchWatchlistEntries() async throws -> [WatchlistEntry] {
    let currentScraper = ScraperManager.shared.getActiveScraper()?.name ?? "Unknown"
    AppLogger.shared.log("Fetching watchlist for scraper: \(currentScraper)", level: .debug)

    let watchlist = try await userRepository.fetchWatchlist()
    let entries = watchlist.entriesForScraper(currentScraper)

    AppLogger.shared.log(
      "Fetched \(entries.count) watchlist items for \(currentScraper)",
      level: .debug
    )
    return entries
  }

  /// Fetch watchlist content with full details for current scraper
  func fetchWatchlistContent() async throws -> [Content] {
    let currentScraper = ScraperManager.shared.getActiveScraper()?.name ?? "Unknown"
    let entries = try await fetchWatchlistEntries()

    guard !entries.isEmpty else {
      AppLogger.shared.log("Watchlist is empty for \(currentScraper)", level: .debug)
      return []
    }

    /// Fetch full content details for each item
    var contents: [Content] = []
    for entry in entries {
      do {
        let content = try await contentRepository.fetchContentDetails(
          id: entry.contentId,
          type: entry.contentType
        )
        contents.append(content)
      } catch {
        AppLogger.shared.log(
          "Failed to fetch content \(entry.contentId): \(error.localizedDescription)",
          level: .warning
        )
      }
    }

    return contents
  }

  /// Add content to watchlist for current scraper
  func addToWatchlist(_ content: Content) async throws {
    let currentScraper = ScraperManager.shared.getActiveScraper()?.name ?? "Unknown"
    AppLogger.shared.log(
      "Adding content \(content.id) to watchlist for \(currentScraper)",
      level: .debug
    )

    try await userRepository.addToWatchlist(
      contentId: content.id,
      title: content.title,
      imageURL: content.fullPosterURL,
      contentType: content.type
    )

    AppLogger.shared.log(
      "Content \(content.id) added to watchlist for \(currentScraper)",
      level: .info
    )
  }

  /// Remove content from watchlist for current scraper
  func removeFromWatchlist(contentId: String, contentType: ContentType) async throws {
    let currentScraper = ScraperManager.shared.getActiveScraper()?.name ?? "Unknown"
    AppLogger.shared.log(
      "Removing content \(contentId) from watchlist for \(currentScraper)",
      level: .debug
    )

    try await userRepository.removeFromWatchlist(contentId: contentId, contentType: contentType)

    AppLogger.shared.log(
      "Content \(contentId) removed from watchlist for \(currentScraper)",
      level: .info
    )
  }

  /// Check if content is in watchlist
  func isInWatchlist(contentId: String, contentType: ContentType) async throws -> Bool {
    let isInWatchlist = try await userRepository.isInWatchlist(
      contentId: contentId, contentType: contentType)

    AppLogger.shared.log(
      "Content \(contentId) in watchlist: \(isInWatchlist)",
      level: .debug
    )

    return isInWatchlist
  }

  /// Toggle watchlist status
  func toggleWatchlist(contentId: String, contentType: ContentType) async throws -> Bool {
    let isInWatchlist = try await isInWatchlist(contentId: contentId, contentType: contentType)

    if isInWatchlist {
      try await removeFromWatchlist(contentId: contentId, contentType: contentType)
      return false
    } else {
      // First fetch content details to get full information
      //let content = try await contentRepository.fetchContentDetails(contentId: contentId, contentType: contentType)
      let content = try await contentRepository.fetchContentDetails(
        id: contentId, type: contentType)
      try await addToWatchlist(content)
      return true
    }
  }

  /// Get watchlist count
  func getWatchlistCount() async throws -> Int {
    let watchlist = try await userRepository.fetchWatchlist()
    return watchlist.count
  }
}
