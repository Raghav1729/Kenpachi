// Movies111.swift
// 111Movies scraper implementation
// Uses TMDB for content metadata and 111Movies API for streaming links with AES encryption

import CommonCrypto
import CryptoKit
import Foundation
import SwiftSoup

/// 111Movies scraper implementation
/// Uses TMDB API for content discovery and 111Movies API with AES encryption for streaming
struct Movies111: ScraperProtocol {
  // MARK: - Properties

  /// Scraper name
  let name = "Movies111"
  /// Base URL for 111Movies
  let baseURL = "https://111movies.com"
  /// Supported content types
  let supportedTypes: [ContentType] = [.movie, .tvShow]

  /// Network client for making requests
  private let networkClient: NetworkClientProtocol
  /// Extractor resolver for streaming links
  private let extractorResolver: ExtractorResolver
  /// TMDB client for content metadata
  private let tmdbClient: TMDBClient

  // Configuration URL
  private let configURL = "https://raw.githubusercontent.com/phisher98/TVVVV/main/output.json"

  // MARK: - Initialization

  init(
    networkClient: NetworkClientProtocol = NetworkClient.shared,
    extractorResolver: ExtractorResolver = ExtractorResolver(),
    tmdbClient: TMDBClient = TMDBClient.shared
  ) {
    self.networkClient = networkClient
    self.extractorResolver = extractorResolver
    self.tmdbClient = tmdbClient
  }

  // MARK: - ScraperProtocol Methods

  func fetchHomeContent() async throws -> [ContentCarousel] {
    async let trendingMovies = tmdbClient.fetchTrendingMovies(timeWindow: .day)
    async let trendingTVShows = tmdbClient.fetchTrendingTVShows(timeWindow: .day)
    async let popularMovies = tmdbClient.fetchTrendingMovies(timeWindow: .week)
    async let popularTVShows = tmdbClient.fetchTrendingTVShows(timeWindow: .week)

    let (movies, tvShows, weeklyMovies, weeklyTVShows) = try await (
      trendingMovies, trendingTVShows, popularMovies, popularTVShows
    )

    var carousels: [ContentCarousel] = []

    let heroItems = (movies.prefix(5) + tvShows.prefix(5)).shuffled().prefix(10)
    if !heroItems.isEmpty {
      carousels.append(ContentCarousel(title: "Featured", items: Array(heroItems), type: .hero))
    }

    if !movies.isEmpty {
      carousels.append(ContentCarousel(title: "Trending Movies", items: movies, type: .trending))
    }
    if !tvShows.isEmpty {
      carousels.append(ContentCarousel(title: "Trending TV Shows", items: tvShows, type: .trending))
    }
    if !weeklyMovies.isEmpty {
      carousels.append(
        ContentCarousel(title: "Popular Movies", items: weeklyMovies, type: .popular))
    }
    if !weeklyTVShows.isEmpty {
      carousels.append(
        ContentCarousel(title: "Popular TV Shows", items: weeklyTVShows, type: .popular))
    }

    return carousels
  }

  func search(query: String, page: Int = 1) async throws -> ContentSearchResult {
    let movieResults = try await tmdbClient.search(query: query, type: .movie)
    let tvResults = try await tmdbClient.search(query: query, type: .tvShow)
    let allResults = movieResults + tvResults

    return ContentSearchResult(
      id: "111movies-search-\(query)-\(page)",
      contents: allResults,
      totalResults: allResults.count,
      page: page,
      totalPages: 1
    )
  }

  func fetchContentDetails(id: String, type: ContentType?) async throws -> Content {
    if type == .tvShow {
      return try await tmdbClient.fetchTVShowDetails(id: id)
    } else {
      return try await tmdbClient.fetchMovieDetails(id: id)
    }
  }

