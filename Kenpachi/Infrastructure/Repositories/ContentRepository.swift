import Combine
import Foundation

final class ContentRepository: ContentRepositoryProtocol {
    
    init() {}

    func getTrendingContent(timeWindow: TimeWindow) -> AnyPublisher<[Content], Error> {
        // Mock implementation using existing mock data
        let content = MockData.sampleMovies + MockData.sampleTVShows + MockData.sampleAnime
        
        return Just(content)
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getPopularMovies(page: Int) -> AnyPublisher<[Movie], Error> {
        // Mock implementation - convert Content to Movie
        let movies = MockData.sampleMovies.compactMap { content -> Movie? in
            guard content.contentType == .movie else { return nil }
            return Movie(
                id: content.id,
                title: content.title,
                originalTitle: content.title,
                overview: content.overview,
                posterPath: content.posterURL,
                backdropPath: content.backdropURL,
                releaseDate: content.releaseDate,
                genres: content.genres,
                runtime: content.runtime,
                budget: nil,
                revenue: nil,
                imdbId: nil,
                originalLanguage: content.originalLanguage ?? "en",
                popularity: content.popularity ?? 0,
                voteAverage: content.rating,
                voteCount: content.voteCount ?? 0,
                adult: content.adult,
                video: false,
                tagline: content.tagline,
                status: .released,
                homepage: content.homepage,
                belongsToCollection: nil,
                productionCompanies: content.productionCompanies ?? [],
                productionCountries: content.productionCountries ?? [],
                spokenLanguages: content.spokenLanguages ?? [],
                cast: content.cast,
                crew: content.crew,
                keywords: content.keywords,
                videos: content.videos,
                images: content.images,
                recommendations: nil,
                similar: nil,
                streamingSources: nil,
                watchProviders: nil
            )
        }
        
        return Just(movies)
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getPopularTVShows(page: Int) -> AnyPublisher<[TVShow], Error> {
        // Mock implementation - convert Content to TVShow
        let tvShows = MockData.sampleTVShows.compactMap { content -> TVShow? in
            guard content.contentType == .tvShow else { return nil }
            return TVShow(
                id: content.id,
                name: content.title,
                originalName: content.title,
                overview: content.overview,
                posterPath: content.posterURL,
                backdropPath: content.backdropURL,
                firstAirDate: content.firstAirDate,
                lastAirDate: content.lastAirDate,
                genres: content.genres,
                episodeRunTime: [45], // Default runtime
                numberOfEpisodes: content.numberOfEpisodes ?? 10,
                numberOfSeasons: content.numberOfSeasons ?? 1,
                originCountry: ["US"],
                originalLanguage: content.originalLanguage ?? "en",
                popularity: content.popularity ?? 0,
                voteAverage: content.rating,
                voteCount: content.voteCount ?? 0,
                adult: content.adult,
                inProduction: content.inProduction ?? false,
                status: .ended,
                type: .scripted,
                homepage: content.homepage,
                tagline: content.tagline,
                createdBy: [],
                networks: [],
                productionCompanies: content.productionCompanies ?? [],
                productionCountries: content.productionCountries ?? [],
                spokenLanguages: content.spokenLanguages ?? [],
                seasons: nil,
                nextEpisodeToAir: nil,
                lastEpisodeToAir: nil,
                cast: content.cast,
                crew: content.crew,
                keywords: content.keywords,
                videos: content.videos,
                images: content.images,
                recommendations: nil,
                similar: nil,
                streamingSources: nil,
                watchProviders: nil
            )
        }
        
        return Just(tvShows)
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getContentDetails(id: String, type: ContentType) -> AnyPublisher<Content, Error> {
        // Mock implementation - find content by ID
        let allContent = MockData.sampleMovies + MockData.sampleTVShows + MockData.sampleAnime
        
        if let content = allContent.first(where: { $0.id == id }) {
            return Just(content)
                .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            return Fail(error: ContentError.notFound)
                .eraseToAnyPublisher()
        }
    }

    func getRelatedContent(for contentId: String, type: ContentType) -> AnyPublisher<[Content], Error> {
        // Mock implementation - return random content of same type
        let allContent = MockData.sampleMovies + MockData.sampleTVShows + MockData.sampleAnime
        let relatedContent = allContent.filter { $0.contentType == type && $0.id != contentId }
        
        return Just(Array(relatedContent.prefix(5)))
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getContentByGenre(_ genre: Genre, page: Int) -> AnyPublisher<[Content], Error> {
        // Mock implementation - filter by genre
        let allContent = MockData.sampleMovies + MockData.sampleTVShows + MockData.sampleAnime
        let filteredContent = allContent.filter { content in
            content.genres.contains { $0.id == genre.id }
        }
        
        return Just(filteredContent)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

enum ContentError: Error {
    case notFound
    case networkError
    case decodingError
}
