import Foundation

struct SubtitleTrack: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let url: String
    let language: String
    let languageCode: String // ISO 639-1 code (e.g., "en", "es", "fr")
    let label: String
    let format: SubtitleFormat
    let isDefault: Bool
    let isForced: Bool
    let isSDH: Bool // Subtitles for Deaf and Hard of hearing
    
    // Additional metadata
    let encoding: String?
    let fileSize: Int64?
    let lastModified: Date?
}

enum SubtitleFormat: String, Codable, CaseIterable {
    case srt = "srt"
    case vtt = "vtt"
    case ass = "ass"
    case ssa = "ssa"
    case sub = "sub"
    case sbv = "sbv"
    case ttml = "ttml"
    case dfxp = "dfxp"
    
    var displayName: String {
        switch self {
        case .srt: return "SRT"
        case .vtt: return "WebVTT"
        case .ass: return "ASS"
        case .ssa: return "SSA"
        case .sub: return "SUB"
        case .sbv: return "SBV"
        case .ttml: return "TTML"
        case .dfxp: return "DFXP"
        }
    }
    
    var mimeType: String {
        switch self {
        case .srt: return "text/srt"
        case .vtt: return "text/vtt"
        case .ass: return "text/x-ass"
        case .ssa: return "text/x-ssa"
        case .sub: return "text/x-sub"
        case .sbv: return "text/x-sbv"
        case .ttml: return "application/ttml+xml"
        case .dfxp: return "application/ttaf+xml"
        }
    }
    
    var fileExtension: String {
        return rawValue
    }
}

// MARK: - Extensions
extension SubtitleTrack {
    var displayLabel: String {
        var components: [String] = [label]
        
        if isSDH {
            components.append("SDH")
        }
        
        if isForced {
            components.append("Forced")
        }
        
        return components.joined(separator: " • ")
    }
    
    var formattedFileSize: String? {
        guard let fileSize = fileSize else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var languageFlag: String {
        // Return flag emoji for common languages
        switch languageCode.lowercased() {
        case "en": return "🇺🇸"
        case "es": return "🇪🇸"
        case "fr": return "🇫🇷"
        case "de": return "🇩🇪"
        case "it": return "🇮🇹"
        case "pt": return "🇵🇹"
        case "ru": return "🇷🇺"
        case "ja": return "🇯🇵"
        case "ko": return "🇰🇷"
        case "zh": return "🇨🇳"
        case "ar": return "🇸🇦"
        case "hi": return "🇮🇳"
        case "th": return "🇹🇭"
        case "vi": return "🇻🇳"
        case "tr": return "🇹🇷"
        case "pl": return "🇵🇱"
        case "nl": return "🇳🇱"
        case "sv": return "🇸🇪"
        case "da": return "🇩🇰"
        case "no": return "🇳🇴"
        case "fi": return "🇫🇮"
        default: return "🌐"
        }
    }
}

// MARK: - Language Utilities
extension SubtitleTrack {
    static func languageName(for code: String) -> String {
        let locale = Locale(identifier: "en")
        return locale.localizedString(forLanguageCode: code) ?? code.uppercased()
    }
    
    static func commonLanguages() -> [(code: String, name: String, flag: String)] {
        return [
            ("en", "English", "🇺🇸"),
            ("es", "Spanish", "🇪🇸"),
            ("fr", "French", "🇫🇷"),
            ("de", "German", "🇩🇪"),
            ("it", "Italian", "🇮🇹"),
            ("pt", "Portuguese", "🇵🇹"),
            ("ru", "Russian", "🇷🇺"),
            ("ja", "Japanese", "🇯🇵"),
            ("ko", "Korean", "🇰🇷"),
            ("zh", "Chinese", "🇨🇳"),
            ("ar", "Arabic", "🇸🇦"),
            ("hi", "Hindi", "🇮🇳")
        ]
    }
}

// MARK: - Sample Data
extension SubtitleTrack {
    static let sample = SubtitleTrack(
        id: "1",
        url: "https://example.com/subtitles/en.srt",
        language: "English",
        languageCode: "en",
        label: "English",
        format: .srt,
        isDefault: true,
        isForced: false,
        isSDH: false,
        encoding: "UTF-8",
        fileSize: 45678,
        lastModified: Date()
    )
    
    static let sampleTracks: [SubtitleTrack] = [
        SubtitleTrack(
            id: "1",
            url: "https://example.com/subtitles/en.srt",
            language: "English",
            languageCode: "en",
            label: "English",
            format: .srt,
            isDefault: true,
            isForced: false,
            isSDH: false,
            encoding: "UTF-8",
            fileSize: 45678,
            lastModified: Date()
        ),
        SubtitleTrack(
            id: "2",
            url: "https://example.com/subtitles/es.srt",
            language: "Spanish",
            languageCode: "es",
            label: "Español",
            format: .srt,
            isDefault: false,
            isForced: false,
            isSDH: false,
            encoding: "UTF-8",
            fileSize: 48234,
            lastModified: Date()
        ),
        SubtitleTrack(
            id: "3",
            url: "https://example.com/subtitles/en-sdh.srt",
            language: "English",
            languageCode: "en",
            label: "English",
            format: .srt,
            isDefault: false,
            isForced: false,
            isSDH: true,
            encoding: "UTF-8",
            fileSize: 52341,
            lastModified: Date()
        )
    ]
}