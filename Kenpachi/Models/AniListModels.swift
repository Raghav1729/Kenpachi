//
//  AniListModels.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//
import Foundation

// MARK: - AniList Common Structures

/// Represents various titles an entry can have.
struct AniListTitle: Decodable, Hashable, Equatable {
    let romaji: String?
    let english: String?
    let native: String?

    var primaryTitle: String {
        english ?? romaji ?? native ?? "Unknown Title"
    }
}

/// Represents an image URL with different sizes.
struct AniListCoverImage: Codable, Hashable, Equatable {
    let extraLarge: String?
    let large: String?
    let medium: String?
    let color: String? // Hex color string
}

/// Represents a fuzzy date (year, month, day).
struct AniListFuzzyDate: Decodable, Hashable, Equatable {
    let year: Int?
    let month: Int?
    let day: Int?

    var formattedDate: String? {
        guard let year = year else { return nil }
        let monthString = month != nil ? String(format: "%02d", month!) : nil
        let dayString = day != nil ? String(format: "%02d", day!) : nil

        if let month = monthString, let day = dayString {
            return "\(year)-\(month)-\(day)"
        } else if let month = monthString {
            return "\(year)-\(month)"
        } else {
            return "\(year)"
        }
    }
}

/// Represents a tag associated with a media entry.
struct AniListTag: Decodable, Hashable, Equatable {
    let name: String?
    let description: String?
    let rank: Int?
    let isGeneralSpoiler: Bool?
    let isMediaSpoiler: Bool?
    let isAdult: Bool?
}

/// Represents an external link related to a media entry.
struct AniListExternalLink: Decodable, Hashable, Equatable {
    let id: Int
    let url: String? // URL string
    let site: String?
    let type: String? // "STREAMING", "INFO" etc.
    let language: String?
    let color: String? // Hex color string
}

// MARK: - AniList Enums
enum AniListMediaStatus: String, Codable, Equatable, CaseIterable {
    case finished = "FINISHED"
    case releasing = "RELEASING"
    case notYetReleased = "NOT_YET_RELEASED"
    case cancelled = "CANCELLED"
    case hiatsu = "HIATUS"
    case unknown // For unexpected values
}

enum AniListMediaFormat: String, Codable, Equatable, CaseIterable {
    case tv = "TV"
    case tvShort = "TV_SHORT"
    case movie = "MOVIE"
    case special = "SPECIAL"
    case ova = "OVA"
    case ona = "ONA"
    case music = "MUSIC"
    case manga = "MANGA"
    case novel = "NOVEL"
    case oneShot = "ONE_SHOT"
    case unknown // For unexpected values
}

enum AniListMediaType: String, Codable, Equatable, CaseIterable {
    case anime = "ANIME"
    case manga = "MANGA"
    case unknown // For unexpected values
}

enum AniListMediaSeason: String, Codable, Equatable, CaseIterable {
    case winter = "WINTER"
    case spring = "SPRING"
    case summer = "SUMMER"
    case fall = "FALL"
    case unknown // For unexpected values
}

// MARK: - Generic AniList Media Model (for lists)

/// Represents a simplified AniList Media entry (Anime or Manga) suitable for lists.
struct AniListMedia: Decodable, Identifiable, Hashable, Equatable {
    let id: Int
    let title: AniListTitle?
    let coverImage: AniListCoverImage?
    let startDate: AniListFuzzyDate?
    let description: String? // HTML formatted string
    let type: AniListMediaType?
    let averageScore: Int? // Out of 100
    let genres: [String]? // Array of genre strings

    /// Helper to get the primary display title.
    var primaryTitle: String {
        title?.primaryTitle ?? "Unknown Title"
    }

    /// Helper to get the large cover image URL.
    var largeCoverImageURL: URL? {
        guard let urlString = coverImage?.extraLarge ?? coverImage?.large else { return nil }
        return URL(string: urlString)
    }

    /// Helper to strip HTML from description.
    var cleanDescription: String {
        guard let description = description else { return "" }
        // Simple regex to strip HTML tags. For robust parsing, consider a dedicated library.
        return description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}

// MARK: - AniList Detail Models (Specific fields for Anime/Manga details)

/// Represents detailed information for an Anime entry.
struct AniListAnimeDetails: Decodable, Identifiable, Hashable, Equatable {
    let id: Int
    let title: AniListTitle?
    let description: String?
    let coverImage: AniListCoverImage?
    let bannerImage: String? // URL string
    let startDate: AniListFuzzyDate?
    let endDate: AniListFuzzyDate?
    let episodes: Int? // Number of episodes for anime
    let duration: Int? // Episode duration in minutes
    let season: AniListMediaSeason?
    let seasonYear: Int?
    let status: AniListMediaStatus?
    let averageScore: Int? // Out of 100
    let genres: [String]?
    let tags: [AniListTag]?
    let externalLinks: [AniListExternalLink]?
    let format: AniListMediaFormat?
    let type: AniListMediaType?

