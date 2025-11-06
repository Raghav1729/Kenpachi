// MP4Hydra.swift
// MP4Hydra scraper implementation (ScraperProtocol)
// This host does not provide catalog/search; only link extraction is supported.

import Foundation

struct MP4Hydra: ScraperProtocol {
  let name = "MP4Hydra"
  let baseURL = "https://mp4hydra"  // Placeholder; host varies by TLD
  let supportedTypes: [ContentType] = [.movie, .tvShow]

  private let networkClient: NetworkClientProtocol
  private let tmdb: TMDBClient

  init(networkClient: NetworkClientProtocol = NetworkClient.shared, tmdb: TMDBClient = .shared) {
    self.networkClient = networkClient
    self.tmdb = tmdb
  }

  // MARK: - Unsupported operations for host-only scraper
  func fetchHomeContent() async throws -> [ContentCarousel] {
    // Build carousels using TMDB top rated endpoints
    let topRatedMovies = try await tmdb.fetchTopRatedMovies()
    let topRatedTV = try await tmdb.fetchTopRatedTVShows()

    /// Build carousels using TMDB popular endpoints
    let popularMovies = try await tmdb.fetchPopularMovies()
    let popularTV = try await tmdb.fetchPopularTVShows()

    // Build carousels using TMDB trending endpoints
    let trendingMovies = try await tmdb.fetchTrendingMovies(timeWindow: .day)
    let trendingTV = try await tmdb.fetchTrendingTVShows(timeWindow: .day)

    var carousels: [ContentCarousel] = []

    //Hero section: pick top 10 by rating from combined top-rated
    let heroItems = (topRatedMovies + topRatedTV)
      .sorted { ($0.voteAverage ?? 0) > ($1.voteAverage ?? 0) }
      .prefix(10)
      .map { $0 }
    carousels.append(ContentCarousel(title: "Featured", items: heroItems, type: .hero))

    // Trending sections
    carousels.append(
      ContentCarousel(title: "Trending Movies", items: trendingMovies, type: .trending))
    carousels.append(
      ContentCarousel(title: "Trending TV Shows", items: trendingTV, type: .trending))

    // Popular sections
    carousels.append(ContentCarousel(title: "Popular Movies", items: popularMovies, type: .popular))
    carousels.append(ContentCarousel(title: "Popular TV Shows", items: popularTV, type: .popular))

    // Top Rated sections (use popular type for display)
    carousels.append(
      ContentCarousel(title: "Top Rated Movies", items: topRatedMovies, type: .topRated))
    carousels.append(
      ContentCarousel(title: "Top Rated TV Shows", items: topRatedTV, type: .topRated))

    return carousels
  }

