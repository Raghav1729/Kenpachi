import Foundation

struct UserProfile: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let avatarURL: String?
    let avatarColor: String
    let isKidsProfile: Bool
    let ageRating: AgeRating
    let createdAt: Date
    let lastUsedAt: Date?
    
    // Profile specific data
    let watchlist: [String] // Content IDs
    let watchHistory: [WatchHistoryItem]
    let favorites: [String] // Content IDs
    let downloadedContent: [String] // Content IDs
    let continueWatching: [ContinueWatchingItem]
    
    // Preferences
    let preferredLanguages: [String]
    let autoplayNext: Bool
    let skipIntros: Bool
    let downloadQuality: StreamingQuality
    let streamingQuality: StreamingQuality
    let subtitlePreferences: SubtitlePreferences
}

enum AgeRating: String, Codable, CaseIterable {
    case kids = "kids" // Under 7
    case family = "family" // 7-12
    case teen = "teen" // 13-17
    case adult = "adult" // 18+
    
    var displayName: String {
        switch self {
        case .kids: return "Kids (Under 7)"
        case .family: return "Family (7-12)"
        case .teen: return "Teen (13-17)"
        case .adult: return "Adult (18+)"
        }
    }
    
    var maxContentRating: String {
        switch self {
        case .kids: return "G"
        case .family: return "PG"
        case .teen: return "PG-13"
        case .adult: return "R"
        }
    }
    
    var allowedGenres: [String] {
        switch self {
        case .kids:
            return ["Animation", "Family", "Comedy"]
        case .family:
            return ["Animation", "Family", "Comedy", "Adventure", "Fantasy"]
        case .teen:
            return ["Animation", "Family", "Comedy", "Adventure", "Fantasy", "Action", "Sci-Fi", "Romance"]
        case .adult:
            return [] // All genres allowed
        }
    }
}

struct WatchHistoryItem: Identifiable, Codable, Equatable {
    let id: String
    let contentId: String
    let contentType: ContentType
    let watchedAt: Date
    let watchDuration: TimeInterval
    let totalDuration: TimeInterval
    let episodeId: String? // For TV shows
    let seasonNumber: Int? // For TV shows
    let episodeNumber: Int? // For TV shows
    
    init(
        id: String = UUID().uuidString,
        contentId: String,
        contentType: ContentType,
        watchedAt: Date,
        watchDuration: TimeInterval,
        totalDuration: TimeInterval,
        episodeId: String? = nil,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil
    ) {
        self.id = id
        self.contentId = contentId
        self.contentType = contentType
        self.watchedAt = watchedAt
        self.watchDuration = watchDuration
        self.totalDuration = totalDuration
        self.episodeId = episodeId
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
    }
    
    var progressPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return min(watchDuration / totalDuration, 1.0)
    }
    
    var isCompleted: Bool {
        progressPercentage >= 0.9 // Consider 90% as completed
    }
}

struct ContinueWatchingItem: Identifiable, Codable, Equatable {
    let id: String
    let contentId: String
    let contentType: ContentType
    let lastWatchedAt: Date
    let watchProgress: TimeInterval
    let totalDuration: TimeInterval
    let episodeId: String? // For TV shows
    let seasonNumber: Int? // For TV shows
    let episodeNumber: Int? // For TV shows
    let nextEpisodeId: String? // For TV shows
    
    init(
        id: String = UUID().uuidString,
        contentId: String,
        contentType: ContentType,
        lastWatchedAt: Date,
        watchProgress: TimeInterval,
        totalDuration: TimeInterval,
        episodeId: String? = nil,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil,
        nextEpisodeId: String? = nil
    ) {
        self.id = id
        self.contentId = contentId
        self.contentType = contentType
        self.lastWatchedAt = lastWatchedAt
        self.watchProgress = watchProgress
        self.totalDuration = totalDuration
        self.episodeId = episodeId
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.nextEpisodeId = nextEpisodeId
    }
    
    var progressPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return min(watchProgress / totalDuration, 1.0)
    }
    
    var shouldShowInContinueWatching: Bool {
        let daysSinceLastWatch = Date().timeIntervalSince(lastWatchedAt) / 86400
        return daysSinceLastWatch <= 30 && progressPercentage > 0.05 && progressPercentage < 0.9
    }
}

struct SubtitlePreferences: Codable, Equatable {
    let preferredLanguages: [String] // Language codes
    let fontSize: SubtitleFontSize
    let fontColor: String
    let backgroundColor: String
    let backgroundOpacity: Double
    let fontFamily: String
    let isEnabled: Bool
    let showForForeignLanguage: Bool
}

enum SubtitleFontSize: String, Codable, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
    
    var scaleFactor: Double {
        switch self {
        case .small: return 0.8
        case .medium: return 1.0
        case .large: return 1.2
        case .extraLarge: return 1.5
        }
    }
}

// MARK: - Extensions
extension UserProfile {
    var watchlistCount: Int {
        watchlist.count
    }
    
    var favoritesCount: Int {
        favorites.count
    }
    
    var downloadedCount: Int {
        downloadedContent.count
    }
    
    var continueWatchingCount: Int {
        continueWatching.filter { $0.shouldShowInContinueWatching }.count
    }
    
    var totalWatchTime: TimeInterval {
        watchHistory.reduce(0) { $0 + $1.watchDuration }
    }
    
    var formattedWatchTime: String {
        let hours = Int(totalWatchTime) / 3600
        return "\(hours) hours"
    }
    
    func isInWatchlist(_ contentId: String) -> Bool {
        watchlist.contains(contentId)
    }
    
    func isFavorite(_ contentId: String) -> Bool {
        favorites.contains(contentId)
    }
    
    func isDownloaded(_ contentId: String) -> Bool {
        downloadedContent.contains(contentId)
    }
}

// MARK: - Sample Data
extension UserProfile {
    static let sample = UserProfile(
        id: "profile_1",
        name: "[name]",
        avatarURL: nil,
        avatarColor: "#FF6B6B",
        isKidsProfile: false,
        ageRating: .adult,
        createdAt: Date().addingTimeInterval(-86400 * 30),
        lastUsedAt: Date(),
        watchlist: ["1", "2", "3"],
        watchHistory: [],
        favorites: ["1", "4"],
        downloadedContent: ["2"],
        continueWatching: [],
        preferredLanguages: ["en", "es"],
        autoplayNext: true,
        skipIntros: true,
        downloadQuality: .hd1080,
        streamingQuality: .auto,
        subtitlePreferences: SubtitlePreferences(
            preferredLanguages: ["en"],
            fontSize: .medium,
            fontColor: "#FFFFFF",
            backgroundColor: "#000000",
            backgroundOpacity: 0.7,
            fontFamily: "System",
            isEnabled: false,
            showForForeignLanguage: true
        )
    )
}