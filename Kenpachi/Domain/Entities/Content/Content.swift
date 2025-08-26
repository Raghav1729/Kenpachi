import Foundation

// MARK: - Content Types
enum ContentType: String, CaseIterable, Codable {
    case movie = "movie"
    case tvShow = "tv"
    case anime = "anime"
    case documentary = "documentary"
    case short = "short"
}

enum TimeWindow: String, CaseIterable {
    case day = "day"
    case week = "week"
}

// MARK: - Main Content Entity
struct Content: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let title: String
    let overview: String
    let posterURL: String?
    let backdropURL: String?
    let releaseDate: Date?
    let genres: [Genre]
    let rating: Double
    let contentType: ContentType
    let runtime: Int? // in minutes
    let originalLanguage: String?
    let popularity: Double?
    let voteCount: Int?
    let adult: Bool
    let tagline: String?
    let status: String?
    let homepage: String?
    
    // TV Show specific
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let firstAirDate: Date?
    let lastAirDate: Date?
    let inProduction: Bool?
    
    // Additional metadata
    let cast: [CastMember]?
    let crew: [CrewMember]?
    let productionCompanies: [ProductionCompany]?
    let productionCountries: [ProductionCountry]?
    let spokenLanguages: [SpokenLanguage]?
    let keywords: [Keyword]?
    let videos: [Video]?
    let images: ContentImages?
    
    init(
        id: String,
        title: String,
        overview: String,
        posterURL: String? = nil,
        backdropURL: String? = nil,
        releaseDate: Date? = nil,
        genres: [Genre] = [],
        rating: Double = 0.0,
        contentType: ContentType,
        runtime: Int? = nil,
        originalLanguage: String? = nil,
        popularity: Double? = nil,
        voteCount: Int? = nil,
        adult: Bool = false,
        tagline: String? = nil,
        status: String? = nil,
        homepage: String? = nil,
        numberOfSeasons: Int? = nil,
        numberOfEpisodes: Int? = nil,
        firstAirDate: Date? = nil,
        lastAirDate: Date? = nil,
        inProduction: Bool? = nil,
        cast: [CastMember]? = nil,
        crew: [CrewMember]? = nil,
        productionCompanies: [ProductionCompany]? = nil,
        productionCountries: [ProductionCountry]? = nil,
        spokenLanguages: [SpokenLanguage]? = nil,
        keywords: [Keyword]? = nil,
        videos: [Video]? = nil,
        images: ContentImages? = nil
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterURL = posterURL
        self.backdropURL = backdropURL
        self.releaseDate = releaseDate
        self.genres = genres
        self.rating = rating
        self.contentType = contentType
        self.runtime = runtime
        self.originalLanguage = originalLanguage
        self.popularity = popularity
        self.voteCount = voteCount
        self.adult = adult
        self.tagline = tagline
        self.status = status
        self.homepage = homepage
        self.numberOfSeasons = numberOfSeasons
        self.numberOfEpisodes = numberOfEpisodes
        self.firstAirDate = firstAirDate
        self.lastAirDate = lastAirDate
        self.inProduction = inProduction
        self.cast = cast
        self.crew = crew
        self.productionCompanies = productionCompanies
        self.productionCountries = productionCountries
        self.spokenLanguages = spokenLanguages
        self.keywords = keywords
        self.videos = videos
        self.images = images
    }
}

// MARK: - Supporting Types
struct Genre: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
}

struct CastMember: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?
    let order: Int
}

struct CrewMember: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
    let job: String
    let department: String
    let profilePath: String?
}

struct ProductionCompany: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
    let logoPath: String?
    let originCountry: String
}

struct ProductionCountry: Codable, Equatable, Hashable {
    let iso31661: String
    let name: String
}

struct SpokenLanguage: Codable, Equatable, Hashable {
    let iso6391: String
    let name: String
    let englishName: String
}

struct Keyword: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
}

struct Video: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let key: String
    let name: String
    let site: String
    let type: String
    let size: Int
    let official: Bool
}

struct ContentImages: Codable, Equatable, Hashable {
    let backdrops: [ImageInfo]
    let posters: [ImageInfo]
    let logos: [ImageInfo]?
}

struct ImageInfo: Codable, Equatable, Hashable {
    let aspectRatio: Double
    let filePath: String
    let height: Int
    let width: Int
    let voteAverage: Double
    let voteCount: Int
}

// MARK: - Content Section Data
struct ContentSectionData: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let content: [Content]
    let sectionType: SectionType
    
    init(title: String, content: [Content], sectionType: SectionType = .horizontal) {
        self.title = title
        self.content = content
        self.sectionType = sectionType
    }
}

enum SectionType {
    case horizontal
    case grid
    case hero
    case featured
}