    var primaryTitle: String {
        title?.primaryTitle ?? "Unknown Title"
    }

    var largeCoverImageURL: URL? {
        guard let urlString = coverImage?.extraLarge ?? coverImage?.large else { return nil }
        return URL(string: urlString)
    }

    var fullBannerImageURL: URL? {
        guard let urlString = bannerImage else { return nil }
        return URL(string: urlString)
    }

    var cleanDescription: String {
        guard let description = description else { return "" }
        return description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}

/// Represents detailed information for a Manga entry.
struct AniListMangaDetails: Decodable, Identifiable, Hashable, Equatable {
    let id: Int
    let title: AniListTitle?
    let description: String?
    let coverImage: AniListCoverImage?
    let bannerImage: String? // URL string
    let startDate: AniListFuzzyDate?
    let endDate: AniListFuzzyDate?
    let chapters: Int? // Number of chapters for manga
    let volumes: Int? // Number of volumes for manga
    let status: AniListMediaStatus?
    let averageScore: Int? // Out of 100
    let genres: [String]?
    let tags: [AniListTag]?
    let externalLinks: [AniListExternalLink]?
    let format: AniListMediaFormat?
    let type: AniListMediaType?

    var primaryTitle: String {
        title?.primaryTitle ?? "Unknown Title"
    }

    var largeCoverImageURL: URL? {
        guard let urlString = coverImage?.extraLarge ?? coverImage?.large else { return nil }
        return URL(string: urlString)
    }

    var fullBannerImageURL: URL? {
        guard let urlString = bannerImage else { return nil }
        return URL(string: urlString)
    }

    var cleanDescription: String {
        guard let description = description else { return "" }
        return description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}

// MARK: - AniList GraphQL Response Wrappers (These match the GraphQL JSON structure)

/// Generic wrapper for AniList GraphQL `data` object.
struct AniListDataWrapper<T: Decodable>: Decodable, Equatable where T: Equatable { // Add Equatable for testing
    let data: T?
}

/// Represents a `Page` object within AniList GraphQL response, containing a list of `Media`.
struct AniListPageWrapper<T: Decodable>: Decodable, Equatable where T: Equatable { // Add Equatable for testing
    let page: AniListPage<T>? // This will contain pageInfo and media array
}

/// Represents a page of media results from AniList.
struct AniListPage<T: Decodable>: Decodable, Equatable where T: Equatable { // Add Equatable for testing
    let pageInfo: AniListPageInfo?
    let media: [T]? // Can be [AniListMedia] or [AniListAnimeDetails] etc.
}

/// Page information for paginated AniList results.
struct AniListPageInfo: Decodable, Hashable, Equatable {
    let total: Int?
    let perPage: Int?
    let currentPage: Int?
    let lastPage: Int?
    let hasNextPage: Bool?
}

// MARK: - AniList Query Helpers

/// Categories for AniList data requests, used to construct GraphQL queries.
enum AniListCategory: Identifiable {
    case popularAnime(page: Int)
    case topRatedAnime(page: Int)
    case popularManga(page: Int)
    case topRatedManga(page: Int)
    case searchAnime(query: String, page: Int)
    case searchManga(query: String, page: Int)
    case animeDetails(id: Int)
    case mangaDetails(id: Int)

    var id: String {
        switch self {
        case .popularAnime: return "popularAnime"
        case .topRatedAnime: return "topRatedAnime"
        case .popularManga: return "popularManga"
        case .topRatedManga: return "topRatedManga"
        case .searchAnime: return "searchAnime"
        case .searchManga: return "searchManga"
        case .animeDetails: return "animeDetails"
        case .mangaDetails: return "mangaDetails"
        }
    }

