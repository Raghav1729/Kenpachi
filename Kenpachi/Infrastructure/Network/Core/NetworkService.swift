import Foundation
import Combine

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, NetworkError>
    func download(from url: URL, to destination: URL) -> AnyPublisher<URL, NetworkError>
}

final class NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, NetworkError> {
        guard let request = buildRequest(from: endpoint) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: T.self, decoder: decoder)
            .mapError { error in
                if error is DecodingError {
                    return NetworkError.decodingError
                }
                return NetworkError.requestFailed
            }
            .eraseToAnyPublisher()
    }
    
    func download(from url: URL, to destination: URL) -> AnyPublisher<URL, NetworkError> {
        return Future { promise in
            let task = self.session.downloadTask(with: url) { tempURL, response, error in
                if let error = error {
                    promise(.failure(.downloadFailed))
                    return
                }
                
                guard let tempURL = tempURL else {
                    promise(.failure(.downloadFailed))
                    return
                }
                
                do {
                    try FileManager.default.moveItem(at: tempURL, to: destination)
                    promise(.success(destination))
                } catch {
                    promise(.failure(.downloadFailed))
                }
            }
            task.resume()
        }
        .eraseToAnyPublisher()
    }
    
    private func buildRequest(from endpoint: Endpoint) -> URLRequest? {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            return nil
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = endpoint.parameters?.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        
        guard let finalURL = components?.url else { return nil }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        request.timeoutInterval = AppConfiguration.requestTimeout
        
        return request
    }
}

protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}