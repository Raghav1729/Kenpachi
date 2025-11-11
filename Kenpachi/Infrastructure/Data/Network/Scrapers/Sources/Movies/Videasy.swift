// Videasy.swift
// Videasy scraper implementation (ScraperProtocol)
// Host-only extractor: uses Videasy backend to retrieve encrypted sources and decrypts via AES-GCM

import Foundation
import CryptoKit

struct VidEasy: ScraperProtocol {
  let name = "VidEasy"
  let baseURL = "https://videasy.net/"
  let supportedTypes: [ContentType] = [.movie, .tvShow]

  private let networkClient: NetworkClientProtocol
  private let tmdb: TMDBClient

  init(networkClient: NetworkClientProtocol = NetworkClient.shared, tmdb: TMDBClient = .shared) {
    self.networkClient = networkClient
    self.tmdb = tmdb
  }

  // Reuse TMDB-based home/search/details like MP4Hydra
  func fetchHomeContent() async throws -> [ContentCarousel] {
    let topRatedMovies = try await tmdb.fetchTopRatedMovies()
    let topRatedTV = try await tmdb.fetchTopRatedTVShows()
    let popularMovies = try await tmdb.fetchPopularMovies()
    let popularTV = try await tmdb.fetchPopularTVShows()
    let trendingMovies = try await tmdb.fetchTrendingMovies(timeWindow: .day)
    let trendingTV = try await tmdb.fetchTrendingTVShows(timeWindow: .day)

    var carousels: [ContentCarousel] = []
    let heroItems = (topRatedMovies + topRatedTV)
      .sorted { ($0.voteAverage ?? 0) > ($1.voteAverage ?? 0) }
      .prefix(10)
    carousels.append(ContentCarousel(title: "Featured", items: Array(heroItems), type: .hero))
    carousels.append(ContentCarousel(title: "Trending Movies", items: trendingMovies, type: .trending))
    carousels.append(ContentCarousel(title: "Trending TV Shows", items: trendingTV, type: .trending))
    carousels.append(ContentCarousel(title: "Popular Movies", items: popularMovies, type: .popular))
    carousels.append(ContentCarousel(title: "Popular TV Shows", items: popularTV, type: .popular))
    carousels.append(ContentCarousel(title: "Top Rated Movies", items: topRatedMovies, type: .topRated))
    carousels.append(ContentCarousel(title: "Top Rated TV Shows", items: topRatedTV, type: .topRated))
    return carousels
  }

  func search(query: String, page: Int) async throws -> ContentSearchResult {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !q.isEmpty else { return ContentSearchResult(contents: []) }
    let response = try await tmdb.search(query: q, page: page)
    let searchResult: [Content] = response.results
      .filter { $0.mediaType != "person" }
      .compactMap { $0.toContent() }
    return ContentSearchResult(
      id: "videasy-search-\(q)-\(response.page)",
      contents: searchResult,
      totalResults: response.totalResults,
      page: response.page,
      totalPages: response.totalPages
    )
  }

  func fetchContentDetails(id: String, type: ContentType?) async throws -> Content {
    if let t = type {
      switch t {
      case .movie:
        return try await tmdb.fetchMovieDetails(id: id)
      case .tvShow:
        return try await tmdb.fetchTVShowDetails(id: id)
      case .anime:
        throw ScraperError.invalidConfiguration
      }
    }
    do { return try await tmdb.fetchMovieDetails(id: id) } catch {}
    return try await tmdb.fetchTVShowDetails(id: id)
  }