  func search(query: String, page: Int) async throws -> ContentSearchResult {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !q.isEmpty else { return ContentSearchResult(contents: []) }

    // Use paged TMDB endpoints; URLQueryItem will handle special character encoding
    let response = try await tmdb.search(query: q, page: page)
    let searchResult: [Content] = response.results
      .filter { $0.mediaType != "person" }
      .compactMap { $0.toContent() }

    let totalResults = response.totalResults
    let totalPages = response.totalPages
    let currentPage = response.page

    return ContentSearchResult(
      id: "mp4hydra-search-\(q)-\(currentPage)",
      contents: searchResult,
      totalResults: totalResults,
      page: currentPage,
      totalPages: totalPages
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
    // Fallback: try movie then TV
    do { return try await tmdb.fetchMovieDetails(id: id) } catch {}
    return try await tmdb.fetchTVShowDetails(id: id)
  }

  // MARK: - Extraction
  func extractStreamingLinks(contentId: String, seasonId: String?, episodeId: String?) async throws
    -> [ExtractedLink]
  {
    // contentId is TMDB ID
    // Determine media type from presence of season/episode
    let isTV = (seasonId != nil && episodeId != nil)
    let mediaType = isTV ? "tv" : "movie"

    // Fetch TMDB details
    let content: Content = try await fetchContentDetails(id: contentId, type: isTV ? .tvShow : .movie)

    // Build initial slug
    let baseTitle = content.title
    let year = content.releaseDate.flatMap { Calendar.current.dateComponents([.year], from: $0).year }
    var slug = generateSlug(from: baseTitle)
    if !isTV, let y = year { slug = "\(slug)-\(y)" }

    let seasonNum: Int? = seasonId.flatMap { Int($0) }
    let episodeNum: Int? = episodeId.flatMap { Int($0) }

    // Attempt sequence: title(+year), original title, title without year (movie only)
    let attemptSlugs: [String] = {
      var attempts: [String] = [slug]
      if let original = content.originalTitle, !original.isEmpty {
        var s = generateSlug(from: original)
        if !isTV, let y = year { s = "\(s)-\(y)" }
        attempts.append(s)
      }
      if !isTV { // try without year
        attempts.append(generateSlug(from: baseTitle))
      }
      return Array(LinkedHashSet(attempts)) // keep order, remove duplicates
    }()

    for attempt in attemptSlugs {
      if let links = try await fetchMP4HydraLinks(slug: attempt, mediaType: mediaType, season: seasonNum, episode: episodeNum), !links.isEmpty {
        return links
      }
    }

    throw ScraperError.extractionFailed("No streaming links found for MP4Hydra")
  }

  // MARK: - MP4Hydra Helpers
  private func fetchMP4HydraLinks(slug: String, mediaType: String, season: Int?, episode: Int?) async throws -> [ExtractedLink]? {
    // Build multipart/form-data body
    let boundary = "Boundary-\(UUID().uuidString)"
    let formFields: [String: String?] = [
      "v": "8",
      "z": buildZPayload(slug: slug, mediaType: mediaType, season: season, episode: episode)
    ]
    let bodyData = buildMultipartBody(fields: formFields, boundary: boundary)

    // Endpoint
    let endpoint = MP4HydraInfoEndpoint(
      queryV: "8",
      refererPath: "/\(mediaType)/\(slug)",
      boundary: boundary,
      bodyData: bodyData
    )

    let data = try await networkClient.requestData(endpoint)

    // Decode partial response
    guard let response = try? JSONDecoder().decode(MP4HydraInfoResponse.self, from: data) else {
      return nil
    }

    guard let playlist = response.playlist, !playlist.isEmpty, let servers = response.servers else {
      return []
    }

    let desiredServers: [(name: String, number: String)] = [("Beta", "#1"), ("Beta#3", "#2")]
    var links: [ExtractedLink] = []

    if mediaType == "tv", let s = season, let e = episode {
      let seasonEpisode = String(format: "S%02dE%02d", s, e)
      guard let target = playlist.first(where: { ($0.title ?? "").uppercased() == seasonEpisode.uppercased() }) else {
        return []
      }
      for server in desiredServers {
        if let base = servers[server.name] {
          if let link = buildLink(from: target, baseServer: base, serverName: server.name, serverNumber: server.number, displayTitle: contentDisplayTitle(for: mediaType, original: false, baseTitle: nil)) {
            links.append(link)
          }
        }
      }
      return links
    }

    // Movie: all items
    for server in desiredServers {
      if let base = servers[server.name] {
        for item in playlist {
          if let link = buildLink(from: item, baseServer: base, serverName: server.name, serverNumber: server.number, displayTitle: contentDisplayTitle(for: mediaType, original: false, baseTitle: nil)) {
            links.append(link)
          }
        }
      }
    }

    return links
  }

  private func contentDisplayTitle(for mediaType: String, original: Bool, baseTitle: String?) -> String {
    return baseTitle ?? ""
  }

  private func buildLink(from item: MP4HydraPlaylistItem, baseServer: String, serverName: String, serverNumber: String, displayTitle: String) -> ExtractedLink? {
    guard let src = item.src else { return nil }
    let videoUrl = baseServer + src
    let quality = item.quality ?? item.label

    var subtitles: [Subtitle] = []
    if let subs = item.subs {
      subtitles = subs.compactMap { sub in
        guard let ssrc = sub.src else { return nil }
        let url = baseServer + ssrc
        let label = sub.label ?? "Subtitle"
        return Subtitle(
          id: UUID().uuidString,
          name: label,
          language: label.lowercased(),
          url: url,
          format: .vtt
        )
      }
    }

    return ExtractedLink(
      url: videoUrl,
      quality: quality,
      server: "MP4Hydra \(serverNumber)",
      requiresReferer: true,
      headers: ["Referer": "https://mp4hydra.org/"],
      type: .direct,
      subtitles: subtitles.isEmpty ? nil : subtitles
    )
  }

  private func buildZPayload(slug: String, mediaType: String, season: Int?, episode: Int?) -> String {
    var dict: [String: Any?] = [
      "s": slug,
      "t": mediaType,
      "se": season,
      "ep": episode
    ]
    // Encode as JSON array string
    let obj: [[String: Any?]] = [dict]
    let json = try? JSONSerialization.data(withJSONObject: obj.compactMap { removeNils($0) }, options: [])
    return String(data: json ?? Data("[]".utf8), encoding: .utf8) ?? "[]"
  }

  private func removeNils(_ dict: [String: Any?]) -> [String: Any] {
    var out: [String: Any] = [:]
    for (k, v) in dict {
      if let v = v { out[k] = v }
    }
    return out
  }

  private func buildMultipartBody(fields: [String: String?], boundary: String) -> Data {
    var body = Data()
    let boundaryLine = "--\(boundary)\r\n"
    let closingBoundary = "--\(boundary)--\r\n"
    for (key, value) in fields {
      guard let value = value else { continue }
      body.append(Data(boundaryLine.utf8))
      body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8))
      body.append(Data("\(value)\r\n".utf8))
    }
    body.append(Data(closingBoundary.utf8))
    return body
  }

  private func generateSlug(from title: String) -> String {
    // Lowercase
    var slug = title.lowercased()
    // Remove special chars except word, space, hyphen
    let allowed = CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: "-"))
    slug = String(slug.unicodeScalars.filter { allowed.contains($0) })
    // Replace spaces with hyphens and collapse multiple hyphens
    slug = slug.replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
    slug = slug.replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
    return slug
  }

  // MARK: - Models & Endpoint
  private struct MP4HydraInfoResponse: Decodable {
    let playlist: [MP4HydraPlaylistItem]?
    let servers: [String: String]?
  }

  private struct MP4HydraPlaylistItem: Decodable {
    let show_title: String?
    let title: String?
    let type: String?
    let quality: String?
    let label: String?
    let src: String?
    let subs: [MP4HydraSubtitle]?
  }

  private struct MP4HydraSubtitle: Decodable {
    let label: String?
    let src: String?
  }

  private struct MP4HydraInfoEndpoint: Endpoint {
    var baseURL: String { "https://mp4hydra.org" }
    var path: String { "/info2" }
    var method: HTTPMethod { .post }
    var queryItems: [URLQueryItem]? { [URLQueryItem(name: "v", value: queryV)] }
    var headers: [String: String]? {
      [
        "User-Agent": "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36",
        "Accept": "*/*",
        "Accept-Language": "en-GB,en-US;q=0.9,en;q=0.8",
        "Origin": "https://mp4hydra.org",
        "Referer": "https://mp4hydra.org\(refererPath)",
        "Content-Type": "multipart/form-data; boundary=\(boundary)"
      ]
    }
    var body: Data? { bodyData }

    let queryV: String
    let refererPath: String
    let boundary: String
    let bodyData: Data
  }

  // Ordered set helper to keep attempts unique in order
  private struct LinkedHashSet<Element: Hashable>: Sequence {
    private var array: [Element] = []
    private var set: Set<Element> = []
    init(_ elements: [Element]) {
      for e in elements { if set.insert(e).inserted { array.append(e) } }
    }
    func makeIterator() -> IndexingIterator<[Element]> { array.makeIterator() }
    var elements: [Element] { array }
  }
}
