// VidLink.swift
// VidLink scraper implementation

import Foundation

struct VidLink: ScraperProtocol {
  let name = "VidLink"
  let baseURL = "https://vidlink.pro/"
  let supportedTypes: [ContentType] = [.movie, .tvShow]

  private let networkClient: NetworkClientProtocol
  private let tmdb: TMDBClient

  init(networkClient: NetworkClientProtocol = NetworkClient.shared, tmdb: TMDBClient = .shared) {
    self.networkClient = networkClient
    self.tmdb = tmdb
  }

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
    carousels.append(
      ContentCarousel(title: "Trending Movies", items: trendingMovies, type: .trending))
    carousels.append(
      ContentCarousel(title: "Trending TV Shows", items: trendingTV, type: .trending))
    carousels.append(ContentCarousel(title: "Popular Movies", items: popularMovies, type: .popular))
    carousels.append(ContentCarousel(title: "Popular TV Shows", items: popularTV, type: .popular))
    carousels.append(
      ContentCarousel(title: "Top Rated Movies", items: topRatedMovies, type: .topRated))
    carousels.append(
      ContentCarousel(title: "Top Rated TV Shows", items: topRatedTV, type: .topRated))
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
      id: "vidlink-search-\(q)-\(response.page)",
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

  func extractStreamingLinks(contentId: String, seasonId: String?, episodeId: String?) async throws
    -> [ExtractedLink]
  {
      let details = try await fetchContentDetails(id: contentId, type: (seasonId != nil && episodeId != nil) ? .tvShow : .movie)
    let mediaType: String =
      (seasonId != nil && episodeId != nil) || details.type == .tvShow ? "tv" : "movie"

    let encId = try await encryptTmdbId(contentId)

    let path: String
    if mediaType == "tv", let s = seasonId, let e = episodeId, !s.isEmpty, !e.isEmpty {
      path = "/api/b/tv/\(encId)/\(s)/\(e)"
    } else {
      path = "/api/b/movie/\(encId)"
    }
    let apiEndpoint = VidLinkAPIEndpoint(path: path)
    let data = try await networkClient.requestData(apiEndpoint)

    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else { return [] }

    var links: [ExtractedLink] = []

    func push(url: String, quality: String) {
      let type: ExtractedLink.LinkType = url.contains(".m3u8") ? .m3u8 : .direct
      let headers: [String: String] = {
        if url.contains(".m3u8") {
          return [
            "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
            "Accept": "application/vnd.apple.mpegurl,application/x-mpegURL,*/*",
            "Referer": "https://vidlink.pro/",
            "Origin": "https://vidlink.pro",
          ]
        }
        return [
          "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
          "Accept": "application/json,*/*",
          "Referer": "https://vidlink.pro/",
          "Origin": "https://vidlink.pro",
        ]
      }()
      links.append(
        ExtractedLink(
          url: url,
          quality: quality,
          server: name,
          requiresReferer: url.contains(".m3u8"),
          headers: headers,
          type: type,
          subtitles: nil
        )
      )
    }

    func processObject(_ obj: Any) {
      if let dict = obj as? [String: Any] {
        if let stream = dict["stream"] as? [String: Any] {
          if let qualities = stream["qualities"] as? [String: Any] {
            for (qKey, qVal) in qualities {
              if let qDict = qVal as? [String: Any], let u = qDict["url"] as? String {
                push(url: u, quality: mapQuality(qKey))
              }
            }
          }
          if let playlist = stream["playlist"] as? String {
            push(url: playlist, quality: "Auto")
          }
        } else if let url = dict["url"] as? String {
          push(url: url, quality: mapQuality(nil))
        } else if let streams = dict["streams"] as? [[String: Any]] {
          for s in streams {
            if let u = s["url"] as? String { push(url: u, quality: mapQuality(s["quality"])) }
          }
        } else if let linksArr = dict["links"] as? [[String: Any]] {
          for s in linksArr {
            if let u = s["url"] as? String { push(url: u, quality: mapQuality(s["quality"])) }
          }
        } else {
          for (k, v) in dict {
            if let str = v as? String, str.hasPrefix("http") || str.contains(".m3u8") {
              if str.contains(".srt") || str.contains(".vtt") { continue }
              if k.lowercased().contains("subtitle") || k.lowercased().contains("caption") {
                continue
              }
              push(url: str, quality: mapQuality(k))
            } else if let sub = v as? [String: Any] {
              processObject(sub)
            } else if let arr = v as? [Any] {
              for item in arr { processObject(item) }
            }
          }
        }
      } else if let arr = obj as? [Any] {
        for item in arr { processObject(item) }
      }
    }

    processObject(json)

    var seen = Set<String>()
    let unique = links.filter { l in
      if seen.contains(l.url) { return false }
      seen.insert(l.url)
      return true
    }
    let sorted = unique.sorted { a, b in qualityRank(a.quality) > qualityRank(b.quality) }
    return sorted
  }
}

