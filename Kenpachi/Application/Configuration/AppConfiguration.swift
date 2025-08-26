import Foundation

struct AppConfiguration {
    
    // MARK: - Network Configuration
    static let requestTimeout: TimeInterval = Environment.current.requestTimeoutInterval
    static let maxConcurrentRequests = Environment.current.maxConcurrentRequests
    
    // MARK: - API Configuration
    static let baseURL = Environment.current.baseURL
    static let tmdbBaseURL = Environment.current.tmdbBaseURL
    static let imageBaseURL = Environment.current.imageBaseURL
    
    // MARK: - Cache Configuration
    static let imageCacheMaxSize = Environment.current.imageCacheMaxSize
    static let cachePolicy = Environment.current.cachePolicy
    
    // MARK: - Download Configuration
    static let maxConcurrentDownloads = Environment.current.maxConcurrentDownloads
    static let downloadRetryAttempts = Environment.current.downloadRetryAttempts
    
    // MARK: - Streaming Configuration
    static let defaultStreamingQuality = Environment.current.defaultStreamingQuality
    static let bufferDuration = Environment.current.bufferDuration
    
    // MARK: - Feature Flags
    static let isLoggingEnabled = Environment.current.isLoggingEnabled
    static let isAnalyticsEnabled = Environment.current.isAnalyticsEnabled
    static let isCrashReportingEnabled = Environment.current.isCrashReportingEnabled
    static let isDebugMenuEnabled = Environment.current.isDebugMenuEnabled
    static let useMockData = Environment.current.useMockData
    
    // MARK: - Security Configuration
    static let certificatePinningEnabled = Environment.current.certificatePinningEnabled
    static let allowHTTP = Environment.current.allowHTTP
    
    // MARK: - App Information
    static let appName = AppConstants.App.name
    static let appVersion = AppConstants.App.version
    static let buildNumber = AppConstants.App.buildNumber
    static let bundleIdentifier = AppConstants.App.bundleIdentifier
    
    // MARK: - UI Configuration
    static let animationDuration = AppConstants.UI.mediumAnimationDuration
    static let cornerRadius = AppConstants.UI.cornerRadius
    static let cardSpacing = AppConstants.UI.cardSpacing
    
    // MARK: - Content Configuration
    static let maxRecentSearches = AppConstants.Content.maxRecentSearches
    static let maxWatchlistItems = AppConstants.Content.maxWatchlistItems
    static let maxDownloads = AppConstants.Content.maxDownloads
    static let searchResultsPerPage = AppConstants.Content.searchResultsPerPage
    
    // MARK: - Helper Methods
    static func configure() {
        // Perform any app-wide configuration here
        configureNetworking()
        configureLogging()
        configureAnalytics()
    }
    
    private static func configureNetworking() {
        // Configure URLSession and networking settings
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.timeoutIntervalForResource = requestTimeout * 2
        configuration.requestCachePolicy = cachePolicy
        configuration.httpMaximumConnectionsPerHost = maxConcurrentRequests
    }
    
    private static func configureLogging() {
        // Configure logging based on environment
        if isLoggingEnabled {
            // Enable detailed logging for development
            print("🔧 Logging enabled for \(Environment.current.displayName) environment")
        }
    }
    
    private static func configureAnalytics() {
        // Configure analytics based on environment
        if isAnalyticsEnabled {
            // Initialize analytics SDK
            print("📊 Analytics enabled for \(Environment.current.displayName) environment")
        }
    }
}