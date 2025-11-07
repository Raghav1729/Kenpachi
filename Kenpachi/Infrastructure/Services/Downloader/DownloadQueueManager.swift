// DownloadQueueManager.swift
// Download queue manager for handling multiple downloads
// Manages download queue, concurrency, and persistence

import Foundation

/// Download queue manager for coordinating multiple downloads
/// Handles download queue, concurrency limits, and state persistence
@Observable
final class DownloadQueueManager {
  /// Shared singleton instance
  static let shared = DownloadQueueManager()

  /// Array of active downloads
  var activeDownloads: [Download] = []
  /// Array of queued downloads
  var queuedDownloads: [Download] = []
  /// Array of completed downloads
  var completedDownloads: [Download] = []
  /// Array of failed downloads
  var failedDownloads: [Download] = []

  /// Maximum concurrent downloads allowed
  private let maxConcurrentDownloads = AppConstants.Downloads.maxConcurrentDownloads
  /// Whether manager is initialized
  private var isInitialized = false

  /// Private initializer for singleton
  private init() {
    // Log initialization
    AppLogger.shared.log(
      "DownloadQueueManager initialized",
      level: .debug
    )
  }

  /// Initializes download queue manager
  /// Loads persisted downloads and sets up observers
  func initialize() {
    AppLogger.shared.log("DownloadQueueManager.initialize() called", level: .debug)
    
    // Check if already initialized
    if isInitialized {
      AppLogger.shared.log("DownloadQueueManager already initialized", level: .debug)
      return
    }

    // Load persisted downloads from storage
    loadPersistedDownloads()

    // Mark as initialized
    isInitialized = true

    // Log initialization complete
    AppLogger.shared.log(
      "DownloadQueueManager initialization complete",
      level: .info
    )
    
    // Debug check after initialization
    debugDownloadCounts()
  }

  /// Adds a download to the queue
  /// - Parameters:
  ///   - download: Download to add
  ///   - stream: Extracted stream link for download
  func addDownload(_ download: Download, stream: ExtractedLink) {
    // Check if download already exists
    guard !downloadExists(download.id) else {
      AppLogger.shared.log(
        "Download already exists: \(download.id)",
        level: .warning
      )
      return
    }

    // Check if can start download immediately
    if activeDownloads.count < maxConcurrentDownloads {
      // Add to active downloads
      var mutableDownload = download
      mutableDownload.state = .downloading
      activeDownloads.append(mutableDownload)
      // Start download
      startDownload(mutableDownload, stream: stream)
    } else {
      // Add to queued downloads
      queuedDownloads.append(download)

      // Log queued
      AppLogger.shared.log(
        "Download queued: \(download.content.title)",
        level: .debug
      )
    }

    // Persist downloads
    persistDownloads()
  }

  /// Starts a download
  /// - Parameters:
  ///   - download: Download to start
  ///   - stream: Extracted stream link for download
  private func startDownload(_ download: Download, stream: ExtractedLink) {
    // Use AVDownloaderService to handle the actual download
    AVDownloaderService.shared.startDownload(
      downloadId: download.id,
      link: stream,
      quality: download.quality ?? .hd720,
      download: download,
      progress: { [weak self] progress in
        // Update download progress
        self?.updateDownloadProgress(downloadId: download.id, progress: progress)
      },
      completion: { [weak self] result in
        // Handle download completion
        self?.handleDownloadCompletion(downloadId: download.id, result: result)
      }
    )

    // Log download started
    AppLogger.shared.log(
      "Download started: \(download.content.title)",
      level: .info
    )
  }

  /// Updates download progress
  /// - Parameters:
  ///   - downloadId: ID of the download
  ///   - progress: Progress value (0.0 to 1.0)
  private func updateDownloadProgress(downloadId: String, progress: Double) {
    // Find download in active downloads
    guard let index = activeDownloads.firstIndex(where: { $0.id == downloadId }) else {
      return
    }

    // Update progress
    activeDownloads[index].progress = progress
    activeDownloads[index].updatedAt = Date()

    // Persist downloads
    persistDownloads()
  }

  /// Handles download completion
  /// - Parameters:
  ///   - downloadId: ID of the download
  ///   - result: Result of the download
  private func handleDownloadCompletion(downloadId: String, result: Result<URL, Error>) {
    // Find download in active downloads
    guard let index = activeDownloads.firstIndex(where: { $0.id == downloadId }) else {
      return
    }

    // Get download
    var download = activeDownloads.remove(at: index)

    // Update download based on result
    switch result {
    case .success(let fileURL):
      download.state = .completed
      download.localFilePath = fileURL
      download.completedAt = Date()
      download.progress = 1.0
      completedDownloads.append(download)

      AppLogger.shared.log(
        "Download completed: \(download.content.title)",
        level: .info
      )

    case .failure(let error):
      download.state = .failed
      failedDownloads.append(download)

      AppLogger.shared.log(
        "Download failed: \(download.content.title) - \(error.localizedDescription)",
        level: .error
      )
    }

    // Start next queued download
    startNextQueuedDownload()

    // Persist downloads
    persistDownloads()
  }

