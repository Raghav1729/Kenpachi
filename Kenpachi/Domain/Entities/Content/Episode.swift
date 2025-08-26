import Foundation

struct Episode: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let episodeNumber: Int
    let seasonNumber: Int
    let name: String
    let overview: String?
    let stillPath: String?
    let airDate: Date?
    let runtime: Int? // in minutes
    let voteAverage: Double
    let voteCount: Int
    let productionCode: String?
    let showId: String
    let seasonId: String
    
    // Episode specific
    let crew: [CrewMember]?
    let guestStars: [CastMember]?
    let images: EpisodeImages?
    let videos: [Video]?
    
    // Streaming info
    let streamingSources: [StreamingSource]?
    let watchProgress: WatchProgress?
}

struct EpisodeImages: Codable, Equatable, Hashable {
    let stills: [ImageInfo]
}

struct WatchProgress: Codable, Equatable, Hashable {
    let watchedDuration: TimeInterval // in seconds
    let totalDuration: TimeInterval
    let isCompleted: Bool
    let lastWatchedAt: Date
    
    var progressPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return min(watchedDuration / totalDuration, 1.0)
    }
    
    var remainingDuration: TimeInterval {
        max(totalDuration - watchedDuration, 0)
    }
}

// MARK: - Extensions
extension Episode {
    var formattedRuntime: String? {
        guard let runtime = runtime else { return nil }
        let hours = runtime / 60
        let minutes = runtime % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedAirDate: String? {
        guard let airDate = airDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: airDate)
    }
    
    var episodeIdentifier: String {
        return "S\(String(format: "%02d", seasonNumber))E\(String(format: "%02d", episodeNumber))"
    }
    
    var displayTitle: String {
        return "\(episodeIdentifier) • \(name)"
    }
    
    var hasAired: Bool {
        guard let airDate = airDate else { return false }
        return airDate <= Date()
    }
    
    var isWatched: Bool {
        watchProgress?.isCompleted ?? false
    }
    
    var watchProgressPercentage: Double {
        watchProgress?.progressPercentage ?? 0.0
    }
}

// MARK: - Sample Data
extension Episode {
    static let sample = Episode(
        id: "1",
        episodeNumber: 1,
        seasonNumber: 1,
        name: "Pilot",
        overview: "The series premiere introduces us to the main characters and sets up the central conflict.",
        stillPath: "/sample-episode-still.jpg",
        airDate: Date(),
        runtime: 45,
        voteAverage: 8.2,
        voteCount: 1250,
        productionCode: "101",
        showId: "1",
        seasonId: "1",
        crew: nil,
        guestStars: nil,
        images: nil,
        videos: nil,
        streamingSources: nil,
        watchProgress: WatchProgress(
            watchedDuration: 1200, // 20 minutes
            totalDuration: 2700, // 45 minutes
            isCompleted: false,
            lastWatchedAt: Date()
        )
    )
}