private struct VidLinkAPIEndpoint: Endpoint {
  var baseURL: String { "https://vidlink.pro" }
  var path: String
  var method: HTTPMethod { .get }
  var headers: [String: String]? {
    [
      "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
      "Accept": "application/json,*/*",
      "Accept-Language": "en-US,en;q=0.5",
      "Accept-Encoding": "gzip, deflate",
      "Connection": "keep-alive",
      "Referer": "https://vidlink.pro/",
      "Origin": "https://vidlink.pro",
    ]
  }
  var queryItems: [URLQueryItem]? { nil }
  var body: Data? { nil }
}

private struct VidLinkEncryptEndpoint: Endpoint {
  var baseURL: String { "https://enc-dec.app" }
  var path: String { "/api/enc-vidlink" }
  var method: HTTPMethod { .get }
  var headers: [String: String]? {
    [
      "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
      "Accept": "application/json,*/*",
      "Connection": "keep-alive",
    ]
  }
  var queryItems: [URLQueryItem]? { [URLQueryItem(name: "text", value: text)] }
  var body: Data? { nil }
  let text: String
}

extension VidLink {
  fileprivate func encryptTmdbId(_ id: String) async throws -> String {
    let endpoint = VidLinkEncryptEndpoint(text: id)
    let data = try await networkClient.requestData(endpoint)
    guard let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
      let result = obj["result"] as? String
    else { throw ScraperError.extractionFailed("Encryption failed") }
    return result
  }

  fileprivate func mapQuality(_ any: Any?) -> String {
    guard let any = any else { return "Unknown" }
    let s = String(describing: any).lowercased()
    if s.contains("2160") || s.contains("4k") { return "4K" }
    if s.contains("1440") || s.contains("2k") { return "1440p" }
    if s.contains("1080") || s.contains("fhd") { return "1080p" }
    if s.contains("720") || s.contains("hd") { return "720p" }
    if s.contains("480") || s.contains("sd") { return "480p" }
    if s.contains("360") { return "360p" }
    if s.contains("240") { return "240p" }
    if let m = s.range(of: "(\\d{3,4})p?", options: .regularExpression) {
      let num = String(s[m]).replacingOccurrences(of: "p", with: "")
      if let v = Int(num) {
        if v >= 2160 { return "4K" }
        if v >= 1440 { return "1440p" }
        if v >= 1080 { return "1080p" }
        if v >= 720 { return "720p" }
        if v >= 480 { return "480p" }
        if v >= 360 { return "360p" }
        return "240p"
      }
    }
    return "Unknown"
  }

  fileprivate func qualityRank(_ q: String?) -> Int {
    guard var v = q?.lowercased() else { return 0 }
    if v == "adaptive" || v == "auto" { return 4000 }
    if v == "4k" { return 2160 }
    if v.hasSuffix("p") { v.removeLast() }
    switch v {
    case "2160": return 2160
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
