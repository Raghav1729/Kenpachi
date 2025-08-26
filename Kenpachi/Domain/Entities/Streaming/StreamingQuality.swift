import Foundation

enum StreamingQuality: String, Codable, CaseIterable, Comparable {
    case sd360 = "360p"
    case sd480 = "480p"
    case hd720 = "720p"
    case hd1080 = "1080p"
    case uhd4k = "4K"
    case uhd8k = "8K"
    case auto = "Auto"
    
    var height: Int {
        switch self {
        case .sd360: return 360
        case .sd480: return 480
        case .hd720: return 720
        case .hd1080: return 1080
        case .uhd4k: return 2160
        case .uhd8k: return 4320
        case .auto: return 0 // Special case for auto quality
        }
    }
    
    var width: Int {
        switch self {
        case .sd360: return 640
        case .sd480: return 854
        case .hd720: return 1280
        case .hd1080: return 1920
        case .uhd4k: return 3840
        case .uhd8k: return 7680
        case .auto: return 0 // Special case for auto quality
        }
    }
    
    var displayName: String {
        switch self {
        case .auto: return "Auto"
        default: return rawValue
        }
    }
    
    var bitrate: Int {
        switch self {
        case .sd360: return 1000 // 1 Mbps
        case .sd480: return 2500 // 2.5 Mbps
        case .hd720: return 5000 // 5 Mbps
        case .hd1080: return 8000 // 8 Mbps
        case .uhd4k: return 25000 // 25 Mbps
        case .uhd8k: return 100000 // 100 Mbps
        case .auto: return 0
        }
    }
    
    var isHD: Bool {
        height >= 720
    }
    
    var is4K: Bool {
        height >= 2160
    }
    
    var aspectRatio: Double {
        guard width > 0 && height > 0 else { return 16.0/9.0 }
        return Double(width) / Double(height)
    }
    
    // MARK: - Comparable
    static func < (lhs: StreamingQuality, rhs: StreamingQuality) -> Bool {
        // Auto quality is considered highest
        if lhs == .auto { return false }
        if rhs == .auto { return true }
        return lhs.height < rhs.height
    }
}

// MARK: - Quality Selection
extension StreamingQuality {
    static var availableQualities: [StreamingQuality] {
        return [.auto, .uhd4k, .hd1080, .hd720, .sd480, .sd360]
    }
    
    static var hdQualities: [StreamingQuality] {
        return [.uhd4k, .hd1080, .hd720]
    }
    
    static var sdQualities: [StreamingQuality] {
        return [.sd480, .sd360]
    }
    
    static func bestQualityForBandwidth(_ bandwidth: Int) -> StreamingQuality {
        // Bandwidth in kbps
        switch bandwidth {
        case 100000...: return .uhd8k
        case 25000...: return .uhd4k
        case 8000...: return .hd1080
        case 5000...: return .hd720
        case 2500...: return .sd480
        default: return .sd360
        }
    }
}