  /// Pauses a download
  /// - Parameter downloadId: ID of download to pause
  func pauseDownload(_ downloadId: String) {
    // Find download in active downloads
    guard let index = activeDownloads.firstIndex(where: { $0.id == downloadId }) else {
      return
    }

    // Update download state
    activeDownloads[index].state = .paused
    activeDownloads[index].updatedAt = Date()

    // Pause download in AVDownloaderService
    AVDownloaderService.shared.pauseDownload(downloadId: downloadId)

    // Log pause
    AppLogger.shared.log(
      "Download paused: \(activeDownloads[index].content.title)",
      level: .debug
    )

    // Persist downloads
    persistDownloads()
  }

  /// Resumes a download
  /// - Parameter downloadId: ID of download to resume
  func resumeDownload(_ downloadId: String) {
    // Find download in active downloads
    if let index = activeDownloads.firstIndex(where: { $0.id == downloadId }) {
      // Update download state
      activeDownloads[index].state = .downloading
      activeDownloads[index].updatedAt = Date()

      // Resume download in AVDownloaderService
      AVDownloaderService.shared.resumeDownload(downloadId: downloadId)

      // Log resume
      AppLogger.shared.log(
        "Download resumed: \(activeDownloads[index].content.title)",
        level: .debug
      )
    }

    // Persist downloads
    persistDownloads()
  }

  /// Cancels a download
  /// - Parameter downloadId: ID of download to cancel
  func cancelDownload(_ downloadId: String) {
    // Remove from active downloads
    if let index = activeDownloads.firstIndex(where: { $0.id == downloadId }) {
      let download = activeDownloads.remove(at: index)

      // Cancel download in AVDownloaderService
      AVDownloaderService.shared.cancelDownload(downloadId: downloadId)

      // Log cancellation
      AppLogger.shared.log(
        "Download cancelled: \(download.content.title)",
        level: .debug
      )

      // Start next queued download
      startNextQueuedDownload()
    }
    // Remove from queued downloads
    else if let index = queuedDownloads.firstIndex(where: { $0.id == downloadId }) {
      let download = queuedDownloads.remove(at: index)

      // Log cancellation
      AppLogger.shared.log(
        "Queued download cancelled: \(download.content.title)",
        level: .debug
      )
    }

    // Persist downloads
    persistDownloads()
  }

  /// Deletes a completed download
  /// - Parameter downloadId: ID of download to delete
  func deleteDownload(_ downloadId: String) {
    var deleted = false

    // Helper to delete file from disk if present
    func deleteFileIfPresent(for download: Download) {
      if let fileURL = download.localFilePath,
         FileManager.default.fileExists(atPath: fileURL.path) {
        do {
          try FileManager.default.removeItem(at: fileURL)
          AppLogger.shared.log("Deleted file from disk: \(fileURL.lastPathComponent)", level: .info)
        } catch {
          AppLogger.shared.log("Failed to delete file: \(error)", level: .error)
        }
      }
    }

    // If active, cancel and remove
    if let idx = activeDownloads.firstIndex(where: { $0.id == downloadId }) {
      let download = activeDownloads.remove(at: idx)
      AVDownloaderService.shared.cancelDownload(downloadId: downloadId)
      deleteFileIfPresent(for: download)
      AppLogger.shared.log("Active download deleted: \(download.content.title)", level: .debug)
      deleted = true
    }

    // If queued, remove
    if let idx = queuedDownloads.firstIndex(where: { $0.id == downloadId }) {
      let download = queuedDownloads.remove(at: idx)
      AppLogger.shared.log("Queued download deleted: \(download.content.title)", level: .debug)
      deleted = true
    }

    // If completed, remove and delete file
    if let idx = completedDownloads.firstIndex(where: { $0.id == downloadId }) {
      let download = completedDownloads.remove(at: idx)
      deleteFileIfPresent(for: download)
      AppLogger.shared.log("Completed download deleted: \(download.content.title)", level: .debug)
      deleted = true
    }

    // If failed, remove
    if let idx = failedDownloads.firstIndex(where: { $0.id == downloadId }) {
      let download = failedDownloads.remove(at: idx)
      deleteFileIfPresent(for: download)
      AppLogger.shared.log("Failed download deleted: \(download.content.title)", level: .debug)
      deleted = true
    }

    if deleted {
      // Persist downloads
      persistDownloads()
      // Start next if slot freed
      startNextQueuedDownload()
    }
  }

