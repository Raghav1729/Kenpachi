// AnimeKai.swift
// AnimeKai provider integration using MegaUp extractor

import Foundation
import SwiftSoup

struct AnimeKai: ScraperProtocol {
  let name = "AnimeKai"
  let baseURL = "https://anikai.to"
  let supportedTypes: [ContentType] = [.anime]

  private let networkClient: NetworkClientProtocol
  private let extractorResolver: ExtractorResolver

  init(
    networkClient: NetworkClientProtocol = NetworkClient.shared,
    extractorResolver: ExtractorResolver = ExtractorResolver()
  ) {
    self.networkClient = networkClient
    self.extractorResolver = extractorResolver
  }

  // MARK: - Home Content
  func fetchHomeContent() async throws -> [ContentCarousel] {
    async let spotlight = fetchSpotlight()
    async let latestCompleted = fetchLatestCompleted()
    async let recentlyAdded = fetchRecentlyAdded()
    async let recentlyUpdated = fetchRecentlyUpdated()
    async let newReleases = fetchNewReleases()

    var carousels: [ContentCarousel] = []
    let hero = try await spotlight
    if !hero.isEmpty {
      carousels.append(ContentCarousel(title: "Spotlight", items: hero, type: .hero))
    }
    let completed = try await latestCompleted
    if !completed.isEmpty {
      carousels.append(ContentCarousel(title: "Latest Completed", items: completed, type: .recent))
    }
    let added = try await recentlyAdded
    if !added.isEmpty {
      carousels.append(ContentCarousel(title: "Recently Added", items: added, type: .recent))
    }
    let updated = try await recentlyUpdated
    if !updated.isEmpty {
      carousels.append(ContentCarousel(title: "Recently Updated", items: updated, type: .recent))
    }
    let releases = try await newReleases
    if !releases.isEmpty {
      carousels.append(ContentCarousel(title: "New Releases", items: releases, type: .recent))
    }
    return carousels
  }

  // MARK: - Section fetchers
  private func fetchCardPage(_ url: String) async throws -> [Content] {
    let data = try await networkClient.requestData(AnimeKaiEndpoint(url: url))
    let doc = try HTMLParser.parse(String(data: data, encoding: .utf8) ?? "")
    return try parseCards(doc)
  }

  private func fetchSpotlight() async throws -> [Content] {
      let data = try await networkClient.requestData(AnimeKaiEndpoint(url: baseURL + "/home"))
      let html = String(data: data, encoding: .utf8) ?? ""
      let doc = try HTMLParser.parse(html)
      var items: [Content] = []
      let slides = try doc.select("section#featured div.swiper-slide").array()
      for slide in slides {
          let btn = try slide.select("div.swiper-ctrl > a.btn").first()
          let href = try btn?.attr("href") ?? ""
          guard !href.isEmpty else { continue }
          let id = href.replacingOccurrences(of: "/watch/", with: "")
          let title = try slide.select("div.detail > p.title").text()
          let style = try slide.attr("style")
          let banner = try extractBackgroundURL(from: style)
          let infoEl = try slide.select("div.detail > div.info").first()
          let type = try infoEl?.children().first(where: { (try? $0.tagName()) == "b" })?.text().trimmingCharacters(in: .whitespacesAndNewlines)

          // Extract release year and rating from the 'mics' div
          let mics = try slide.select("div.mics > div")
          var releaseYear: String?
          var rating: String?

          for mic in mics.array() {
              let key = try mic.select("div").text()
              if key == "Release" {
                  releaseYear = try mic.select("span").text()
              } else if key == "Rating" {
                  rating = try mic.select("span").text()
              }
          }

          items.append(
              Content(
                  id: id,
                  type: .anime,
                  title: title,
                  originalTitle: nil,
                  overview: try? slide.select("div.detail > p.desc").text().trimmingCharacters(
                      in: .whitespacesAndNewlines),
                  posterPath: nil,
                  backdropPath: banner,
                  voteAverage: nil,
                  voteCount: nil,
                  popularity: nil,
                  originalLanguage: "ja",
                  genreIds: nil,
                  genres: nil,
                  adult: false,
                  rating: rating,
                  runtime: nil,
                  numberOfSeasons: 1,
                  numberOfEpisodes: nil,
                  status: type,
                  tagline: nil,
                  homepage: nil,
                  productionCompanies: nil,
                  seasons: nil,
                  cast: nil,
                  trailerUrl: nil,
                  country: "JP",
                  duration: nil,
                  recommendations: nil
              )
          )
      }
      return items
  }

