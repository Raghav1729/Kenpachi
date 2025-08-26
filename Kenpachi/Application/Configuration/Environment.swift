import Foundation

enum Environment: String, CaseIterable {
  case development = "development"
  case staging = "staging"
  case production = "production"

  static var current: Environment {
    #if DEBUG
      return .development
    #elseif STAGING
      return .staging
    #else
      return .production
    #endif
  }

  var displayName: String {
    switch self {
    case .development: return "Development"
    case .staging: return "Staging"
    case .production: return "Production"
    }
  }

  // MARK: - API Configuration
  var baseURL: String {
    switch self {
    case .development:
      return "https://dev-api.kenpachi.com"
    case .staging:
      return "https://staging-api.kenpachi.com"
    case .production:
      return "https://api.kenpachi.com"
    }
  }

  var tmdbBaseURL: String {
    return "https://api.themoviedb.org/3"
  }

  var imageBaseURL: String {
    return "https://image.tmdb.org/t/p"
  }

  // MARK: - Feature Flags
  var isLoggingEnabled: Bool {
    switch self {
    case .development, .staging:
      return true
    case .production:
      return false
    }
  }

  var isAnalyticsEnabled: Bool {
    switch self {
    case .development:
      return false
    case .staging, .production:
      return true
    }
  }

  var isCrashReportingEnabled: Bool {
    switch self {
    case .development:
      return false
    case .staging, .production:
      return true
    }
  }

  var isDebugMenuEnabled: Bool {
    switch self {
    case .development, .staging:
      return true
    case .production:
      return false
    }
  }

  // MARK: - Network Configuration
  var requestTimeoutInterval: TimeInterval {
    switch self {
    case .development:
      return 60  // Longer timeout for debugging
    case .staging, .production:
      return 30
    }
  }

  var maxConcurrentRequests: Int {
    switch self {
    case .development:
      return 5
    case .staging, .production:
      return 10
    }
  }

  // MARK: - Cache Configuration
  var cachePolicy: URLRequest.CachePolicy {
    switch self {
    case .development:
      return .reloadIgnoringLocalCacheData
    case .staging, .production:
      return .returnCacheDataElseLoad
    }
  }

  var imageCacheMaxSize: Int {
    switch self {
    case .development:
      return 50 * 1024 * 1024  // 50MB
    case .staging, .production:
      return 100 * 1024 * 1024  // 100MB
    }
  }

  // MARK: - Download Configuration
  var maxConcurrentDownloads: Int {
    switch self {
    case .development:
      return 2
    case .staging, .production:
      return 3
    }
  }

  var downloadRetryAttempts: Int {
    switch self {
    case .development:
      return 5  // More retries for testing
    case .staging, .production:
      return 3
    }
  }

  // MARK: - Streaming Configuration
  var defaultStreamingQuality: StreamingQuality {
    switch self {
    case .development:
      return .hd720  // Lower quality for faster testing
    case .staging, .production:
      return .auto
    }
  }

  var bufferDuration: TimeInterval {
    switch self {
    case .development:
      return 5  // Shorter buffer for testing
    case .staging, .production:
      return 10
    }
  }

  // MARK: - Security Configuration
  var certificatePinningEnabled: Bool {
    switch self {
    case .development:
      return false
    case .staging, .production:
      return true
    }
  }

  var allowHTTP: Bool {
    switch self {
    case .development:
      return true
    case .staging, .production:
      return false
    }
  }

  // MARK: - Mock Data Configuration
  var useMockData: Bool {
    switch self {
    case .development:
      return true
    case .staging, .production:
      return false
    }
  }

  var mockDataDelay: TimeInterval {
    switch self {
    case .development:
      return 0.5  // Simulate network delay
    case .staging, .production:
      return 0
    }
  }
}
