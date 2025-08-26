import Foundation

struct Season: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let seasonNumber: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let airDate: Date?
    let episodeCount: Int
    let episodes: [Episode]?
    let tvShowId: String
    
    // Additional metadata
    let voteAverage: Double?
    let credits: SeasonCredits?
    let images: ContentImages?
    let videos: [Video]?
}

struct SeasonCredits: Codable, Equatable, Hashable {
    let cast: [CastMember]
    let crew: [CrewMember]
    let guestStars: [CastMember]
}

// MARK: - Extensions
extension Season {
    var formattedAirYear: String? {
        guard let airDate = airDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: airDate)
    }
    
    var episodeCountText: String {
        episodeCount == 1 ? "1 Episode" : "\(episodeCount) Episodes"
    }
    
    var isSpecialSeason: Bool {
        seasonNumber == 0
    }
    
    var displayName: String {
        if isSpecialSeason {
            return "Specials"
        } else {
            return name.isEmpty ? "Season \(seasonNumber)" : name
        }
    }
}

// MARK: - Sample Data
extension Season {
    static let sample = Season(
        id: "1",
        seasonNumber: 1,
        name: "Season 1",
        overview: "The first season introduces us to the main characters and sets up the story.",
        posterPath: "/sample-season-poster.jpg",
        airDate: Date(),
        episodeCount: 10,
        episodes: nil,
        tvShowId: "1",
        voteAverage: 8.5,
        credits: nil,
        images: nil,
        videos: nil
    )
}