  private func fetchLatestCompleted() async throws -> [Content] {
    try await fetchCardPage(baseURL + "/completed?page=1")
  }

  private func fetchRecentlyAdded() async throws -> [Content] {
    try await fetchCardPage(baseURL + "/recent?page=1")
  }

  private func fetchRecentlyUpdated() async throws -> [Content] {
    try await fetchCardPage(baseURL + "/updates?page=1")
  }

  private func fetchNewReleases() async throws -> [Content] {
    try await fetchCardPage(baseURL + "/new-releases?page=1")
  }

  // MARK: - Parsing helpers
  private func parseCards(_ doc: Document) throws -> [Content] {
    var results: [Content] = []
    let cards = try doc.select(".aitem").array()
    for card in cards {
      let posterLink = try card.select("a.poster").first()
      let href = try posterLink?.attr("href") ?? ""
      guard !href.isEmpty else { continue }
      
      let cleanHref = href.components(separatedBy: "#").first ?? href
      let id = cleanHref.replacingOccurrences(of: "/watch/", with: "")
      
      let title = try card.select("a.title").text()
      
      let imgEl = try card.select("img").first()
      let image = try { () -> String? in
        let ds = try imgEl?.attr("data-src") ?? ""
        if !ds.isEmpty { return ds }
        let s = try imgEl?.attr("src") ?? ""
        return s.isEmpty ? nil : s
      }()
      let infoEl = try card.select(".info").first()
      let type = try infoEl?.children().last()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
      results.append(
        Content(
          id: id,
          type: .anime,
          title: title,
          originalTitle: nil,
          overview: nil,
          posterPath: image,
          backdropPath: nil,
          releaseDate: nil,
          voteAverage: nil,
          voteCount: nil,
          popularity: nil,
          originalLanguage: "ja",
          genreIds: nil,
          genres: nil,
          adult: false,
          rating: type,
          runtime: nil,
          numberOfSeasons: 1,
          numberOfEpisodes: nil,
          status: nil,
          tagline: nil,
          homepage: nil,
          productionCompanies: nil,
          seasons: nil,
          cast: nil,
          trailerUrl: nil,
          country: "JP",
          duration: nil,
          recommendations: nil
        ))
    }
    return results
  }

  private func extractBackgroundURL(from style: String) throws -> String? {
    let pattern = #"background-image:\s*url\((.+?)\)"#
    let regex = try NSRegularExpression(pattern: pattern)
    let ns = style as NSString
    if let match = regex.firstMatch(in: style, range: NSRange(location: 0, length: ns.length)),
      match.numberOfRanges > 1
    {
      let r = match.range(at: 1)
      if r.location != NSNotFound { return ns.substring(with: r).trimmingCharacters(in: CharacterSet(charactersIn: "\"'")) }
    }
    return nil
  }

  // MARK: - Search
  func search(query: String, page: Int) async throws -> ContentSearchResult {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !q.isEmpty else { return ContentSearchResult(contents: []) }
    let url =
      "\(baseURL)/browser?keyword=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&page=\(max(page,1))"
    let htmlData = try await networkClient.requestData(AnimeKaiEndpoint(url: url))
    let doc = try HTMLParser.parse(String(data: htmlData, encoding: .utf8) ?? "")

    var results: [Content] = []
    let items = try doc.select(".aitem")
    for el in items.array() {
      // Correctly select the poster link for the href and the title link for the text
      let posterLink = try el.select("a.poster").first()
      let href = try posterLink?.attr("href") ?? ""
      guard !href.isEmpty else { continue }
      
      let id = href.replacingOccurrences(of: "/watch/", with: "")
      let title = try el.select("a.title").text()
      
      let img = try el.select("img").first()
      let image =
        try (img?.attr("data-src").isEmpty == false ? img?.attr("data-src") : img?.attr("src"))
      let infoEl2 = try el.select(".info").first()
      let type = try infoEl2?.children().last()?.text().trimmingCharacters(in: .whitespacesAndNewlines)

      results.append(
        Content(
          id: id,
          type: .anime,
          title: title,
          originalTitle: nil,
          overview: nil,
          posterPath: image,
          backdropPath: nil,
          releaseDate: nil,
          voteAverage: nil,
          voteCount: nil,
          popularity: nil,
          originalLanguage: "ja",
          genreIds: nil,
          genres: nil,
          adult: false,
          rating: nil,
          runtime: nil,
          numberOfSeasons: 1,
          numberOfEpisodes: nil,
          status: type,
          tagline: nil,
          homepage: nil,
          productionCompanies: nil,
          seasons: nil,
          cast: nil,
          trailerUrl: nil,
          country: "JP",
          duration: nil,
          recommendations: nil
        )
      )
    }

    return ContentSearchResult(contents: results)
  }

