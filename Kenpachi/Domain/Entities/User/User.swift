import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    let displayName: String
    let avatarURL: String?
    let isPremium: Bool
    let subscriptionType: SubscriptionType
    let subscriptionExpiresAt: Date?
    
    // User preferences
    let preferences: UserPreferences
    let profiles: [UserProfile]
    let activeProfileId: String?
    
    // Statistics
    let totalWatchTime: TimeInterval // in seconds
    let contentWatched: Int
    let favoriteGenres: [Genre]
}

enum SubscriptionType: String, Codable, CaseIterable {
    case free = "free"
    case premium = "premium"
    case family = "family"
    case student = "student"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        case .family: return "Family"
        case .student: return "Student"
        }
    }
    
    var maxProfiles: Int {
        switch self {
        case .free: return 1
        case .premium: return 3
        case .family: return 6
        case .student: return 2
        }
    }
    
    var canDownload: Bool {
        self != .free
    }
    
    var maxDownloads: Int {
        switch self {
        case .free: return 0
        case .premium: return 50
        case .family: return 100
        case .student: return 25
        }
    }
    
    var hasAds: Bool {
        self == .free
    }
    
    var maxQuality: StreamingQuality {
        switch self {
        case .free: return .hd720
        case .premium, .family, .student: return .uhd4k
        }
    }
}

// MARK: - Extensions
extension User {
    var activeProfile: UserProfile? {
        guard let activeProfileId = activeProfileId else { return profiles.first }
        return profiles.first { $0.id == activeProfileId }
    }
    
    var formattedWatchTime: String {
        let hours = Int(totalWatchTime) / 3600
        let days = hours / 24
        
        if days > 0 {
            return "\(days) days, \(hours % 24) hours"
        } else {
            return "\(hours) hours"
        }
    }
    
    var isSubscriptionActive: Bool {
        guard let expiresAt = subscriptionExpiresAt else {
            return subscriptionType == .free
        }
        return expiresAt > Date()
    }
    
    var canCreateProfile: Bool {
        profiles.count < subscriptionType.maxProfiles
    }
    
    var remainingDownloadSlots: Int {
        let downloadedCount = activeProfile?.downloadedContent.count ?? 0
        return max(subscriptionType.maxDownloads - downloadedCount, 0)
    }
}

// MARK: - Sample Data
extension User {
    static let sample = User(
        id: "user_123",
        displayName: "[name]",
        avatarURL: nil,
        isPremium: true,
        subscriptionType: .premium,
        subscriptionExpiresAt: Date().addingTimeInterval(86400 * 365), // 1 year from now
        preferences: UserPreferences.sample,
        profiles: [UserProfile.sample],
        activeProfileId: "profile_1",
        totalWatchTime: 86400 * 5, // 5 days worth of content
        contentWatched: 127,
        favoriteGenres: [
            Genre(id: 1, name: "Action"),
            Genre(id: 2, name: "Sci-Fi"),
            Genre(id: 3, name: "Drama")
        ]
    )
}