  // MARK: - Extraction
  func extractStreamingLinks(contentId: String, seasonId: String?, episodeId: String?) async throws -> [ExtractedLink] {
    // Fetch media details from TMDB to get title/year and determine media type
    let details = try await fetchContentDetails(id: contentId, type: nil)
    let mediaType: String = (seasonId != nil && episodeId != nil) || details.type == .tvShow ? "tv" : "movie"
    let title = details.title
    let year = details.releaseYear ?? ""
    let tmdbId = contentId
    let imdbId = "" // Not available in current Content model

    // Define Videasy servers (subset per JS provider)
    struct ServerConfig { let name: String; let url: String; let language: String; let moviesOnly: Bool; let params: [String: String]? }
    let servers: [ServerConfig] = [
      .init(name: "Neon", url: "https://api.videasy.net/myflixerzupcloud/sources-with-title", language: "Original", moviesOnly: false, params: nil),
      .init(name: "Sage", url: "https://api.videasy.net/1movies/sources-with-title", language: "Original", moviesOnly: false, params: nil),
      .init(name: "Cypher", url: "https://api.videasy.net/moviebox/sources-with-title", language: "Original", moviesOnly: false, params: nil),
      .init(name: "Yoru", url: "https://api.videasy.net/cdn/sources-with-title", language: "Original", moviesOnly: true, params: nil),
      .init(name: "Reyna", url: "https://api2.videasy.net/primewire/sources-with-title", language: "Original", moviesOnly: false, params: nil),
      .init(name: "Omen", url: "https://api.videasy.net/onionplay/sources-with-title", language: "Original", moviesOnly: false, params: nil),
      .init(name: "Breach", url: "https://api.videasy.net/m4uhd/sources-with-title", language: "Original", moviesOnly: false, params: nil),
      .init(name: "Vyse", url: "https://api.videasy.net/hdmovie/sources-with-title", language: "Original", moviesOnly: false, params: nil),
      .init(name: "Fade", url: "https://api.videasy.net/hdmovie/sources-with-title", language: "Hindi", moviesOnly: false, params: nil)
    ]

    // Helper: build endpoint for server GET (returns encrypted text)
    func makeServerEndpoint(_ cfg: ServerConfig) throws -> Endpoint {
      guard let u = URL(string: cfg.url) else { throw ScraperError.invalidConfiguration }
      let base = "\(u.scheme ?? "https")://\(u.host ?? "")"
      var query: [URLQueryItem] = [
        URLQueryItem(name: "title", value: title),
        URLQueryItem(name: "mediaType", value: mediaType),
        URLQueryItem(name: "year", value: year),
        URLQueryItem(name: "tmdbId", value: tmdbId),
        URLQueryItem(name: "imdbId", value: imdbId)
      ]
      if mediaType == "tv", let s = seasonId, let e = episodeId {
        query.append(contentsOf: [URLQueryItem(name: "seasonId", value: s), URLQueryItem(name: "episodeId", value: e)])
      }
      if let params = cfg.params {
        for (k, v) in params { query.append(URLQueryItem(name: k, value: v)) }
      }
      return VideasyServerTextEndpoint(
        baseURL: base,
        path: u.path,
        queryItems: query
      )
    }

    // Helper: decrypt via enc-dec.app
    struct DecResponse: Decodable { let result: DecodedPayload? }
    struct DecodedPayload: Decodable { let sources: [DecodedSource]? }
    struct DecodedSource: Decodable { let url: String?; let quality: String?; let language: String?; let type: String? }

    func decryptText(_ encrypted: String) async throws -> DecodedPayload? {
      let endpoint = VideasyDecryptEndpoint(text: encrypted, id: tmdbId)
      let data = try await networkClient.requestData(endpoint)
      let dec = try JSONDecoder().decode(DecResponse.self, from: data)
      return dec.result
    }

    // Aggregate results
    var all: [ExtractedLink] = []

    for cfg in servers {
      if mediaType == "tv" && cfg.moviesOnly { continue }
      do {
        // GET encrypted text
        let encData = try await networkClient.requestData(try makeServerEndpoint(cfg))
        guard let encrypted = String(data: encData, encoding: .utf8), !encrypted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
        // Decrypt
        guard let payload = try await decryptText(encrypted) else { continue }

        print(payload)
        let sources = payload.sources ?? []
        if sources.isEmpty { continue }

        // Map to ExtractedLink
        for s in sources {
          guard let url = s.url else { continue }
          let quality = extractQuality(from: url, extra: s.quality)
          let type: ExtractedLink.LinkType = url.contains(".m3u8") ? .m3u8 : .direct
          let headers: [String: String] = {
            if url.contains(".m3u8") {
              return [
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
                "Accept": "application/vnd.apple.mpegurl,application/x-mpegURL,*/*",
                "Referer": "https://videasy.net/"
              ]
            } else if url.contains(".mp4") {
              return [
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
                "Accept": "video/mp4,*/*",
                "Range": "bytes=0-"
              ]
            } else if url.contains(".mkv") {
              return [
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
                "Accept": "video/x-matroska,*/*",
                "Range": "bytes=0-"
              ]
            }
            return ["User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36"]
          }()
          let serverName = "VidEasy \(cfg.name) (\(cfg.language))"
          all.append(
            ExtractedLink(
              url: url,
              quality: quality,
              server: serverName,
              requiresReferer: url.contains(".m3u8"),
              headers: headers,
              type: type,
              subtitles: nil
            )
          )
        }
      } catch {
        // Ignore individual server failures
        continue
      }
    }

    // Dedupe by URL
    var seen = Set<String>()
    let unique = all.filter { link in
      if seen.contains(link.url) { return false }
      seen.insert(link.url)
      return true
    }
    // Sort by quality desc (Adaptive/Auto first)
    let sorted = unique.sorted { lhs, rhs in
      qualityRank(lhs.quality) > qualityRank(rhs.quality)
    }
    return sorted
  }
}

