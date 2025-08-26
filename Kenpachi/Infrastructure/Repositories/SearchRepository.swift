import Foundation
import Combine

final class SearchRepository: SearchRepositoryProtocol {
    
    init() {}
    
    func searchContent(query: String, filters: SearchFilters) -> AnyPublisher<SearchResult, Error> {
        // Mock implementation for now
        let allContent = MockData.sampleMovies + MockData.sampleTVShows + MockData.sampleAnime
        
        let filteredContent = allContent.filter { content in
            let matchesQuery = content.title.localizedCaseInsensitiveContains(query) ||
                             content.overview.localizedCaseInsensitiveContains(query)
            
            let matchesContentType = filters.contentTypes.contains(content.contentType)
            
            let matchesGenres = filters.genres.isEmpty || 
                              !Set(content.genres).isDisjoint(with: Set(filters.genres))
            
            return matchesQuery && matchesContentType && matchesGenres
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
    
    func getSearchSuggestions(query: String) -> AnyPublisher<[String], Error> {
        let suggestions = generateSuggestions(for: query)
        
        return Just(suggestions)
            .delay(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func saveRecentSearch(_ query: String) -> AnyPublisher<Void, Error> {
        // Mock implementation - in real app would save to UserDefaults or database
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func getRecentSearches() -> AnyPublisher<[String], Error> {
        // Mock implementation
        let recentSearches = ["Avatar", "Marvel", "Star Wars", "Disney"]
        
        return Just(recentSearches)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func clearRecentSearches() -> AnyPublisher<Void, Error> {
        // Mock implementation
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helper Methods
    
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