  func extractStreamingLinks(
    contentId: String, seasonId: String? = nil, episodeId: String? = nil
  ) async throws -> [ExtractedLink] {
    let embedURL: String
    if let season = seasonId, let episode = episodeId {
      embedURL = "/tv/\(contentId)/\(season)/\(episode)"
    } else {
      embedURL = "/movie/\(contentId)"
    }

    print("\n🎬 [111Movies] ========== EXTRACT STREAMING LINKS START ==========")
    print("📥 [111Movies] Input - contentId: \(contentId)")
    
    // Step 1: Fetch configuration
    print("� [111MMovies] Step 1: Fetching configuration from remote")
    let configEndpoint = SimpleEndpoint(url: configURL)
    let configData = try await networkClient.requestData(configEndpoint)
    let config = try JSONDecoder().decode(Movies111Config.self, from: configData)
    print("✅ [111Movies] Step 1: Configuration loaded")

    // Step 2: Fetch embed page
    print("🔗 [111Movies] Step 2: Fetching embed page: \(baseURL)\(embedURL)")
    let endpoint = Movies111Endpoint(baseURL: baseURL, path: embedURL)
    let data = try await networkClient.requestData(endpoint)

    guard let html = String(data: data, encoding: .utf8) else {
      throw ScraperError.parsingFailed("Failed to decode HTML")
    }
    print("✅ [111Movies] Step 2: Received HTML (\(html.count) characters)")

    // Step 3: Extract raw data
    guard let rawData = extractRawData(from: html) else {
      throw ScraperError.parsingFailed("Failed to extract raw data")
    }
    print("✅ [111Movies] Step 3: Extracted raw data (\(rawData.count) characters)")

    // Step 4: Process encryption
    let encodedData = try processEncryptionPipeline(rawData: rawData, config: config)
    print("✅ [111Movies] Step 4: Encryption complete (\(encodedData.count) characters)")

    // Step 5: Fetch servers
    let serversPath = "/\(config.staticPath)/\(encodedData)/sr"
    print("🌐 [111Movies] Step 5: Fetching servers: \(baseURL)\(serversPath)")

    let serversEndpoint = Movies111Endpoint(
      baseURL: baseURL,
      path: serversPath,
      method: config.httpMethod == "GET" ? .get : .post,
      config: config
    )
    let serversData = try await networkClient.requestData(serversEndpoint)
    let servers = try JSONDecoder().decode([ServerEntry].self, from: serversData)
    print("✅ [111Movies] Step 5: Got \(servers.count) servers")

    // Step 6: Extract streams from all servers
    var extractedLinks: [ExtractedLink] = []
    
    for server in servers {
      let streamPath = "/\(config.staticPath)/\(server.data)"
      print("🎥 [111Movies] Step 6: Fetching stream from \(server.name): \(baseURL)\(streamPath)")

      let streamEndpoint = Movies111Endpoint(
        baseURL: baseURL,
        path: streamPath,
        method: config.httpMethod == "GET" ? .get : .post,
        config: config
      )
      
      do {
        let streamData = try await networkClient.requestData(streamEndpoint)
        let streamResponse = try JSONDecoder().decode(StreamResponse.self, from: streamData)
        
        if let url = streamResponse.url {
          extractedLinks.append(
            ExtractedLink(
              url: url,
              quality: "Auto",
              server: "111Movies - \(server.name)",
              requiresReferer: true,
              headers: [
                "Referer": baseURL + "/",
                "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36",
              ],
              type: .m3u8
            )
          )
          print("✅ [111Movies] Got streaming URL from \(server.name)")
        }
      } catch {
        print("⚠️ [111Movies] Failed to fetch stream from \(server.name): \(error)")
        continue
      }
    }

    guard !extractedLinks.isEmpty else {
      throw ScraperError.parsingFailed("No streaming links available")
    }

    print("✅ [111Movies] ========== EXTRACT STREAMING LINKS SUCCESS (\(extractedLinks.count) links) ==========\n")
    return extractedLinks
  }

  // MARK: - Helper Methods

  private func extractRawData(from html: String) -> String? {
    let pattern = #"\{\"data\":\"(.*?)\""#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
      let match = regex.firstMatch(
        in: html, options: [], range: NSRange(html.startIndex..., in: html)),
      let range = Range(match.range(at: 1), in: html)
    else {
      return nil
    }
    return String(html[range])
  }

  private func processEncryptionPipeline(rawData: String, config: Movies111Config) throws -> String {
    guard let aesKey = Data(hexString: config.keyHex),
      let aesIV = Data(hexString: config.ivHex)
    else {
      throw ScraperError.parsingFailed("Failed to prepare AES keys")
    }

    let aesEncrypted = try performAESCBCEncryption(data: rawData, key: aesKey, iv: aesIV)
    let hexString = aesEncrypted.map { String(format: "%02x", $0) }.joined()

    guard let xorKey = Data(hexString: config.xorKey) else {
      throw ScraperError.parsingFailed("Failed to prepare XOR key")
    }

    let xorResult = performXOROnHex(hexString: hexString, key: xorKey)
    let encoded = customBase64Encode(string: xorResult, src: config.src, dst: config.dst)

    return encoded
  }

