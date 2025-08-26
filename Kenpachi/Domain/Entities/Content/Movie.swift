import Foundation

struct Movie: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let title: String
    let originalTitle: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: Date?
    let genres: [Genre]
    let runtime: Int? // in minutes
    let budget: Int?
    let revenue: Int?
    let imdbId: String?
    let originalLanguage: String
    let popularity: Double
    let voteAverage: Double
    let voteCount: Int
    let adult: Bool
    let video: Bool
    let tagline: String?
    let status: MovieStatus
    let homepage: String?
    
    // Collections
    let belongsToCollection: MovieCollection?
    let productionCompanies: [ProductionCompany]
    let productionCountries: [ProductionCountry]
    let spokenLanguages: [SpokenLanguage]
    
    // Additional metadata
    let cast: [CastMember]?
    let crew: [CrewMember]?
    let keywords: [Keyword]?
    let videos: [Video]?
    let images: ContentImages?
    let recommendations: [Movie]?
    let similar: [Movie]?
    
    // Streaming info
    let streamingSources: [StreamingSource]?
    let watchProviders: [WatchProvider]?
}

enum MovieStatus: String, Codable, CaseIterable {
    case rumored = "Rumored"
    case planned = "Planned"
    case inProduction = "In Production"
    case postProduction = "Post Production"
    case released = "Released"
    case canceled = "Canceled"
}

struct MovieCollection: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let parts: [Movie]?
}

// MARK: - Extensions
extension Movie {
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
    
    var formattedReleaseYear: String? {
        guard let releaseDate = releaseDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: releaseDate)
    }
    
    var genreNames: String {
        genres.map { $0.name }.joined(separator: ", ")
    }
    
    var isUpcoming: Bool {
        guard let releaseDate = releaseDate else { return false }
        return releaseDate > Date()
    }
    
    var isReleased: Bool {
        status == .released
    }
}

// MARK: - Content Protocol Conformance
extension Movie {
    func toContent() -> Content {
        return Content(
            id: id,
            title: title,
            overview: overview,
            posterURL: posterPath,
            backdropURL: backdropPath,
            releaseDate: releaseDate,
            genres: genres,
            rating: voteAverage,
            contentType: .movie,
            runtime: runtime,
            originalLanguage: originalLanguage,
            popularity: popularity,
            voteCount: voteCount,
            adult: adult,
            tagline: tagline,
            status: status.rawValue,
            homepage: homepage,
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