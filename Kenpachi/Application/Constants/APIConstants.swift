import Foundation

struct APIConstants {

  // MARK: - Base URLs
  static let tmdbBaseURL = "https://api.themoviedb.org/3"
  static let imageBaseURL = "https://image.tmdb.org/t/p"

  // MARK: - API Keys (Replace with actual keys)
  static let tmdbAPIKey = "YOUR_TMDB_API_KEY"  // Replace with actual TMDB API key

  // MARK: - Headers
  static let userAgent = "Kenpachi/\(AppConstants.App.version) (iOS)"
  static let acceptLanguage = "en-US,en;q=0.9"

  // MARK: - Image Sizes
  struct ImageSizes {
    static let posterSizes = ["w92", "w154", "w185", "w342", "w500", "w780", "original"]
    static let backdropSizes = ["w300", "w780", "w1280", "original"]
    static let profileSizes = ["w45", "w185", "h632", "original"]
    static let logoSizes = ["w45", "w92", "w154", "w185", "w300", "w500", "original"]

    // Default sizes
    static let defaultPosterSize = "w500"
    static let defaultBackdropSize = "w1280"
    static let defaultProfileSize = "w185"
    static let defaultLogoSize = "w185"
  }

  // MARK: - Endpoints
  struct Endpoints {
    // Movies
    static let popularMovies = "/movie/popular"
    static let topRatedMovies = "/movie/top_rated"
    static let upcomingMovies = "/movie/upcoming"
    static let nowPlayingMovies = "/movie/now_playing"
    static let movieDetails = "/movie/{movie_id}"
    static let movieCredits = "/movie/{movie_id}/credits"
    static let movieVideos = "/movie/{movie_id}/videos"
    static let movieRecommendations = "/movie/{movie_id}/recommendations"
    static let movieSimilar = "/movie/{movie_id}/similar"

    // TV Shows
    static let popularTVShows = "/tv/popular"
    static let topRatedTVShows = "/tv/top_rated"
    static let onTheAirTVShows = "/tv/on_the_air"
    static let airingTodayTVShows = "/tv/airing_today"
    static let tvShowDetails = "/tv/{tv_id}"
    static let tvShowCredits = "/tv/{tv_id}/credits"
    static let tvShowVideos = "/tv/{tv_id}/videos"
    static let tvShowRecommendations = "/tv/{tv_id}/recommendations"
    static let tvShowSimilar = "/tv/{tv_id}/similar"
    static let tvShowSeasons = "/tv/{tv_id}/season/{season_number}"
    static let tvShowEpisodes = "/tv/{tv_id}/season/{season_number}/episode/{episode_number}"

    // Search
    static let searchMulti = "/search/multi"
    static let searchMovies = "/search/movie"
    static let searchTVShows = "/search/tv"
    static let searchPeople = "/search/person"

    // Trending
    static let trendingAll = "/trending/all/{time_window}"
    static let trendingMovies = "/trending/movie/{time_window}"
    static let trendingTVShows = "/trending/tv/{time_window}"
    static let trendingPeople = "/trending/person/{time_window}"

    // Genres
    static let movieGenres = "/genre/movie/list"
    static let tvGenres = "/genre/tv/list"

    // Discover
    static let discoverMovies = "/discover/movie"
    static let discoverTVShows = "/discover/tv"

    // People
    static let personDetails = "/person/{person_id}"
    static let personMovieCredits = "/person/{person_id}/movie_credits"
    static let personTVCredits = "/person/{person_id}/tv_credits"

    // Configuration
    static let configuration = "/configuration"
    static let countries = "/configuration/countries"
    static let languages = "/configuration/languages"
  }

  // MARK: - Request Parameters
  struct Parameters {
    static let apiKey = "api_key"
    static let language = "language"
    static let page = "page"
    static let query = "query"
    static let includeAdult = "include_adult"
    static let region = "region"
    static let year = "year"
    static let primaryReleaseYear = "primary_release_year"
    static let firstAirDateYear = "first_air_date_year"
    static let sortBy = "sort_by"
    static let withGenres = "with_genres"
    static let withoutGenres = "without_genres"
    static let withCompanies = "with_companies"
    static let withKeywords = "with_keywords"
    static let withPeople = "with_people"
    static let voteAverageGte = "vote_average.gte"
    static let voteAverageLte = "vote_average.lte"
    static let voteCountGte = "vote_count.gte"
    static let releaseDateGte = "release_date.gte"
    static let releaseDateLte = "release_date.lte"
  }

  // MARK: - Helper Methods
  static func imageURL(path: String, size: String = ImageSizes.defaultPosterSize) -> String {
    return "\(imageBaseURL)/\(size)\(path)"
  }

  static func posterURL(path: String, size: String = ImageSizes.defaultPosterSize) -> String {
    return imageURL(path: path, size: size)
  }

  static func backdropURL(path: String, size: String = ImageSizes.defaultBackdropSize) -> String {
    return imageURL(path: path, size: size)
  }

  static func profileURL(path: String, size: String = ImageSizes.defaultProfileSize) -> String {
    return imageURL(path: path, size: size)
  }
}
