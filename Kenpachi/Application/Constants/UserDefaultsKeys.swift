import Foundation

struct UserDefaultsKeys {
    // User Preferences
    static let preferredVideoQuality = "preferred_video_quality"
    static let autoPlayEnabled = "auto_play_enabled"
    static let subtitlesEnabled = "subtitles_enabled"
    static let preferredSubtitleLanguage = "preferred_subtitle_language"
    
    // App State
    static let lastSelectedTab = "last_selected_tab"
    static let lastWatchedContent = "last_watched_content"
    
    // Download Settings
    static let downloadQuality = "download_quality"
    static let wifiOnlyDownloads = "wifi_only_downloads"
    static let autoDeleteWatchedDownloads = "auto_delete_watched_downloads"
    
    // Privacy & Security
    static let parentalControlsEnabled = "parental_controls_enabled"
    static let analyticsEnabled = "analytics_enabled"
    
    // Playback Settings
    static let skipIntroEnabled = "skip_intro_enabled"
    static let skipCreditsEnabled = "skip_credits_enabled"
    static let continuousPlayEnabled = "continuous_play_enabled"
}