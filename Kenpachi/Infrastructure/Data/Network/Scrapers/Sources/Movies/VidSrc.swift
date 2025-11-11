// VidSrc.swift
// VidSrc scraper implementation based on VidLink pattern and provided JS extraction logic

import Foundation
import SwiftSoup

struct VidSrc: ScraperProtocol {
  let name = "VidSrc"
  let baseURL = "https://vidsrc-embed.ru/"
  let supportedTypes: [ContentType] = [.movie, .tvShow]

  private let networkClient: NetworkClientProtocol
  private let tmdb: TMDBClient

  init(networkClient: NetworkClientProtocol = NetworkClient.shared, tmdb: TMDBClient = .shared) {
    self.networkClient = networkClient
    self.tmdb = tmdb
  }

  // Home uses TMDB similar to VidLink
  func fetchHomeContent() async throws -> [ContentCarousel] {
    let topRatedMovies = try await tmdb.fetchTopRatedMovies()
    let topRatedTV = try await tmdb.fetchTopRatedTVShows()
    let trendingMovies = try await tmdb.fetchTrendingMovies(timeWindow: .day)
    let trendingTV = try await tmdb.fetchTrendingTVShows(timeWindow: .day)

    var carousels: [ContentCarousel] = []
    let heroItems = (topRatedMovies + topRatedTV)
      .sorted { ($0.voteAverage ?? 0) > ($1.voteAverage ?? 0) }
      .prefix(10)
    carousels.append(ContentCarousel(title: "Featured", items: Array(heroItems), type: .hero))
    carousels.append(ContentCarousel(title: "Trending Movies", items: trendingMovies, type: .trending))
    carousels.append(ContentCarousel(title: "Trending TV Shows", items: trendingTV, type: .trending))
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
      id: "vidsrc-search-\(q)-\(response.page)",
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

  func extractStreamingLinks(contentId: String, seasonId: String?, episodeId: String?) async throws -> [ExtractedLink] {
    // Determine type from provided params
    let isTV = (seasonId != nil && episodeId != nil)
    let base = "https://vidsrc-embed.ru/embed/"
    let url: String = {
      if isTV, let s = seasonId, let e = episodeId, !s.isEmpty, !e.isEmpty {
        return "\(base)tv?tmdb=\(contentId)&season=\(s)&episode=\(e)"
      } else {
        return "\(base)movie?tmdb=\(contentId)"
      }
    }()

    let headers: [String: String] = [
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
      "Referer": "https://vidsrc-embed.ru/",
    ]

    // Step 1: Fetch embed iframe
    let html1Data = try await networkClient.requestData(VidSrcURLEndpoint(url: url, method: .get, headers: headers))
    let html1 = String(data: html1Data, encoding: .utf8) ?? ""
    guard let match1 = matchFirst(in: html1, pattern: #"src=\"(.*?)\""#) else {
      throw ScraperError.extractionFailed("VidSrc: No source iframe found")
    }

    // Construct the RCP base
    let baseHost = "https://vidsrc-embed.ru"
    let urlRCP: String = {
      if match1.hasPrefix("http") { return match1 }
      if match1.hasPrefix("/embed") { return baseHost + match1 }
      return "https:" + match1
    }()

    // Parse servers
    var rcpTargets: [(name: String, url: String)] = []
    do {
      let doc = try SwiftSoup.parse(html1)
      let servers = try doc.select(".serversList .server").array()
      let prefix = splitBeforeRCPSegment(urlRCP)
      for s in servers {
        let name = try s.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let hash = try s.attr("data-hash")
        if !name.isEmpty, !hash.isEmpty {
          rcpTargets.append((name: name, url: prefix + "rcp/" + hash))
        }
      }
    } catch {
      // continue with empty list
    }

    var links: [ExtractedLink] = []

    // Step 2 and 3: For each RCP, resolve to pro/src rcp and extract m3u8
    for target in rcpTargets {
      do {
        // Fetch RCP page
        let html2Data = try await networkClient.requestData(
          VidSrcURLEndpoint(url: target.url, method: .get, headers: headers.merging(["Referer": url]) { $1 })
        )
        let html2 = String(data: html2Data, encoding: .utf8) ?? ""
        guard let match2 = matchFirst(in: html2, pattern: #"src.*['\"](\/(?:src|pro)rcp.*?)['\"]"#) else { continue }
        let urlPRORCP = splitBeforeRCPSegment(target.url) + match2

        // Fetch pro/src rcp page
        let html3Data = try await networkClient.requestData(
          VidSrcURLEndpoint(url: urlPRORCP, method: .get, headers: headers.merging(["Referer": target.url]) { $1 })
        )
        let html3 = String(data: html3Data, encoding: .utf8) ?? ""
        if let m3u8 = matchFirst(in: html3, pattern: #"file:\s*['\"]([^'\"]+\.m3u8)['\"]"#) {
          let playbackHeaders: [String: String] = [
            "User-Agent": headers["User-Agent"]!,
            "Accept": "application/vnd.apple.mpegurl,application/x-mpegURL,*/*",
            "Referer": splitBeforeRCPSegment(urlRCP),
          ]
          links.append(ExtractedLink(
            url: m3u8,
            quality: "default",
            server: target.name,
            requiresReferer: true,
            headers: playbackHeaders,
            type: .m3u8,
            subtitles: nil
          ))
        }
      } catch {
        continue
      }
    }

    // Dedupe
    var seen = Set<String>()
    let unique = links.filter { l in
      if seen.contains(l.url) { return false }
      seen.insert(l.url)
      return true
    }
    return unique
  }
}

private struct VidSrcURLEndpoint: Endpoint {
  let url: String
  let method: HTTPMethod
  var headers: [String: String]?
  var body: Data? { nil }
  var baseURL: String { URL(string: url)?.origin ?? "" }
  var path: String { URL(string: url)?.pathWithQuery ?? "" }
  var queryItems: [URLQueryItem]? { nil }
}

private extension URL {
  var origin: String {
    guard let scheme = self.scheme, let host = self.host else { return absoluteString }
    let portPart = (self.port != nil) ? ":\(self.port!)" : ""
    return "\(scheme)://\(host)\(portPart)"
  }
  var pathWithQuery: String {
    let comp = URLComponents(url: self, resolvingAgainstBaseURL: false)
    let path = comp?.path ?? ""
    let query = comp?.percentEncodedQuery.map { "?\($0)" } ?? ""
    return path + query
  }
}

private extension VidSrc {
  func matchFirst(in text: String, pattern: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else { return nil }
    let ns = text as NSString
    if let m = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: ns.length)), m.numberOfRanges > 1 {
      let r = m.range(at: 1)
      if r.location != NSNotFound { return ns.substring(with: r) }
    }
    return nil
  }

  func splitBeforeRCPSegment(_ url: String) -> String {
    if let r = url.range(of: "rcp") {
      return String(url[..<r.lowerBound])
    }
    return url
  }
}
   