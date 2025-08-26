import Foundation

struct AppConstants {
    
    // MARK: - App Info
    struct App {
        static let name = "Kenpachi"
        static let version = "1.0.0"
        static let buildNumber = "1"
        static let bundleIdentifier = "com.kenpachi.streaming"
    }
    
    // MARK: - UI Constants
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let cardSpacing: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 16
        
        // Animation Durations
        static let shortAnimationDuration: Double = 0.2
        static let mediumAnimationDuration: Double = 0.3
        static let longAnimationDuration: Double = 0.5
        
        // Content Dimensions
        static let posterAspectRatio: CGFloat = 2.0/3.0
        static let backdropAspectRatio: CGFloat = 16.0/9.0
        static let cardWidth: CGFloat = 120
        static let cardHeight: CGFloat = 180
    }
    
    // MARK: - Content Limits
    struct Content {
        static let maxRecentSearches = 10
        static let maxWatchlistItems = 500
        static let maxDownloads = 100
        static let maxContinueWatching = 20
        static let searchResultsPerPage = 20
        static let homeContentSections = 6
    }
    
    // MARK: - Download Settings
    struct Downloads {
        static let maxConcurrentDownloads = 3
        static let downloadTimeoutInterval: TimeInterval = 30
        static let maxRetryAttempts = 3
        static let downloadExpiryDays = 30
        static let minFreeSpaceGB: Int64 = 1 // 1GB minimum free space
    }
    
    // MARK: - Streaming Settings
    struct Streaming {
        static let bufferDuration: TimeInterval = 10
        static let maxBufferDuration: TimeInterval = 30
        static let connectionTimeoutInterval: TimeInterval = 15
        static let readTimeoutInterval: TimeInterval = 30
        static let maxRetryAttempts = 5
        static let retryDelay: TimeInterval = 2
    }
    
    // MARK: - Cache Settings
    struct Cache {
        static let imageCacheMaxSize: Int64 = 100 * 1024 * 1024 // 100MB
        static let imageCacheMaxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        static let metadataCacheMaxAge: TimeInterval = 24 * 60 * 60 // 24 hours
        static let searchCacheMaxAge: TimeInterval = 60 * 60 // 1 hour
    }
    
    // MARK: - User Defaults Keys
    struct UserDefaultsKeys {
        static let selectedQuality = "selectedQuality"
        static let autoplayEnabled = "autoplayEnabled"
        static let downloadOnlyOnWiFi = "downloadOnlyOnWiFi"
        static let skipIntros = "skipIntros"
        static let subtitlesEnabled = "subtitlesEnabled"
        static let preferredLanguage = "preferredLanguage"
        static let lastSelectedProfile = "lastSelectedProfile"
        static let recentSearches = "recentSearches"
        static let watchHistory = "watchHistory"
        static let continueWatching = "continueWatching"
    }
    
    // MARK: - Notification Names
    struct Notifications {
        static let downloadStarted = "downloadStarted"
        static let downloadCompleted = "downloadCompleted"
        static let downloadFailed = "downloadFailed"
        static let playbackStarted = "playbackStarted"
        static let playbackEnded = "playbackEnded"
        static let networkStatusChanged = "networkStatusChanged"
        static let userProfileChanged = "userProfileChanged"
    }
    
    // MARK: - Error Codes
    struct ErrorCodes {
        static let networkError = "NETWORK_ERROR"
        static let contentNotFound = "CONTENT_NOT_FOUND"
        static let downloadError = "DOWNLOAD_ERROR"
        static let playbackError = "PLAYBACK_ERROR"
        static let storageError = "STORAGE_ERROR"
        static let subscriptionError = "SUBSCRIPTION_ERROR"
    }
    
    // MARK: - File Extensions
    struct FileExtensions {
        static let video = ["mp4", "mkv", "avi", "mov", "m4v"]
        static let subtitle = ["srt", "vtt", "ass", "ssa", "sub"]
        static let image = ["jpg", "jpeg", "png", "webp"]
    }
    
    // MARK: - MIME Types
    struct MimeTypes {
        static let mp4 = "video/mp4"
        static let hls = "application/x-mpegURL"
        static let dash = "application/dash+xml"
        static let srt = "text/srt"
        static let vtt = "text/vtt"
        static let jpeg = "image/jpeg"
        static let png = "image/png"
    }
    
    // MARK: - Quality Presets
    struct QualityPresets {
        static let auto = StreamingQuality.auto
        static let low = StreamingQuality.sd360
        static let medium = StreamingQuality.sd480
        static let high = StreamingQuality.hd720
        static let veryHigh = StreamingQuality.hd1080
        static let ultra = StreamingQuality.uhd4k
    }
    
    // MARK: - Subscription Limits
    struct SubscriptionLimits {
        static let freeMaxProfiles = 1
        static let freeMaxDownloads = 0
        static let freeMaxQuality = StreamingQuality.hd720
        
        static let premiumMaxProfiles = 3
        static let premiumMaxDownloads = 50
        static let premiumMaxQuality = StreamingQuality.uhd4k
        
        static let familyMaxProfiles = 6
        static let familyMaxDownloads = 100
        static let familyMaxQuality = StreamingQuality.uhd4k
    }
}