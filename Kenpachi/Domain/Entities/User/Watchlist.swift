// Watchlist.swift
// Domain entity representing a user's watchlist
// Contains content items saved for later viewing

import Foundation

/// Represents an entry in the watchlist
struct WatchlistEntry: Equatable, Identifiable, Codable {
  /// Unique identifier for the entry
  let id: String
  /// Content ID from the scraper
  let contentId: String
  /// Scraper source name (e.g., "FlixHQ", "VidFast")
  let scraperSource: String
  /// Title of the content
  let title: String
  /// Full poster URL for the content
  let fullPosterURL: URL?
  /// Type of content (movie/show)
  let contentType: ContentType
  /// Date when entry was added
  let addedAt: Date

  init(
    id: String = UUID().uuidString,
    contentId: String,
    scraperSource: String,
    title: String,
    fullPosterURL: URL?,
    contentType: ContentType,
    addedAt: Date = Date()
  ) {
    self.id = id
    self.contentId = contentId
    self.scraperSource = scraperSource
    self.title = title
    self.fullPosterURL = fullPosterURL
    self.contentType = contentType
    self.addedAt = addedAt
  }
}

/// Represents a user's watchlist with saved content
struct Watchlist: Equatable, Identifiable, Codable {
  /// Unique identifier for the watchlist
  let id: String
  /// User ID who owns the watchlist
  let userId: String
  /// List of entries in the watchlist
  var entries: [WatchlistEntry]
  /// Date when watchlist was created
  let createdAt: Date
  /// Date when watchlist was last updated
  var updatedAt: Date

  /// Initializer
  init(
    id: String = UUID().uuidString,
    userId: String,
    entries: [WatchlistEntry] = [],
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.userId = userId
    self.entries = entries
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  /// Number of items in watchlist
  var count: Int {
    entries.count
  }

  /// Whether watchlist is empty
  var isEmpty: Bool {
    entries.isEmpty
  }

  /// Check if content is in watchlist
  func contains(_ contentId: String) -> Bool {
    entries.contains { $0.contentId == contentId }
  }

  /// Check if content from specific scraper and type is in watchlist
  func contains(contentId: String, scraperSource: String, contentType: ContentType) -> Bool {
    entries.contains {
      $0.contentId == contentId && $0.scraperSource == scraperSource && $0.contentType == contentType
    }
  }

  /// Add content to watchlist
  mutating func add(
    contentId: String,
    scraperSource: String,
    title: String,
    fullPosterURL: URL?,
    contentType: ContentType
  ) {
    guard !contains(contentId: contentId, scraperSource: scraperSource, contentType: contentType) else { return }
    let entry = WatchlistEntry(
      contentId: contentId,
      scraperSource: scraperSource,
      title: title,
      fullPosterURL: fullPosterURL,
      contentType: contentType
    )
    entries.append(entry)
    updatedAt = Date()
  }

  /// Remove content from watchlist
  mutating func remove(contentId: String, scraperSource: String, contentType: ContentType) {
    entries.removeAll {
      $0.contentId == contentId && $0.scraperSource == scraperSource && $0.contentType == contentType
    }
    updatedAt = Date()
  }

  /// Get watchlist entries for a specific scraper
  func entriesForScraper(_ scraperSource: String) -> [WatchlistEntry] {
    entries.filter { $0.scraperSource == scraperSource }
  }
}
