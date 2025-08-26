import Foundation

struct DownloadItem: Identifiable, Codable, Equatable {
    let id: String
    let contentId: String
    let contentType: ContentType
    let title: String
    let posterURL: String?
    let episodeId: String? // For TV shows
    let seasonNumber: Int? // For TV shows
    let episodeNumber: Int? // For TV shows
    let quality: StreamingQuality
    let fileSize: Int64 // in bytes
    let downloadedSize: Int64 // in bytes
    let status: DownloadStatus
    let progress: DownloadProgress
    let createdAt: Date
    let startedAt: Date?
    let completedAt: Date?
    let expiresAt: Date?
    let localPath: String?
    let streamingSource: StreamingSource?
    let subtitles: [SubtitleTrack]
    let error: DownloadError?
}

enum DownloadStatus: String, Codable, CaseIterable {
    case queued = "queued"
    case downloading = "downloading"
    case paused = "paused"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .queued: return "Queued"
        case .downloading: return "Downloading"
        case .paused: return "Paused"
        case .completed: return "Downloaded"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        }
    }
    
    var isActive: Bool {
        self == .downloading
    }
    
    var canResume: Bool {
        self == .paused || self == .failed
    }
    
    var canPause: Bool {
        self == .downloading || self == .queued
    }
    
    var canDelete: Bool {
        true // All downloads can be deleted
    }
}

struct DownloadError: Codable, Equatable {
    let code: String
    let message: String
    let timestamp: Date
    let retryCount: Int
    
    var isRetryable: Bool {
        retryCount < 3 && (code == "network_error" || code == "timeout")
    }
}

// MARK: - Extensions
extension DownloadItem {
    var progressPercentage: Double {
        guard fileSize > 0 else { return 0 }
        return min(Double(downloadedSize) / Double(fileSize), 1.0)
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var formattedDownloadedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: downloadedSize)
    }
    
    var remainingSize: Int64 {
        max(fileSize - downloadedSize, 0)
    }
    
    var formattedRemainingSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: remainingSize)
    }
    
    var estimatedTimeRemaining: TimeInterval? {
        guard status == .downloading,
              let downloadSpeed = progress.downloadSpeed,
              downloadSpeed > 0,
              remainingSize > 0 else { return nil }
        
        return TimeInterval(remainingSize) / downloadSpeed
    }
    
    var formattedTimeRemaining: String? {
        guard let timeRemaining = estimatedTimeRemaining else { return nil }
        
        let hours = Int(timeRemaining) / 3600
        let minutes = Int(timeRemaining) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var daysUntilExpiry: Int? {
        guard let expiresAt = expiresAt else { return nil }
        let timeInterval = expiresAt.timeIntervalSince(Date())
        return max(Int(timeInterval / 86400), 0)
    }
    
    var displayTitle: String {
        if let episodeNumber = episodeNumber, let seasonNumber = seasonNumber {
            return "\(title) - S\(String(format: "%02d", seasonNumber))E\(String(format: "%02d", episodeNumber))"
        }
        return title
    }
}

// MARK: - Sample Data
extension DownloadItem {
    static let sample = DownloadItem(
        id: "download_1",
        contentId: "1",
        contentType: .movie,
        title: "Avatar: The Way of Water",
        posterURL: "https://image.tmdb.org/t/p/w500/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg",
        episodeId: nil,
        seasonNumber: nil,
        episodeNumber: nil,
        quality: .hd1080,
        fileSize: 4294967296, // 4GB
        downloadedSize: 2147483648, // 2GB (50% downloaded)
        status: .downloading,
        progress: DownloadProgress.sample,
        createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
        startedAt: Date().addingTimeInterval(-1800), // 30 minutes ago
        completedAt: nil,
        expiresAt: Date().addingTimeInterval(86400 * 30), // 30 days from now
        localPath: nil,
        streamingSource: StreamingSource.sample,
        subtitles: SubtitleTrack.sampleTracks,
        error: nil
    )
}