// MARK: - Videasy dynamic endpoints
private struct VideasyServerTextEndpoint: Endpoint {
  var baseURL: String
  var path: String
  var method: HTTPMethod { .get }
  var headers: [String: String]? {
    [
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
      "Connection": "keep-alive"
    ]
  }
  var queryItems: [URLQueryItem]?
  var body: Data? { nil }
}

private struct VideasyDecryptEndpoint: Endpoint {
  var baseURL: String { "https://enc-dec.app" }
  var path: String { "/api/dec-videasy" }
  var method: HTTPMethod { .post }
  var headers: [String : String]? {
    [
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
      "Connection": "keep-alive",
      "Content-Type": "application/json"
    ]
  }
  var queryItems: [URLQueryItem]? { nil }
  var body: Data? {
    let payload: [String: String] = ["text": text, "id": id]
    return try? JSONSerialization.data(withJSONObject: payload, options: [])
  }
  let text: String
  let id: String
}

// MARK: - Helpers
private extension VidEasy {
  func extractQuality(from url: String, extra: String?) -> String? {
    // Base64 encoded markers and patterns
    let patterns: [String] = [
      #"(\\d{3,4})p"#,
      #"(\\d{3,4})k"#,
      #"quality[_-]?(\\d{3,4})"#,
      #"res[_-]?(\\d{3,4})"#,
      #"(\\d{3,4})x\\d{3,4}"#,
      "/MTA4MA==/",
      "/NzIw/",
      "/MzYw/",
      "/NDgw/",
      "/MTkyMA==/",
      "/MTI4MA==/"
    ]
    for pat in patterns {
      if pat.hasPrefix("/") && pat.hasSuffix("/") {
        if url.contains(pat.trimmingCharacters(in: CharacterSet(charactersIn: "/"))) {
          if pat.contains("MTA4MA==") || pat.contains("MTkyMA==") { return "1080p" }
          if pat.contains("NzIw") || pat.contains("MTI4MA==") { return "720p" }
          if pat.contains("NDgw") { return "480p" }
          if pat.contains("MzYw") { return "360p" }
        }
      } else if let regex = try? NSRegularExpression(pattern: pat, options: .caseInsensitive) {
        let range = NSRange(url.startIndex..<url.endIndex, in: url)
        if let m = regex.firstMatch(in: url, options: [], range: range), m.numberOfRanges > 1,
           let r = Range(m.range(at: 1), in: url) {
          let q = String(url[r])
          if let num = Int(q), (240...4320).contains(num) { return "\(num)p" }
        }
      }
    }
    if url.contains("1080") || url.contains("1920") { return "1080p" }
    if url.contains("720") || url.contains("1280") { return "720p" }
    if url.contains("480") || url.contains("854") { return "480p" }
    if url.contains("360") || url.contains("640") { return "360p" }
    if url.contains("240") || url.contains("426") { return "240p" }
    if let extra = extra, !extra.isEmpty {
      let lower = extra.lowercased()
      if lower == "auto" { return "Auto" }
      if lower == "adaptive" { return "Adaptive" }
      if let num = Int(lower.filter({ $0.isNumber })), (240...4320).contains(num) { return "\(num)p" }
    }
    return "unknown"
  }

  func qualityRank(_ q: String?) -> Int {
    guard var v = q?.lowercased() else { return 0 }
    if v == "adaptive" || v == "auto" { return 4000 }
    if v.hasSuffix("p") { v.removeLast() }
    switch v {
    case "4k", "2160": return 2160
    case "1440": return 1440
    case "1080": return 1080
    case "720": return 720
    case "480": return 480
    case "360": return 360
    case "240": return 240
    case "unknown": return 0
    default: return Int(v) ?? 1
    }
  }
}