  private func performAESCBCEncryption(data: String, key: Data, iv: Data) throws -> Data {
    guard let inputData = data.data(using: .utf8) else {
      throw ScraperError.parsingFailed("Failed to convert string to data")
    }

    let paddedData = addPKCS7Padding(data: inputData, blockSize: kCCBlockSizeAES128)

    let bufferSize = paddedData.count + kCCBlockSizeAES128
    var buffer = Data(count: bufferSize)
    var numBytesEncrypted: size_t = 0

    let cryptStatus = buffer.withUnsafeMutableBytes { bufferBytes in
      paddedData.withUnsafeBytes { dataBytes in
        key.withUnsafeBytes { keyBytes in
          iv.withUnsafeBytes { ivBytes in
            CCCrypt(
              CCOperation(kCCEncrypt),
              CCAlgorithm(kCCAlgorithmAES),
              CCOptions(0),
              keyBytes.baseAddress, key.count,
              ivBytes.baseAddress,
              dataBytes.baseAddress, paddedData.count,
              bufferBytes.baseAddress, bufferSize,
              &numBytesEncrypted
            )
          }
        }
      }
    }

    guard cryptStatus == kCCSuccess else {
      throw ScraperError.parsingFailed("AES encryption failed")
    }

    return buffer.prefix(numBytesEncrypted)
  }

  private func addPKCS7Padding(data: Data, blockSize: Int) -> Data {
    let paddingLength = blockSize - (data.count % blockSize)
    let paddingByte = UInt8(paddingLength)
    var paddedData = data
    paddedData.append(contentsOf: [UInt8](repeating: paddingByte, count: paddingLength))
    return paddedData
  }

  private func performXOROnHex(hexString: String, key: Data) -> String {
    var result = ""
    for (i, char) in hexString.enumerated() {
      let charCode = char.unicodeScalars.first!.value
      let xorByte = key[i % key.count]
      let xorResult = charCode ^ UInt32(xorByte)
      result.append(Character(UnicodeScalar(xorResult)!))
    }
    return result
  }

  private func customBase64Encode(string: String, src: String, dst: String) -> String {
    guard let data = string.data(using: .utf8) else { return "" }

    var base64 = data.base64EncodedString()
    base64 = base64.replacingOccurrences(of: "+", with: "-")
    base64 = base64.replacingOccurrences(of: "/", with: "_")
    base64 = base64.replacingOccurrences(of: "=", with: "")

    var result = ""
    for char in base64 {
      if let index = src.firstIndex(of: char) {
        let targetIndex = src.distance(from: src.startIndex, to: index)
        let targetChar = dst[dst.index(dst.startIndex, offsetBy: targetIndex)]
        result.append(targetChar)
      } else {
        result.append(char)
      }
    }

    return result
  }
}

// MARK: - Data Structures

private struct Movies111Config: Decodable {
  let src: String
  let dst: String
  let staticPath: String
  let httpMethod: String
  let keyHex: String
  let ivHex: String
  let xorKey: String
  let csrfToken: String
  let contentTypes: String

  enum CodingKeys: String, CodingKey {
    case src
    case dst
    case staticPath = "static_path"
    case httpMethod = "http_method"
    case keyHex = "key_hex"
    case ivHex = "iv_hex"
    case xorKey = "xor_key"
    case csrfToken = "csrf_token"
    case contentTypes = "content_types"
  }
}

private struct ServerEntry: Decodable {
  let name: String
  let description: String
  let image: String
  let data: String
}

private struct StreamResponse: Decodable {
  let url: String?
  let tracks: [SubtitleTrack]?
}

private struct SubtitleTrack: Decodable {
  let label: String?
  let file: String?
}

// MARK: - Endpoints

private struct SimpleEndpoint: Endpoint {
  let url: String
  
  var baseURL: String { url }
  var path: String { "" }
  var method: HTTPMethod { .get }
  var queryItems: [URLQueryItem]? { nil }
  var headers: [String: String]? { nil }
  var body: Data? { nil }
}

private struct Movies111Endpoint: Endpoint {
  let baseURL: String
  let path: String
  let method: HTTPMethod
  let config: Movies111Config?

  init(baseURL: String, path: String, method: HTTPMethod = .get, config: Movies111Config? = nil) {
    self.baseURL = baseURL
    self.path = path
    self.method = method
    self.config = config
  }

  var queryItems: [URLQueryItem]? { nil }
  var headers: [String: String]? {
    var headers = [
      "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36",
      "Referer": baseURL + "/",
      "X-Requested-With": "XMLHttpRequest"
    ]
    
    if let config = config {
      headers["Content-Type"] = config.contentTypes
      headers["X-Csrf-Token"] = config.csrfToken
    }
    
    return headers
  }
  var body: Data? { nil }
}