  // MARK: - Details (with episodes)
    func fetchContentDetails(id: String, type: ContentType?) async throws -> Content {
        let url = "\(baseURL)/watch/\(id)"
        let htmlData = try await networkClient.requestData(AnimeKaiEndpoint(url: url))
        let html = String(data: htmlData, encoding: .utf8) ?? ""
        let doc = try HTMLParser.parse(html)

        let title = try doc.select("h1.title").text()
        let poster = try doc.select("div.poster img").attr("src")
        let backdropStyle = try doc.select("div.watch-section-bg").attr("style")
        let backdrop = try extractBackgroundURL(from: backdropStyle)
        let overview = try doc.select("div.desc.text-expand").text()
        let rating = try doc.select("div.info span.rating").text()

        let detailElements = try doc.select("div.detail > div > div")
        let status = try detailElements.first(where: { try $0.text().starts(with: "Status:") })?.select("span").text()
        let genreNames = try detailElements.first(where: { try $0.text().starts(with: "Genres:") })?.select("a").map { try $0.text() }
        let releaseDate = try detailElements.first(where: { try $0.text().starts(with: "Date aired:") })?.select("span").text().components(separatedBy: " to ").first
        let numberOfEpisodesStr = try detailElements.first(where: { try $0.text().starts(with: "Episodes:") })?.select("span").text()
        let numberOfEpisodes = Int(numberOfEpisodesStr ?? "")

        // Parse seasons
        var seasons: [Season] = []
        let seasonElements = try doc.select("section#seasons .aitem").array()
        var seasonCounter = 1

        for seasonEl in seasonElements {
            let seasonHref = try seasonEl.select("a.poster").attr("href")
            let seasonId = seasonHref.replacingOccurrences(of: "/watch/", with: "")
            let seasonName = try seasonEl.select("div.detail > span").text()
            let seasonPoster = try seasonEl.select("a.poster img").attr("src")
            let episodeCountStr = try seasonEl.select("div.detail .btn").text().replacingOccurrences(of: " Eps", with: "")
            let episodeCount = Int(episodeCountStr)

            var episodes: [Episode] = []
            // If this is the current season, fetch its episodes via AJAX
            if seasonEl.hasClass("active") {
                let aniId = try doc.select(".rate-box#anime-rating").attr("data-id")
                if !aniId.isEmpty {
                    let token = try await generateToken(aniId)
                    let ajaxURL = "\(baseURL)/ajax/episodes/list?ani_id=\(aniId)&_=\(token)"
                    let ajaxData = try await networkClient.requestData(
                        AnimeKaiAjaxEndpoint(url: ajaxURL, referer: url)
                    )
                    
                    if let json = try? JSONSerialization.jsonObject(with: ajaxData) as? [String: Any],
                       let resultHTML = json["result"] as? String {
                        
                        let epDoc = try SwiftSoup.parse(resultHTML)
                        let links = try epDoc.select("div.eplist > ul > li > a").array()
                        for a in links {
                            let numStr = try a.attr("num")
                            let tokenAttr = try a.attr("token")
                            let epNum = Int(numStr) ?? 0
                            let epId = "\(id)$ep=\(epNum)$token=\(tokenAttr)"
                            let epTitle = try a.text().trimmingCharacters(in: .whitespacesAndNewlines)
                            episodes.append(
                                Episode(
                                    id: epId, episodeNumber: epNum, seasonNumber: seasonCounter, name: epTitle, overview: nil,
                                    airDate: nil, runtime: nil
                                )
                            )
                        }
                    }
                }
            }

            seasons.append(
                Season(
                    id: seasonId,
                    seasonNumber: seasonCounter,
                    name: seasonName,
                    overview: nil,
                    posterPath: seasonPoster,
                    airDate: nil,
                    episodeCount: episodeCount ?? 0,
                    episodes: episodes
                )
            )
            seasonCounter += 1
        }
        
        // Parse recommendations
        var recommendations: [Content] = []
        let recItems = try doc.select("section.sidebar-section:contains(Recommended) .aitem").array()
        for item in recItems {
            let recHref = try item.attr("href")
            let recId = recHref.replacingOccurrences(of: "/watch/", with: "")
            let recTitle = try item.select(".detail .title").text()
            let recStyle = try item.attr("style")
            let recImage = try extractBackgroundURL(from: recStyle)

            recommendations.append(Content(id: recId, type: .anime, title: recTitle, posterPath: recImage))
        }


        return Content(
            id: id,
            type: .anime,
            title: title,
            originalTitle: nil,
            overview: overview,
            posterPath: poster,
            backdropPath: backdrop,
            voteAverage: nil,
            voteCount: nil,
            popularity: nil,
            originalLanguage: "ja",
            genreIds: nil,
            genres: genreNames?.map { Genre(id: 0, name: $0) },
            adult: false,
            rating: rating,
            runtime: nil,
            numberOfSeasons: seasons.count,
            numberOfEpisodes: numberOfEpisodes,
            status: status,
            tagline: nil,
            homepage: nil,
            productionCompanies: nil,
            seasons: seasons,
            cast: nil,
            trailerUrl: nil,
            country: "JP",
            duration: nil,
            recommendations: recommendations
        )
    }

