import Foundation

struct Profile: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let avatarURL: String?
    let isPrimary: Bool
    let isKidsProfile: Bool
    let createdAt: Date
    
    var watchlist: [String] // Content IDs
    var watchHistory: [WatchHistoryItem]
    var preferences: ProfilePreferences
    var parentalControls: ParentalControls?
    
    struct WatchHistoryItem: Codable, Equatable {
        let contentId: String
        let contentType: ContentType
        let watchedAt: Date
        let progress: WatchProgress?
    }
    
    struct ProfilePreferences: Codable, Equatable {
        var preferredLanguages: [String]
        var maturityRating: MaturityRating
        var autoPlayNext: Bool
        var skipIntros: Bool
        var subtitlesEnabled: Bool
        var preferredSubtitleLanguage: String?
        
        enum MaturityRating: String, Codable, CaseIterable {
            case kids = "kids"        // G, TV-Y
            case family = "family"    // PG, TV-PG
            case teen = "teen"        // PG-13, TV-14
            case mature = "mature"    // R, TV-MA
            case adult = "adult"      // NC-17
        }
    }
    
    struct ParentalControls: Codable, Equatable {
        let maxMaturityRating: ProfilePreferences.MaturityRating
        let blockedContent: [String] // Content IDs
        let timeRestrictions: TimeRestrictions?
        let requirePinForPurchases: Bool
        
        struct TimeRestrictions: Codable, Equatable {
            let dailyLimit: TimeInterval? // in seconds
            let bedtime: TimeOfDay?
            let allowedDays: [Weekday]
            
            struct TimeOfDay: Codable, Equatable {
                let hour: Int
                let minute: Int
            }
            
            enum Weekday: String, Codable, CaseIterable {
                case monday, tuesday, wednesday, thursday, friday, saturday, sunday
            }
        }
    }
}