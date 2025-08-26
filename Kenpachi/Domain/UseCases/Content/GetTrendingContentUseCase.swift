import Foundation
import Combine

protocol GetTrendingContentUseCaseProtocol {
    func execute(timeWindow: TimeWindow, page: Int) -> AnyPublisher<[Content], Error>
}

final class GetTrendingContentUseCase: GetTrendingContentUseCaseProtocol {
    private let contentRepository: ContentRepositoryProtocol
    
    init(contentRepository: ContentRepositoryProtocol) {
        self.contentRepository = contentRepository
    }
    
    func execute(timeWindow: TimeWindow = .week, page: Int = 1) -> AnyPublisher<[Content], Error> {
        return contentRepository.getTrendingContent(timeWindow: timeWindow)
            .map { content in
                // Apply any business logic here
                return content.filter { !$0.adult } // Filter adult content
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Mock Implementation
final class MockGetTrendingContentUseCase: GetTrendingContentUseCaseProtocol {
    func execute(timeWindow: TimeWindow = .week, page: Int = 1) -> AnyPublisher<[Content], Error> {
        // Simulate network delay
        return Just(MockData.sampleMovies + MockData.sampleTVShows)
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}