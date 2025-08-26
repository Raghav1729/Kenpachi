import Foundation

struct VideoSource: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let url: String
    let quality: StreamingQuality
    let type: VideoType
    let server: String
    let isM3U8: Bool
    let headers: [String: String]?
    
    enum VideoType: String, Codable, CaseIterable {
        case mp4 = "mp4"
        case hls = "hls"
        case dash = "dash"
        case webm = "webm"
    }
}