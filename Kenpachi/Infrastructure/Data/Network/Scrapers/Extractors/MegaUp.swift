// MegaUp.swift
// MegaUp video extractor (used by AnimeKai)

import Foundation

final class MegaUpExtractor: ExtractorProtocol {
  var name: String { "MegaUp" }
  var supportedDomains: [String] { ["megaup.net"] }

  private let networkClient: NetworkClientProtocol
  private let apiBase = "https://enc-dec.app/api"

  init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
    self.networkClient = networkClient
  }

  struct DecMegaRequest: Encodable {
    let text: String
    let agent: String
  }
  private struct DecMegaResponse: Decodable {
    let result: DecMegaResult
  }
  private struct DecMegaResult: Decodable {
    let sources: [DecSource]
    let tracks: [DecTrack]?
    let download: String?
  }
  private struct DecSource: Decodable { let file: String }
  private struct DecTrack: Decodable {
    let kind: String
    let file: String
    let label: String?
  }

  func extract(from embedURL: String) async throws -> [ExtractedLink] {
    // AnimeKai uses MegaUp: replace /e/ with /media/ then fetch JSON { result: string }
    let mediaURL = embedURL.replacingOccurrences(of: "/e/", with: "/media/")

    // Step 1: GET mediaURL to obtain encrypted payload
    let mediaData = try await networkClient.requestData(
      GenericURLEndpoint(
        url: mediaURL,
        method: .get,
        headers: [
          "Connection": "keep-alive",
          "User-Agent": userAgent,
        ]
      ))

    // Expecting JSON { result: string }
    guard
      let json = try? JSONSerialization.jsonObject(with: mediaData) as? [String: Any],
      let encrypted = json["result"] as? String,
      !encrypted.isEmpty
    else {
      throw ScraperError.extractionFailed("MegaUp: missing encrypted result")
    }

    // Step 2: POST to enc-dec.app/api/dec-mega to decode
    let body = DecMegaRequest(text: encrypted, agent: userAgent)
    let bodyData = try JSONEncoder().encode(body)
    let decData = try await networkClient.requestData(
      GenericURLEndpoint(
        url: apiBase + "/dec-mega",
        method: .post,
        headers: [
          "Content-Type": "application/json"
        ],
        body: bodyData
      ))

    let decoded = try JSONDecoder().decode(DecMegaResponse.self, from: decData).result

    var links: [ExtractedLink] = []
    for src in decoded.sources {
      let url = src.file
      let isHls = url.contains(".m3u8") || url.hasSuffix("m3u8")
      let type: ExtractedLink.LinkType = isHls ? .m3u8 : .direct
      let headers: [String: String] = {
        if isHls {
          return [
            "User-Agent": userAgent,
            "Accept": "application/vnd.apple.mpegurl,application/x-mpegURL,*/*",
            "Referer": embedURL,
          ]
        }
        return [
          "User-Agent": userAgent,
          "Accept": "application/json,*/*",
          "Referer": embedURL,
        ]
      }()
      let subs: [Subtitle]? = decoded.tracks?.map { t in
        let label = t.label ?? t.kind
        let format: SubtitleFormat = t.file.lowercased().hasSuffix(".srt") ? .srt : .vtt
        return Subtitle(
          id: UUID().uuidString,
          name: label,
          language: label.lowercased(),
          url: t.file,
          format: format
        )
      }
      links.append(
        ExtractedLink(
          url: url,
          quality: isHls ? "auto" : "unknown",
          server: name,
          requiresReferer: true,
          headers: headers,
          type: type,
          subtitles: subs
        )
      )
    }

    return links
  }

  private var userAgent: String {
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36"
  }
}

// Generic endpoint for arbitrary URLs
private struct GenericURLEndpoint: Endpoint {
  let url: String
  let method: HTTPMethod
  var headers: [String: String]?
  var body: Data?

  var baseURL: String {
    guard let u = URL(string: url), let scheme = u.scheme, let host = u.host else { return "" }
    let portPart = (u.port != nil) ? ":\(u.port!)" : ""
    return "\(scheme)://\(host)\(portPart)"
  }
  var path: String {
    guard let u = URL(string: url) else { return "" }
    let comp = URLComponents(url: u, resolvingAgainstBaseURL: false)
    let path = comp?.path ?? ""
    let query = comp?.percentEncodedQuery.map { "?\($0)" } ?? ""
    return path + query
  }
  var queryItems: [URLQueryItem]? { nil }
}
