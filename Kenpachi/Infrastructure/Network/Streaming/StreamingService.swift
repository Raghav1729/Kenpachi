import Foundation
import Combine
import AVFoundation

protocol StreamingServiceProtocol {
    func getVideoSources(for contentId: String) -> AnyPublisher<[VideoSource], StreamingError>
    func getStreamingURL(for source: VideoSource) -> AnyPublisher<URL, StreamingError>
    func validateStreamingURL(_ url: URL) -> AnyPublisher<Bool, StreamingError>
}

final class StreamingService: StreamingServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let cache = NSCache<NSString, NSArray>()
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
        setupCache()
    }
    
    func getVideoSources(for contentId: String) -> AnyPublisher<[VideoSource], StreamingError> {
        // Check cache first
        if let cachedSources = cache.object(forKey: contentId as NSString) as? [VideoSource] {
            return Just(cachedSources)
                .setFailureType(to: StreamingError.self)
                .eraseToAnyPublisher()
        }
        
        // For demo purposes, return mock video sources
        // In a real app, this would call your streaming API
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let sources = self.generateMockVideoSources(for: contentId)
                self.cache.setObject(sources as NSArray, forKey: contentId as NSString)
                promise(.success(sources))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getStreamingURL(for source: VideoSource) -> AnyPublisher<URL, StreamingError> {
        return Future { promise in
            // Use the URL from the VideoSource
            guard let url = URL(string: source.url) else {
                promise(.failure(.invalidURL))
                return
            }
            
            promise(.success(url))
        }
        .eraseToAnyPublisher()
    }
    
    func validateStreamingURL(_ url: URL) -> AnyPublisher<Bool, StreamingError> {
        return Future { promise in
            let asset = AVAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["playable"]) {
                var error: NSError?
                let status = asset.statusOfValue(forKey: "playable", error: &error)
                
                DispatchQueue.main.async {
                    switch status {
                    case .loaded:
                        promise(.success(asset.isPlayable))
                    case .failed, .cancelled:
                        promise(.failure(.validationFailed))
                    default:
                        promise(.failure(.validationFailed))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func setupCache() {
        cache.countLimit = 50
        cache.totalCostLimit = 1024 * 1024 * 10 // 10MB
    }
    
    private func generateMockVideoSources(for contentId: String) -> [VideoSource] {
        return [
            VideoSource(
                id: "\(contentId)_4k",
                url: getSampleVideoURL(for: .uhd4k),
                quality: .uhd4k,
                type: .mp4,
                server: "Primary Server",
                isM3U8: false,
                headers: nil
            ),
            VideoSource(
                id: "\(contentId)_1080p",
                url: getSampleVideoURL(for: .hd1080),
                quality: .hd1080,
                type: .mp4,
                server: "Primary Server",
                isM3U8: false,
                headers: nil
            ),
            VideoSource(
                id: "\(contentId)_720p",
                url: getSampleVideoURL(for: .hd720),
                quality: .hd720,
                type: .mp4,
                server: "Backup Server",
                isM3U8: false,
                headers: nil
            ),
            VideoSource(
                id: "\(contentId)_480p",
                url: getSampleVideoURL(for: .sd480),
                quality: .sd480,
                type: .mp4,
                server: "Mobile Server",
                isM3U8: false,
                headers: nil
            )
        ]
    }
    
    private func getSampleVideoURL(for quality: StreamingQuality) -> String {
        // Sample video URLs for different qualities
        switch quality {
        case .uhd4k, .uhd8k, .hd1080:
            return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        case .hd720:
            return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
        case .sd480, .sd360:
            return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
        case .auto:
            return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        }
    }
}

enum StreamingError: Error, LocalizedError {
    case invalidURL
    case noSourcesAvailable
    case validationFailed
    case networkError
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid streaming URL"
        case .noSourcesAvailable:
            return "No video sources available"
        case .validationFailed:
            return "Failed to validate streaming URL"
        case .networkError:
            return "Network connection error"
        case .serverError:
            return "Server error occurred"
        }
    }
}