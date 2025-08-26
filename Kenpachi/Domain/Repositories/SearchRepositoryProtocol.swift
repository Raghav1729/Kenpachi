import Foundation
import Combine

protocol SearchRepositoryProtocol {
    func searchContent(query: String, filters: SearchFilters) -> AnyPublisher<SearchResult, Error>
    func getSearchSuggestions(query: String) -> AnyPublisher<[String], Error>
    func saveRecentSearch(_ query: String) -> AnyPublisher<Void, Error>
    func getRecentSearches() -> AnyPublisher<[String], Error>
    func clearRecentSearches() -> AnyPublisher<Void, Error>
}