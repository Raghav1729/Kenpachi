import Foundation

struct DownloadQueue: Codable, Equatable {
    let id: String
    let profileId: String
    let items: [DownloadQueueItem]
    let maxConcurrentDownloads: Int
    let isWiFiOnly: Bool
    let createdAt: Date
    let lastUpdated: Date
    
    init(
        id: String = UUID().uuidString,
        profileId: String,
        items: [DownloadQueueItem] = [],
        maxConcurrentDownloads: Int = 3,
        isWiFiOnly: Bool = true,
        createdAt: Date = Date(),
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.profileId = profileId
        self.items = items
        self.maxConcurrentDownloads = maxConcurrentDownloads
        self.isWiFiOnly = isWiFiOnly
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
    }
}

struct DownloadQueueItem: Identifiable, Codable, Equatable {
    let id: String
    let downloadId: String
    let priority: DownloadPriority
    let addedAt: Date
    let estimatedSize: Int64
    let quality: StreamingQuality
    
    init(
        id: String = UUID().uuidString,
        downloadId: String,
        priority: DownloadPriority = .normal,
        addedAt: Date = Date(),
        estimatedSize: Int64,
        quality: StreamingQuality
    ) {
        self.id = id
        self.downloadId = downloadId
        self.priority = priority
        self.addedAt = addedAt
        self.estimatedSize = estimatedSize
        self.quality = quality
    }
}

enum DownloadPriority: Int, Codable, CaseIterable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    static func < (lhs: DownloadPriority, rhs: DownloadPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Queue Management
extension DownloadQueue {
    var activeDownloads: [DownloadQueueItem] {
        items.filter { item in
            // In a real implementation, you'd check the actual download status
            true // Placeholder
        }
    }
    
    var queuedDownloads: [DownloadQueueItem] {
        items.filter { item in
            // In a real implementation, you'd check if the download is queued
            true // Placeholder
        }
    }
    
    var totalEstimatedSize: Int64 {
        items.reduce(0) { $0 + $1.estimatedSize }
    }
    
    var formattedTotalSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalEstimatedSize)
    }
    
    var canStartNewDownload: Bool {
        activeDownloads.count < maxConcurrentDownloads
    }
    
    var nextItemToDownload: DownloadQueueItem? {
        queuedDownloads
            .sorted { $0.priority > $1.priority || ($0.priority == $1.priority && $0.addedAt < $1.addedAt) }
            .first
    }
    
    func adding(_ item: DownloadQueueItem) -> DownloadQueue {
        var newItems = items
        newItems.append(item)
        
        return DownloadQueue(
            id: id,
            profileId: profileId,
            items: newItems,
            maxConcurrentDownloads: maxConcurrentDownloads,
            isWiFiOnly: isWiFiOnly,
            createdAt: createdAt,
            lastUpdated: Date()
        )
    }
    
    func removing(itemId: String) -> DownloadQueue {
        let newItems = items.filter { $0.id != itemId }
        
        return DownloadQueue(
            id: id,
            profileId: profileId,
            items: newItems,
            maxConcurrentDownloads: maxConcurrentDownloads,
            isWiFiOnly: isWiFiOnly,
            createdAt: createdAt,
            lastUpdated: Date()
        )
    }
    
    func updatingPriority(itemId: String, priority: DownloadPriority) -> DownloadQueue {
        let newItems = items.map { item in
            if item.id == itemId {
                return DownloadQueueItem(
                    id: item.id,
                    downloadId: item.downloadId,
                    priority: priority,
                    addedAt: item.addedAt,
                    estimatedSize: item.estimatedSize,
                    quality: item.quality
                )
            }
            return item
        }
        
        return DownloadQueue(
            id: id,
            profileId: profileId,
            items: newItems,
            maxConcurrentDownloads: maxConcurrentDownloads,
            isWiFiOnly: isWiFiOnly,
            createdAt: createdAt,
            lastUpdated: Date()
        )
    }
}

// MARK: - Sample Data
extension DownloadQueue {
    static let sample = DownloadQueue(
        profileId: "profile_1",
        items: [
            DownloadQueueItem(
                downloadId: "download_1",
                priority: .high,
                estimatedSize: 4294967296, // 4GB
                quality: .hd1080
            ),
            DownloadQueueItem(
                downloadId: "download_2",
                priority: .normal,
                estimatedSize: 2147483648, // 2GB
                quality: .hd720
            ),
            DownloadQueueItem(
                downloadId: "download_3",
                priority: .low,
                estimatedSize: 1073741824, // 1GB
                quality: .sd480
            )
        ],
        maxConcurrentDownloads: 3,
        isWiFiOnly: true
    )
}