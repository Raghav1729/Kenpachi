import Foundation

struct TVShow: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let originalName: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: Date?
    let lastAirDate: Date?
    let genres: [Genre]
    let episodeRunTime: [Int] // Array because episodes can have different runtimes
    let numberOfEpisodes: Int
    let numberOfSeasons: Int
    let originCountry: [String]
    let originalLanguage: String
    let popularity: Double
    let voteAverage: Double
    let voteCount: Int
    let adult: Bool
    let inProduction: Bool
    let status: TVShowStatus
    let type: TVShowType
    let homepage: String?
    let tagline: String?
    
    // TV Show specific
    let createdBy: [Creator]
    let networks: [Network]
    let productionCompanies: [ProductionCompany]
    let productionCountries: [ProductionCountry]
    let spokenLanguages: [SpokenLanguage]
    let seasons: [Season]?
    let nextEpisodeToAir: Episode?
    let lastEpisodeToAir: Episode?
    
    // Additional metadata
    let cast: [CastMember]?
    let crew: [CrewMember]?
    let keywords: [Keyword]?
    let videos: [Video]?
    let images: ContentImages?
    let recommendations: [TVShow]?
    let similar: [TVShow]?
    
    // Streaming info
    let streamingSources: [StreamingSource]?
    let watchProviders: [WatchProvider]?
}

enum TVShowStatus: String, Codable, CaseIterable {
    case returningSeries = "Returning Series"
    case planned = "Planned"
    case inProduction = "In Production"
    case ended = "Ended"
    case canceled = "Canceled"
    case pilot = "Pilot"
}

enum TVShowType: String, Codable, CaseIterable {
    case scripted = "Scripted"
    case reality = "Reality"
    case documentary = "Documentary"
    case news = "News"
    case talkShow = "Talk Show"
    case miniseries = "Miniseries"
}

struct Creator: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
    let profilePath: String?
    let creditId: String
}

struct Network: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
    let logoPath: String?
    let originCountry: String
}

// MARK: - Extensions
extension TVShow {
    var formattedRuntime: String? {
        guard !episodeRunTime.isEmpty else { return nil }
        let avgRuntime = episodeRunTime.reduce(0, +) / episodeRunTime.count
        return "\(avgRuntime)m"
    }
    
    var formattedAirYear: String? {
        guard let firstAirDate = firstAirDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let startYear = formatter.string(from: firstAirDate)
        
        if let lastAirDate = lastAirDate, !inProduction {
            let endYear = formatter.string(from: lastAirDate)
            return startYear == endYear ? startYear : "\(startYear)-\(endYear)"
        } else {
            return inProduction ? "\(startYear)-" : startYear
        }
    }
    
    var genreNames: String {
        genres.map { $0.name }.joined(separator: ", ")
    }
    
    var isOngoing: Bool {
        status == .returningSeries && inProduction
    }
    
    var isCompleted: Bool {
        status == .ended || status == .canceled
    }
    
    var seasonsCount: String {
        numberOfSeasons == 1 ? "1 Season" : "\(numberOfSeasons) Seasons"
    }
    
    var episodesCount: String {
        numberOfEpisodes == 1 ? "1 Episode" : "\(numberOfEpisodes) Episodes"
    }
}

// MARK: - Content Protocol Conformance
extension TVShow {
    func toContent() -> Content {
        return Content(
            id: id,
            title: name,
            overview: overview,
            posterURL: posterPath,
            backdropURL: backdropPath,
            releaseDate: firstAirDate,
            genres: genres,
            rating: voteAverage,
            contentType: .tvShow,
            runtime: episodeRunTime.first,
            originalLanguage: originalLanguage,
            popularity: popularity,
            voteCount: voteCount,
            adult: adult,
            tagline: tagline,
            status: status.rawValue,
            homepage: homepage,
            numberOfSeasons: numberOfSeasons,
            numberOfEpisodes: numberOfEpisodes,
            firstAirDate: firstAirDate,
            lastAirDate: lastAirDate,
            inProduction: inProduction,
            cast: cast,
            crew: crew,
            productionCompanies: productionCompanies,
            productionCountries: productionCountries,
            spokenLanguages: spokenLanguages,
            keywords: keywords,
            videos: videos,
            images: images
        )
    }
}