    // This property generates the GraphQL query string.
    var query: String {
        let mediaListFields: String = """
            id
            title { romaji english native }
            coverImage { extraLarge large medium color }
            startDate { year month day }
            description(asHtml: false)
            type
            averageScore
            genres
        """

        let animeDetailFields: String = """
            \(mediaListFields)
            bannerImage
            endDate { year month day }
            episodes
            duration
            season
            seasonYear
            status
            tags { name description rank isGeneralSpoiler isMediaSpoiler isAdult }
            externalLinks { id url site type language color }
            format
        """

        let mangaDetailFields: String = """
            \(mediaListFields)
            bannerImage
            endDate { year month day }
            chapters
            volumes
            status
            tags { name description rank isGeneralSpoiler isMediaSpoiler isAdult }
            externalLinks { id url site type language color }
            format
        """

        switch self {
        case .popularAnime, .topRatedAnime:
            return """
            query ($page: Int, $perPage: Int, $sort: [MediaSort], $type: MediaType) {
                Page (page: $page, perPage: $perPage) {
                    pageInfo {
                        total
                        currentPage
                        lastPage
                        hasNextPage
                    }
                    media (sort: $sort, type: $type) {
                        \(mediaListFields)
                    }
                }
            }
            """
        case .popularManga, .topRatedManga:
            return """
            query ($page: Int, $perPage: Int, $sort: [MediaSort], $type: MediaType) {
                Page (page: $page, perPage: $perPage) {
                    pageInfo {
                        total
                        currentPage
                        lastPage
                        hasNextPage
                    }
                    media (sort: $sort, type: $type) {
                        \(mediaListFields)
                    }
                }
            }
            """
        case .searchAnime:
            return """
            query ($page: Int, $perPage: Int, $search: String, $type: MediaType) {
                Page (page: $page, perPage: $perPage) {
                    pageInfo {
                        total
                        currentPage
                        lastPage
                        hasNextPage
                    }
                    media (search: $search, type: $type) {
                        \(mediaListFields)
                    }
                }
            }
            """
        case .searchManga:
            return """
            query ($page: Int, $perPage: Int, $search: String, $type: MediaType) {
                Page (page: $page, perPage: $perPage) {
                    pageInfo {
                        total
                        currentPage
                        lastPage
                        hasNextPage
                    }
                    media (search: $search, type: $type) {
                        \(mediaListFields)
                    }
                }
            }
            """
        case .animeDetails:
            return """
            query ($id: Int) {
                Media(id: $id, type: ANIME) {
                    \(animeDetailFields)
                }
            }
            """
        case .mangaDetails:
            return """
            query ($id: Int) {
                Media(id: $id, type: MANGA) {
                    \(mangaDetailFields)
                }
            }
            """
        }
    }

    // This property generates the GraphQL variables dictionary.
    var variables: [String: Any] {
        var vars: [String: Any] = [:]
        let defaultPerPage = 20 // Standard pagination size

        switch self {
        case .popularAnime(let page):
            vars["page"] = page
            vars["perPage"] = defaultPerPage
            vars["sort"] = ["POPULARITY_DESC"]
            vars["type"] = "ANIME"
        case .topRatedAnime(let page):
            vars["page"] = page
            vars["perPage"] = defaultPerPage
            vars["sort"] = ["SCORE_DESC"]
            vars["type"] = "ANIME"
        case .popularManga(let page):
            vars["page"] = page
            vars["perPage"] = defaultPerPage
            vars["sort"] = ["POPULARITY_DESC"]
            vars["type"] = "MANGA"
        case .topRatedManga(let page):
            vars["page"] = page
            vars["perPage"] = defaultPerPage
            vars["sort"] = ["SCORE_DESC"]
            vars["type"] = "MANGA"
        case .searchAnime(let query, let page):
            vars["page"] = page
            vars["perPage"] = defaultPerPage
            vars["search"] = query
            vars["type"] = "ANIME"
        case .searchManga(let query, let page):
            vars["page"] = page
            vars["perPage"] = defaultPerPage
            vars["search"] = query
            vars["type"] = "MANGA"
        case .animeDetails(let id):
            vars["id"] = id
        case .mangaDetails(let id):
            vars["id"] = id
        }
        return vars
    }
}

/// Struct to define the GraphQL query body for AniList
struct GraphQLQuery: Encodable {
    let query: String
    let variables: [String: AnyEncodable]?

    // Custom encoding to handle `Any` in variables
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(query, forKey: .query)
        if let variables = variables {
            try container.encode(variables, forKey: .variables)
        }
    }

    enum CodingKeys: String, CodingKey {
        case query, variables
    }

    // Helper to convert a dictionary of [String: Any] to [String: AnyEncodable]
    // This is crucial because Encodable cannot directly encode `Any`
    struct AnyEncodable: Encodable {
        let value: Any

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch value {
            case let intValue as Int:
                try container.encode(intValue)
            case let stringValue as String:
                try container.encode(stringValue)
            case let boolValue as Bool:
                try container.encode(boolValue)
            case let doubleValue as Double:
                try container.encode(doubleValue)
            case let arrayValue as [Any?]: // Handle optional elements in array
                // Map array of Any? to array of AnyEncodable?
                let encodableArray = arrayValue.map { val -> AnyEncodable? in
                    if let val = val { return AnyEncodable(value: val) }
                    return nil
                }
                try container.encode(encodableArray)
            case let dictionaryValue as [String: Any?]: // Handle optional values in dictionary
                // Map dictionary of Any? to dictionary of AnyEncodable?
                let encodableDictionary = dictionaryValue.mapValues { val -> AnyEncodable? in
                    if let val = val { return AnyEncodable(value: val) }
                    return nil
                }
                try container.encode(encodableDictionary)
            default:
                let context = EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "AnyEncodable cannot encode type \(type(of: value)). Value must be a primitive, [Any?], or [String: Any?].")
                throw EncodingError.invalidValue(value, context)
            }
        }
    }

    static func convertVariables(_ dict: [String: Any]?) -> [String: AnyEncodable]? {
        guard let dict = dict else { return nil }
        return dict.mapValues { AnyEncodable(value: $0) }
    }
}
