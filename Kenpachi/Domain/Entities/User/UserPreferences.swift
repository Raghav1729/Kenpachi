import Foundation

struct UserPreferences: Codable, Equatable {
    // Playback preferences
    let autoplay: Bool
    let autoplayTrailers: Bool
    let skipIntros: Bool
    let skipCredits: Bool
    let defaultAudioLanguage: String
    let defaultSubtitleLanguage: String?
    let subtitlesEnabled: Bool
    
    // Quality preferences
    let preferredStreamingQuality: StreamingQuality
    let preferredDownloadQuality: StreamingQuality
    let adaptiveStreaming: Bool
    let dataSaverMode: Bool
    
    // Interface preferences
    let theme: UserTheme
    let language: String
    let region: String
    let timeFormat: TimeFormat
    let dateFormat: DateFormat
    
    // Notification preferences
    let pushNotificationsEnabled: Bool
    let emailNotificationsEnabled: Bool
    let newContentNotifications: Bool
    let watchlistNotifications: Bool
    let downloadNotifications: Bool
    
    // Privacy preferences
    let shareWatchHistory: Bool
    let allowRecommendations: Bool
    let allowAnalytics: Bool
    let parentalControlsEnabled: Bool
    let parentalControlsPIN: String?
    
    // Download preferences
    let downloadOnlyOnWiFi: Bool
    let autoDownloadWatchlist: Bool
    let maxConcurrentDownloads: Int
    let downloadLocation: DownloadLocation
    let deleteWatchedDownloads: Bool
    
    // Accessibility preferences
    let voiceOverEnabled: Bool
    let highContrastMode: Bool
    let reducedMotion: Bool
    let largeText: Bool
    let audioDescriptions: Bool
}

enum UserTheme: String, Codable, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum TimeFormat: String, Codable, CaseIterable {
    case twelveHour = "12"
    case twentyFourHour = "24"
    
    var displayName: String {
        switch self {
        case .twelveHour: return "12-hour"
        case .twentyFourHour: return "24-hour"
        }
    }
}

enum DateFormat: String, Codable, CaseIterable {
    case mmddyyyy = "MM/dd/yyyy"
    case ddmmyyyy = "dd/MM/yyyy"
    case yyyymmdd = "yyyy-MM-dd"
    
    var displayName: String {
        switch self {
        case .mmddyyyy: return "MM/dd/yyyy"
        case .ddmmyyyy: return "dd/MM/yyyy"
        case .yyyymmdd: return "yyyy-MM-dd"
        }
    }
}

enum DownloadLocation: String, Codable, CaseIterable {
    case internalStorage = "internal"
    case external = "external"
    case icloud = "icloud"
    
    var displayName: String {
        switch self {
        case .internalStorage: return "Internal Storage"
        case .external: return "External Storage"
        case .icloud: return "iCloud"
        }
    }
}

// MARK: - Extensions
extension UserPreferences {
    var effectiveTheme: UserTheme {
        if theme == .system {
            // In a real app, you'd check the system theme here
            return .dark
        }
        return theme
    }
    
    var maxDownloadQuality: StreamingQuality {
        dataSaverMode ? .hd720 : preferredDownloadQuality
    }
    
    var maxStreamingQuality: StreamingQuality {
        dataSaverMode ? .hd720 : preferredStreamingQuality
    }
    
    var shouldShowSubtitles: Bool {
        subtitlesEnabled && defaultSubtitleLanguage != nil
    }
}

// MARK: - Default Values
extension UserPreferences {
    static let `default` = UserPreferences(
        autoplay: true,
        autoplayTrailers: true,
        skipIntros: false,
        skipCredits: false,
        defaultAudioLanguage: "en",
        defaultSubtitleLanguage: nil,
        subtitlesEnabled: false,
        preferredStreamingQuality: .auto,
        preferredDownloadQuality: .hd1080,
        adaptiveStreaming: true,
        dataSaverMode: false,
        theme: .system,
        language: "en",
        region: "US",
        timeFormat: .twelveHour,
        dateFormat: .mmddyyyy,
        pushNotificationsEnabled: true,
        emailNotificationsEnabled: true,
        newContentNotifications: true,
        watchlistNotifications: true,
        downloadNotifications: true,
        shareWatchHistory: true,
        allowRecommendations: true,
        allowAnalytics: true,
        parentalControlsEnabled: false,
        parentalControlsPIN: nil,
        downloadOnlyOnWiFi: true,
        autoDownloadWatchlist: false,
        maxConcurrentDownloads: 3,
        downloadLocation: .internalStorage,
        deleteWatchedDownloads: false,
        voiceOverEnabled: false,
        highContrastMode: false,
        reducedMotion: false,
        largeText: false,
        audioDescriptions: false
    )
    
    static let sample = UserPreferences.default
}