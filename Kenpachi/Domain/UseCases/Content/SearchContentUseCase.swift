import Foundation
import Combine

protocol SearchContentUseCaseProtocol {
    func execute(query: String, filters: SearchFilters, page: Int) -> AnyPublisher<SearchResult, Error>
    func getSuggestions(query: String) -> AnyPublisher<[String], Error>
}

final class SearchContentUseCase: SearchContentUseCaseProtocol {
    private let searchRepository: SearchRepositoryProtocol
    private let contentRepository: ContentRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        searchRepository: SearchRepositoryProtocol,
        contentRepository: ContentRepositoryProtocol
    ) {
        self.searchRepository = searchRepository
        self.contentRepository = contentRepository
    }
    
    func execute(query: String, filters: SearchFilters = SearchFilters(), page: Int = 1) -> AnyPublisher<SearchResult, Error> {
        let startTime = Date()
        
        return searchRepository.searchContent(query: query, filters: filters)
            .map { result in
                let searchTime = Date().timeIntervalSince(startTime)
                return SearchResult(
                    query: result.query,
                    results: result.results,
                    totalResults: result.totalResults,
                    page: result.page,
                    totalPages: result.totalPages,
                    filters: result.filters,
                    searchTime: searchTime,
                    suggestions: result.suggestions,
                    didYouMean: result.didYouMean,
                    relatedQueries: result.relatedQueries
                )
            }
            .handleEvents(receiveOutput: { _ in
                // Save recent search
                self.searchRepository.saveRecentSearch(query)
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &self.cancellables)
            })
            .eraseToAnyPublisher()
    }
    
    func getSuggestions(query: String) -> AnyPublisher<[String], Error> {
        guard query.count >= 2 else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        return searchRepository.getSearchSuggestions(query: query)
            .eraseToAnyPublisher()
    }
}

// MARK: - Mock Implementation
final class MockSearchContentUseCase: SearchContentUseCaseProtocol {
    func execute(query: String, filters: SearchFilters = SearchFilters(), page: Int = 1) -> AnyPublisher<SearchResult, Error> {
        let allContent = MockData.sampleMovies + MockData.sampleTVShows + MockData.sampleAnime
        
        // Simple search implementation
        let filteredContent = allContent.filter { content in
            content.title.localizedCaseInsensitiveContains(query) ||
            content.overview.localizedCaseInsensitiveContains(query)
        }
        
        let result = SearchResult(
            query: query,
            results: filteredContent,
            totalResults: filteredContent.count,
            page: 1,
            totalPages: 1,
            filters: filters,
            searchTime: 0.123,
            suggestions: generateSuggestions(for: query),
            didYouMean: generateDidYouMean(for: query),
            relatedQueries: generateRelatedQueries(for: query)
        )
        
        return Just(result)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func getSuggestions(query: String) -> AnyPublisher<[String], Error> {
        let suggestions = generateSuggestions(for: query)
        
        return Just(suggestions)
            .delay(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func generateSuggestions(for query: String) -> [String] {
        let commonSuggestions = [
            "avatar", "avatar the last airbender", "avatar 2",
            "marvel", "marvel movies", "marvel cinematic universe",
            "star wars", "star wars movies", "star wars series",
            "disney", "disney movies", "disney plus",
            "action movies", "comedy movies", "horror movies",
            "netflix series", "hbo series", "amazon prime"
        ]
        
        return commonSuggestions.filter { $0.localizedCaseInsensitiveContains(query) }
            .prefix(5)
            .map { $0 }
    }
    
    private func generateDidYouMean(for query: String) -> String? {
        let corrections: [String: String] = [
            "avater": "avatar",
            "mavel": "marvel",
            "starwars": "star wars",
            "disny": "disney"
        ]
        
        return corrections[query.lowercased()]
    }
    
    private func generateRelatedQueries(for query: String) -> [String] {
        let relatedQueries: [String: [String]] = [
            "avatar": ["james cameron", "pandora", "sci-fi movies"],
            "marvel": ["superhero movies", "mcu", "disney plus"],
            "star wars": ["sci-fi", "space movies", "disney plus"],
            "disney": ["family movies", "animation", "pixar"]
        ]
        
        return relatedQueries[query.lowercased()] ?? []
    }
}