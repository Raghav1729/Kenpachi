import Foundation

struct SearchResult: Codable, Equatable {
    let query: String
    let results: [Content]
    let totalResults: Int
    let page: Int
    let totalPages: Int
    let filters: SearchFilters
    let searchTime: TimeInterval // in seconds
    let timestamp: Date
    
    // Categorized results
    let movies: [Content]
    let tvShows: [Content]
    let anime: [Content]
    let documentaries: [Content]
    
    // Suggestions and corrections
    let suggestions: [String]
    let didYouMean: String?
    let relatedQueries: [String]
    
    init(
        query: String,
        results: [Content],
        totalResults: Int,
        page: Int,
        totalPages: Int,
        filters: SearchFilters,
        searchTime: TimeInterval,
        timestamp: Date = Date(),
        suggestions: [String] = [],
        didYouMean: String? = nil,
        relatedQueries: [String] = []
    ) {
        self.query = query
        self.results = results
        self.totalResults = totalResults
        self.page = page
        self.totalPages = totalPages
        self.filters = filters
        self.searchTime = searchTime
        self.timestamp = timestamp
        self.suggestions = suggestions
        self.didYouMean = didYouMean
        self.relatedQueries = relatedQueries
        
        // Categorize results
        self.movies = results.filter { $0.contentType == .movie }
        self.tvShows = results.filter { $0.contentType == .tvShow }
        self.anime = results.filter { $0.contentType == .anime }
        self.documentaries = results.filter { $0.contentType == .documentary }
    }
}

struct SearchFilters: Codable, Equatable {
    let contentTypes: [ContentType]
    let genres: [Genre]
    let releaseYearRange: YearRange?
    let ratingRange: RatingRange?
    let sortBy: SearchSortOption
    let sortOrder: SortOrder
    let language: String?
    let region: String?
    let includeAdult: Bool
    
    init(
        contentTypes: [ContentType] = ContentType.allCases,
        genres: [Genre] = [],
        releaseYearRange: YearRange? = nil,
        ratingRange: RatingRange? = nil,
        sortBy: SearchSortOption = .relevance,
        sortOrder: SortOrder = .descending,
        language: String? = nil,
        region: String? = nil,
        includeAdult: Bool = false
    ) {
        self.contentTypes = contentTypes
        self.genres = genres
        self.releaseYearRange = releaseYearRange
        self.ratingRange = ratingRange
        self.sortBy = sortBy
        self.sortOrder = sortOrder
        self.language = language
        self.region = region
        self.includeAdult = includeAdult
    }
}

struct YearRange: Codable, Equatable {
    let startYear: Int
    let endYear: Int
    
    var isValid: Bool {
        startYear <= endYear && startYear >= 1900 && endYear <= Calendar.current.component(.year, from: Date()) + 5
    }
    
    var displayText: String {
        if startYear == endYear {
            return "\(startYear)"
        }
        return "\(startYear) - \(endYear)"
    }
}

struct RatingRange: Codable, Equatable {
    let minRating: Double
    let maxRating: Double
    
    var isValid: Bool {
        minRating >= 0 && maxRating <= 10 && minRating <= maxRating
    }
    
    var displayText: String {
        if minRating == maxRating {
            return String(format: "%.1f", minRating)
        }
        return String(format: "%.1f - %.1f", minRating, maxRating)
    }
}

enum SearchSortOption: String, Codable, CaseIterable {
    case relevance = "relevance"
    case popularity = "popularity"
    case rating = "rating"
    case releaseDate = "release_date"
    case title = "title"
    case runtime = "runtime"
    case voteCount = "vote_count"
    
    var displayName: String {
        switch self {
        case .relevance: return "Relevance"
        case .popularity: return "Popularity"
        case .rating: return "Rating"
        case .releaseDate: return "Release Date"
        case .title: return "Title"
        case .runtime: return "Runtime"
        case .voteCount: return "Vote Count"
        }
    }
}

enum SortOrder: String, Codable, CaseIterable {
    case ascending = "asc"
    case descending = "desc"
    
    var displayName: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }
    
    var symbol: String {
        switch self {
        case .ascending: return "↑"
        case .descending: return "↓"
        }
    }
}

// MARK: - Extensions
extension SearchResult {
    var isEmpty: Bool {
        results.isEmpty
    }
    
    var hasMorePages: Bool {
        page < totalPages
    }
    
    var formattedSearchTime: String {
        String(format: "%.3f seconds", searchTime)
    }
    
    var resultCountText: String {
        if totalResults == 0 {
            return "No results"
        } else if totalResults == 1 {
            return "1 result"
        } else {
            return "\(totalResults) results"
        }
    }
    
    var categoryBreakdown: [(ContentType, Int)] {
        return [
            (.movie, movies.count),
            (.tvShow, tvShows.count),
            (.anime, anime.count),
            (.documentary, documentaries.count)
        ].filter { $0.1 > 0 }
    }
    
    func results(for contentType: ContentType) -> [Content] {
        switch contentType {
        case .movie: return movies
        case .tvShow: return tvShows
        case .anime: return anime
        case .documentary: return documentaries
        case .short: return results.filter { $0.contentType == .short }
        }
    }
}

extension SearchFilters {
    static let `default` = SearchFilters()
    
    var isDefault: Bool {
        contentTypes == ContentType.allCases &&
        genres.isEmpty &&
        releaseYearRange == nil &&
        ratingRange == nil &&
        sortBy == .relevance &&
        sortOrder == .descending &&
        language == nil &&
        region == nil &&
        includeAdult == false
    }
    
    var activeFilterCount: Int {
        var count = 0
        
        if contentTypes != ContentType.allCases { count += 1 }
        if !genres.isEmpty { count += 1 }
        if releaseYearRange != nil { count += 1 }
        if ratingRange != nil { count += 1 }
        if sortBy != .relevance { count += 1 }
        if language != nil { count += 1 }
        if region != nil { count += 1 }
        if includeAdult { count += 1 }
        
        return count
    }
    
    func clearingAll() -> SearchFilters {
        return SearchFilters.default
    }
}

// MARK: - Sample Data
extension SearchResult {
    static let sample = SearchResult(
        query: "avatar",
        results: MockData.sampleMovies,
        totalResults: 3,
        page: 1,
        totalPages: 1,
        filters: SearchFilters.default,
        searchTime: 0.234,
        suggestions: ["avatar the last airbender", "avatar 2", "avatar movie"],
        didYouMean: nil,
        relatedQueries: ["james cameron", "pandora", "sci-fi movies"]
    )
}