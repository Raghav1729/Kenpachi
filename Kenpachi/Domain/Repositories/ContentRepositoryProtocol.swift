import Foundation
import Combine

protocol ContentRepositoryProtocol {
    func getTrendingContent(timeWindow: TimeWindow) -> AnyPublisher<[Content], Error>
    func getPopularMovies(page: Int) -> AnyPublisher<[Movie], Error>
    func getPopularTVShows(page: Int) -> AnyPublisher<[TVShow], Error>
    func getContentDetails(id: String, type: ContentType) -> AnyPublisher<Content, Error>
    func getRelatedContent(for contentId: String, type: ContentType) -> AnyPublisher<[Content], Error>
    func getContentByGenre(_ genre: Genre, page: Int) -> AnyPublisher<[Content], Error>
}