  // MARK: - Extraction
  func extractStreamingLinks(contentId: String, seasonId: String?, episodeId: String?) async throws
    -> [ExtractedLink]
  {
    // episodeId carries token info like: "{animeId}$ep={num}$token={token}"
    guard let eid = episodeId, let token = eid.components(separatedBy: "$token=").last,
      !token.isEmpty
    else {
      // if user passed embed URL directly, try resolver
      if contentId.starts(with: "http") {
        return try await extractorResolver.extract(from: contentId)
      }
      throw ScraperError.invalidConfiguration
    }

    // Step 1: list servers
    let listTok = try await generateToken(token)
    let listURL = "\(baseURL)/ajax/links/list?token=\(token)&_=\(listTok)"
    let listData = try await networkClient.requestData(
      AnimeKaiAjaxEndpoint(url: listURL, referer: baseURL + "/"))
    guard let listJson = try? JSONSerialization.jsonObject(with: listData) as? [String: Any],
      let listHTML = listJson["result"] as? String
    else { return [] }

    let listDoc = try SwiftSoup.parse(listHTML)
    let servers = try listDoc.select(".server-items.lang-group[data-id='softsub'] .server").array()

    var allLinks: [ExtractedLink] = []

    for server in servers {
      let lid = try server.attr("data-lid")
      if lid.isEmpty { continue }
      let viewTok = try await generateToken(lid)
      let viewURL = "\(baseURL)/ajax/links/view?id=\(lid)&_=\(viewTok)"
      let viewData = try await networkClient.requestData(
        AnimeKaiAjaxEndpoint(url: viewURL, referer: baseURL + "/"))
      guard let viewJson = try? JSONSerialization.jsonObject(with: viewData) as? [String: Any],
        let encIframe = viewJson["result"] as? String
      else { continue }

      // Decode iframe data via enc-dec.app/dec-kai to get embed URL
      guard let decoded = try await decodeIframeData(encIframe) else { continue }
      // Resolve using registered extractors (MegaUp)
      if let links = try? await extractorResolver.extract(from: decoded.url) {
        allLinks.append(
          contentsOf: links.map { l in
            ExtractedLink(
              id: l.id,
              url: l.url,
              quality: l.quality,
              server: serverName(from: server),
              requiresReferer: l.requiresReferer,
              headers: l.headers,
              type: l.type,
              subtitles: l.subtitles
            )
          })
      }
    }

    // dedupe
    var seen = Set<String>()
    let unique = allLinks.filter { link in
      if seen.contains(link.url) { return false }
      seen.insert(link.url)
      return true
    }
    return unique
  }