  /// Resumes all pending downloads
  /// Called when app returns to foreground or network becomes available
  func resumePendingDownloads() {
    // Resume all paused active downloads
    for _ in activeDownloads {
      // TODO: Check download state and resume if paused
    }

    // Start queued downloads if slots available
    while activeDownloads.count < maxConcurrentDownloads && !queuedDownloads.isEmpty {
      startNextQueuedDownload()
    }

    // Log resume
    AppLogger.shared.log(
      "Resumed pending downloads",
      level: .debug
    )
  }

  /// Pauses downloads when on cellular network
  /// Called when network switches to cellular and setting is enabled
  func pauseDownloadsOnCellular() {
    // Check if download over cellular is disabled
    let downloadOverCellular = UserDefaults.standard.bool(
      forKey: AppConstants.StorageKeys.downloadOverCellular
    )

    // Pause all active downloads if cellular downloads disabled
    if !downloadOverCellular {
      for download in activeDownloads {
        pauseDownload(download.id)
      }

      // Log pause
      AppLogger.shared.log(
        "Downloads paused on cellular network",
        level: .info
      )
    }
  }

  /// Starts next queued download
  /// Moves download from queue to active and starts it
  private func startNextQueuedDownload() {
    // Check if queue has downloads and slots available
    guard !queuedDownloads.isEmpty,
      activeDownloads.count < maxConcurrentDownloads
    else {
      return
    }

    // Get next download from queue
    var download = queuedDownloads.removeFirst()
    download.state = .downloading

    // Add to active downloads
    activeDownloads.append(download)

    // Note: We need to store the stream link with the download
    // For now, we'll need to re-extract the stream link
    // In a production app, you'd want to store the stream link with the download
    AppLogger.shared.log(
      "Cannot start queued download without stream link: \(download.content.title)",
      level: .warning
    )
  }

  /// Checks if download exists in any queue
  /// - Parameter downloadId: Download ID to check
  /// - Returns: True if download exists
  private func downloadExists(_ downloadId: String) -> Bool {
    return activeDownloads.contains(where: { $0.id == downloadId })
      || queuedDownloads.contains(where: { $0.id == downloadId })
      || completedDownloads.contains(where: { $0.id == downloadId })
  }
  
  /// Updates the local file path for a download (e.g., after conversion)
  /// - Parameters:
  ///   - downloadId: Download ID to update
  ///   - newPath: New file path
  func updateDownloadFilePath(_ downloadId: String, newPath: URL) {
    // Update in completed downloads
    if let index = completedDownloads.firstIndex(where: { $0.id == downloadId }) {
      completedDownloads[index].localFilePath = newPath
      persistDownloads()
      AppLogger.shared.log(
        "Updated file path for download: \(downloadId)",
        level: .info
      )
    }
  }
  
  /// Debug method to check current download counts
  func debugDownloadCounts() {
    AppLogger.shared.log(
      "Current downloads - Active: \(activeDownloads.count), Queued: \(queuedDownloads.count), Completed: \(completedDownloads.count), Failed: \(failedDownloads.count)",
      level: .debug
    )
  }
  
  /// Debug method to force reload from persistence
  func debugReloadFromPersistence() {
    AppLogger.shared.log("Debug: Force reloading from persistence", level: .debug)
    loadPersistedDownloads()
    debugDownloadCounts()
  }
  
  /// Debug method to force save to persistence
  func debugForcePersist() {
    AppLogger.shared.log("Debug: Force persisting downloads", level: .debug)
    persistDownloads()
  }
  
  /// Debug method to clear all UserDefaults data
  func debugClearPersistence() {
    UserDefaults.standard.removeObject(forKey: "activeDownloads")
    UserDefaults.standard.removeObject(forKey: "queuedDownloads")
    UserDefaults.standard.removeObject(forKey: "completedDownloads")
    UserDefaults.standard.removeObject(forKey: "failedDownloads")
    AppLogger.shared.log("Debug: Cleared all persisted download data", level: .debug)
  }
  
