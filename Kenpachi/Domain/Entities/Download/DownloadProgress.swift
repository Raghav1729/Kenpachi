import Foundation

struct DownloadProgress: Codable, Equatable {
    let downloadedBytes: Int64
    let totalBytes: Int64
    let downloadSpeed: Double? // bytes per second
    let timeRemaining: TimeInterval? // seconds
    let lastUpdated: Date
    
    // Network statistics
    let averageSpeed: Double? // bytes per second over entire download
    let peakSpeed: Double? // highest recorded speed
    let connectionCount: Int // number of concurrent connections
    let retryCount: Int
    
    init(
        downloadedBytes: Int64,
        totalBytes: Int64,
        downloadSpeed: Double? = nil,
        timeRemaining: TimeInterval? = nil,
        lastUpdated: Date = Date(),
        averageSpeed: Double? = nil,
        peakSpeed: Double? = nil,
        connectionCount: Int = 1,
        retryCount: Int = 0
    ) {
        self.downloadedBytes = downloadedBytes
        self.totalBytes = totalBytes
        self.downloadSpeed = downloadSpeed
        self.timeRemaining = timeRemaining
        self.lastUpdated = lastUpdated
        self.averageSpeed = averageSpeed
        self.peakSpeed = peakSpeed
        self.connectionCount = connectionCount
        self.retryCount = retryCount
    }
}

// MARK: - Computed Properties
extension DownloadProgress {
    var percentage: Double {
        guard totalBytes > 0 else { return 0 }
        return min(Double(downloadedBytes) / Double(totalBytes), 1.0)
    }
    
    var percentageInt: Int {
        Int(percentage * 100)
    }
    
    var remainingBytes: Int64 {
        max(totalBytes - downloadedBytes, 0)
    }
    
    var isCompleted: Bool {
        downloadedBytes >= totalBytes
    }
    
    var formattedDownloadSpeed: String? {
        guard let speed = downloadSpeed, speed > 0 else { return nil }
        return formatBytesPerSecond(speed)
    }
    
    var formattedAverageSpeed: String? {
        guard let speed = averageSpeed, speed > 0 else { return nil }
        return formatBytesPerSecond(speed)
    }
    
    var formattedPeakSpeed: String? {
        guard let speed = peakSpeed, speed > 0 else { return nil }
        return formatBytesPerSecond(speed)
    }
    
    var formattedTimeRemaining: String? {
        guard let timeRemaining = timeRemaining, timeRemaining > 0 else { return nil }
        return formatTimeInterval(timeRemaining)
    }
    
    var formattedDownloadedSize: String {
        formatBytes(downloadedBytes)
    }
    
    var formattedTotalSize: String {
        formatBytes(totalBytes)
    }
    
    var formattedRemainingSize: String {
        formatBytes(remainingBytes)
    }
    
    var progressText: String {
        return "\(formattedDownloadedSize) / \(formattedTotalSize)"
    }
    
    var detailedProgressText: String {
        var components: [String] = [progressText]
        
        if let speed = formattedDownloadSpeed {
            components.append(speed)
        }
        
        if let remaining = formattedTimeRemaining {
            components.append(remaining + " left")
        }
        
        return components.joined(separator: " • ")
    }
}

// MARK: - Helper Methods
private extension DownloadProgress {
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func formatBytesPerSecond(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }
    
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Progress Updates
extension DownloadProgress {
    func updated(
        downloadedBytes: Int64? = nil,
        downloadSpeed: Double? = nil,
        timeRemaining: TimeInterval? = nil,
        connectionCount: Int? = nil
    ) -> DownloadProgress {
        return DownloadProgress(
            downloadedBytes: downloadedBytes ?? self.downloadedBytes,
            totalBytes: self.totalBytes,
            downloadSpeed: downloadSpeed ?? self.downloadSpeed,
            timeRemaining: timeRemaining ?? self.timeRemaining,
            lastUpdated: Date(),
            averageSpeed: self.averageSpeed,
            peakSpeed: max(self.peakSpeed ?? 0, downloadSpeed ?? 0),
            connectionCount: connectionCount ?? self.connectionCount,
            retryCount: self.retryCount
        )
    }
    
    func withRetry() -> DownloadProgress {
        return DownloadProgress(
            downloadedBytes: self.downloadedBytes,
            totalBytes: self.totalBytes,
            downloadSpeed: nil,
            timeRemaining: nil,
            lastUpdated: Date(),
            averageSpeed: self.averageSpeed,
            peakSpeed: self.peakSpeed,
            connectionCount: self.connectionCount,
            retryCount: self.retryCount + 1
        )
    }
}

// MARK: - Sample Data
extension DownloadProgress {
    static let sample = DownloadProgress(
        downloadedBytes: 2147483648, // 2GB
        totalBytes: 4294967296, // 4GB
        downloadSpeed: 5242880, // 5MB/s
        timeRemaining: 409, // ~6.8 minutes
        lastUpdated: Date(),
        averageSpeed: 4194304, // 4MB/s average
        peakSpeed: 8388608, // 8MB/s peak
        connectionCount: 4,
        retryCount: 0
    )
    
    static let completed = DownloadProgress(
        downloadedBytes: 4294967296, // 4GB
        totalBytes: 4294967296, // 4GB
        downloadSpeed: 0,
        timeRemaining: 0,
        lastUpdated: Date(),
        averageSpeed: 4194304, // 4MB/s average
        peakSpeed: 8388608, // 8MB/s peak
        connectionCount: 1,
        retryCount: 0
    )
    
    static let starting = DownloadProgress(
        downloadedBytes: 0,
        totalBytes: 4294967296, // 4GB
        downloadSpeed: nil,
        timeRemaining: nil,
        lastUpdated: Date(),
        averageSpeed: nil,
        peakSpeed: nil,
        connectionCount: 1,
        retryCount: 0
    )
}