  // MARK: - Helpers
  private func serverName(from el: Element) -> String {
    (try? el.text().trimmingCharacters(in: .whitespacesAndNewlines)) ?? name
  }

  private func headers() -> [String: String] {
    [
      "User-Agent": userAgent,
      "Accept": "text/html, */*; q=0.01",
      "Accept-Language": "en-US,en;q=0.5",
      "X-Requested-With": "XMLHttpRequest",
      "Referer": baseURL + "/",
    ]
  }

  private var userAgent: String {
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36"
  }

  private func generateToken(_ text: String) async throws -> String {
    let url =
      "https://enc-dec.app/api/enc-kai?text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text)"
    let data = try await networkClient.requestData(
      GenericURLEndpoint(url: url, method: .get, headers: ["User-Agent": userAgent], body: nil))
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let result = json?["result"] as? String else {
      throw ScraperError.extractionFailed("Token gen failed")
    }
    return result
  }

  private struct DecKaiReq: Encodable { let text: String }
  private struct DecKaiResp: Decodable {
    let result: Decoded
    struct Decoded: Decodable {
      let url: String
      let skip: Skip
    }
    struct Skip: Decodable {
      let intro: [Double]
      let outro: [Double]
    }
  }

  private func decodeIframeData(_ text: String) async throws -> (
    url: String, intro: [Double], outro: [Double]
  )? {
    let body = try JSONEncoder().encode(DecKaiReq(text: text))
    let data = try await networkClient.requestData(
      GenericURLEndpoint(
        url: "https://enc-dec.app/api/dec-kai", method: .post,
        headers: ["Content-Type": "application/json"], body: body))
    let resp = try JSONDecoder().decode(DecKaiResp.self, from: data)
    return (resp.result.url, resp.result.skip.intro, resp.result.skip.outro)
  }
}

// MARK: - Endpoints
private struct AnimeKaiEndpoint: Endpoint {
  let url: String
  var method: HTTPMethod { .get }
  var headers: [String: String]? {
    [
      "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
      "Referer": "https://anikai.to/",
    ]
  }
  var body: Data? { nil }
  var baseURL: String { URL(string: url)?.origin ?? "" }
  var path: String { URL(string: url)?.pathWithQuery ?? "" }
  var queryItems: [URLQueryItem]? { nil }
}

private struct AnimeKaiAjaxEndpoint: Endpoint {
  let url: String
  let referer: String
  var method: HTTPMethod { .get }
  var headers: [String: String]? {
    [
      "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
      "X-Requested-With": "XMLHttpRequest",
      "Referer": referer,
    ]
  }
  var body: Data? { nil }
  var baseURL: String { URL(string: url)?.origin ?? "" }
  var path: String { URL(string: url)?.pathWithQuery ?? "" }
  var queryItems: [URLQueryItem]? { nil }
}

// Generic endpoint re-use
private struct GenericURLEndpoint: Endpoint {
  let url: String
  let method: HTTPMethod
  var headers: [String: String]?
  var body: Data?
  var baseURL: String { URL(string: url)?.origin ?? "" }
  var path: String { URL(string: url)?.pathWithQuery ?? "" }
  var queryItems: [URLQueryItem]? { nil }
}

extension URL {
  fileprivate var origin: String {
    guard let scheme = self.scheme, let host = self.host else { return absoluteString }
    let portPart = (self.port != nil) ? ":\(self.port!)" : ""
    return "\(scheme)://\(host)\(portPart)"
  }
  fileprivate var pathWithQuery: String {
    let comp = URLComponents(url: self, resolvingAgainstBaseURL: false)
    let path = comp?.path ?? ""
    let query = comp?.percentEncodedQuery.map { "?\($0)" } ?? ""
    return path + query
  }
}