  /// Debug method to check UserDefaults data
  func debugCheckUserDefaults() {
    let hasActive = UserDefaults.standard.data(forKey: "activeDownloads") != nil
    let hasQueued = UserDefaults.standard.data(forKey: "queuedDownloads") != nil
    let hasCompleted = UserDefaults.standard.data(forKey: "completedDownloads") != nil
    let hasFailed = UserDefaults.standard.data(forKey: "failedDownloads") != nil
    
    AppLogger.shared.log(
      "UserDefaults check - Active: \(hasActive), Queued: \(hasQueued), Completed: \(hasCompleted), Failed: \(hasFailed)",
      level: .debug
    )
    
    if let completedData = UserDefaults.standard.data(forKey: "completedDownloads") {
      AppLogger.shared.log("Completed downloads data size: \(completedData.count) bytes", level: .debug)
    }
  }

  /// Persists downloads to storage
  /// Saves download state for restoration
  private func persistDownloads() {
    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601

      // Encode all download arrays
      let activeData = try encoder.encode(activeDownloads)
      let queuedData = try encoder.encode(queuedDownloads)
      let completedData = try encoder.encode(completedDownloads)
      let failedData = try encoder.encode(failedDownloads)

      // Save to UserDefaults
      UserDefaults.standard.set(activeData, forKey: "activeDownloads")
      UserDefaults.standard.set(queuedData, forKey: "queuedDownloads")
      UserDefaults.standard.set(completedData, forKey: "completedDownloads")
      UserDefaults.standard.set(failedData, forKey: "failedDownloads")

      AppLogger.shared.log(
        "Downloads persisted: \(activeDownloads.count) active, \(completedDownloads.count) completed",
        level: .debug
      )
    } catch {
      AppLogger.shared.log(
        "Failed to persist downloads: \(error)",
        level: .error
      )
    }
  }

  /// Loads persisted downloads from storage
  /// Restores download state on app launch
  private func loadPersistedDownloads() {
    AppLogger.shared.log("Starting to load persisted downloads", level: .debug)
    
    // Check if UserDefaults has any data
    let hasActiveData = UserDefaults.standard.data(forKey: "activeDownloads") != nil
    let hasQueuedData = UserDefaults.standard.data(forKey: "queuedDownloads") != nil
    let hasCompletedData = UserDefaults.standard.data(forKey: "completedDownloads") != nil
    let hasFailedData = UserDefaults.standard.data(forKey: "failedDownloads") != nil
    
    AppLogger.shared.log(
      "UserDefaults data availability - Active: \(hasActiveData), Queued: \(hasQueuedData), Completed: \(hasCompletedData), Failed: \(hasFailedData)",
      level: .debug
    )
    
    do {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      // Load from UserDefaults
      if let activeData = UserDefaults.standard.data(forKey: "activeDownloads") {
        activeDownloads = try decoder.decode([Download].self, from: activeData)
        AppLogger.shared.log("Loaded \(activeDownloads.count) active downloads", level: .debug)
      }

      if let queuedData = UserDefaults.standard.data(forKey: "queuedDownloads") {
        queuedDownloads = try decoder.decode([Download].self, from: queuedData)
        AppLogger.shared.log("Loaded \(queuedDownloads.count) queued downloads", level: .debug)
      }

      if let completedData = UserDefaults.standard.data(forKey: "completedDownloads") {
        let loadedCompleted = try decoder.decode([Download].self, from: completedData)
        AppLogger.shared.log("Loaded \(loadedCompleted.count) completed downloads from storage", level: .debug)

        // Verify that downloaded files still exist
        completedDownloads = loadedCompleted.filter { download in
          guard let filePath = download.localFilePath else { 
            AppLogger.shared.log("Download has no local file path: \(download.content.title)", level: .warning)
            return false 
          }
          let fileExists = FileManager.default.fileExists(atPath: filePath.path)
          if !fileExists {
            AppLogger.shared.log(
              "Downloaded file missing: \(download.content.title) at \(filePath.path)",
              level: .warning
            )
          } else {
            AppLogger.shared.log(
              "Verified file exists: \(download.content.title) at \(filePath.path)",
              level: .debug
            )
          }
          return fileExists
        }
        
        AppLogger.shared.log("After file verification: \(completedDownloads.count) completed downloads", level: .debug)
      }

      if let failedData = UserDefaults.standard.data(forKey: "failedDownloads") {
        failedDownloads = try decoder.decode([Download].self, from: failedData)
        AppLogger.shared.log("Loaded \(failedDownloads.count) failed downloads", level: .debug)
      }

      AppLogger.shared.log(
        "Persisted downloads loaded: \(activeDownloads.count) active, \(queuedDownloads.count) queued, \(completedDownloads.count) completed, \(failedDownloads.count) failed",
        level: .info
      )
    } catch {
      AppLogger.shared.log(
        "Failed to load persisted downloads: \(error)",
        level: .error
      )
    }
  }
}
