import Foundation

struct StreamingSource: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let url: String
    let quality: StreamingQuality
    let type: StreamingType
    let server: String
    let isWorking: Bool
    let lastChecked: Date
    let headers: [String: String]?
    let referer: String?
    
    // Additional metadata
    let fileSize: Int64? // in bytes
    let duration: TimeInterval? // in seconds
    let language: String?
    let subtitles: [SubtitleTrack]?
}

enum StreamingType: String, Codable, CaseIterable {
    case direct = "direct"
    case hls = "hls"
    case dash = "dash"
    case torrent = "torrent"
    case magnet = "magnet"
}

struct WatchProvider: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
    let logoPath: String?
    let displayPriority: Int
    let type: WatchProviderType
}

enum WatchProviderType: String, Codable, CaseIterable {
    case flatrate = "flatrate" // Subscription
    case rent = "rent"
    case buy = "buy"
    case ads = "ads" // Free with ads
    case free = "free" // Completely free
}

// MARK: - Extensions
extension StreamingSource {
    var formattedFileSize: String? {
        guard let fileSize = fileSize else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var isHD: Bool {
        quality.height >= 720
    }
    
    var is4K: Bool {
        quality.height >= 2160
    }
}

// MARK: - Sample Data
extension StreamingSource {
    static let sample = StreamingSource(
        id: "1",
        url: "https://example.com/stream.m3u8",
        quality: .hd720,
        type: .hls,
        server: "VidCloud",
        isWorking: true,
        lastChecked: Date(),
        headers: ["User-Agent": "Mozilla/5.0"],
        referer: "https://example.com",
        fileSize: 1073741824, // 1GB
        duration: 5400, // 90 minutes
        language: "en",
        subtitles: [SubtitleTrack.sample]
    )
}