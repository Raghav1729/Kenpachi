// DownloadsFeature.swift
// TCA feature for downloads management
// Handles download operations, progress tracking, and storage management

import ComposableArchitecture
import Foundation

@Reducer
struct DownloadsFeature {
  
  /// Helper function to get total device storage
  private func getTotalDeviceStorage() -> Int64 {
    do {
      let fileURL = URL(fileURLWithPath: NSHomeDirectory())
      let values = try fileURL.resourceValues(forKeys: [
        .volumeTotalCapacityKey
      ])
      return Int64(values.volumeTotalCapacity ?? 0)
    } catch {
      return 0
    }
  }

  @ObservableState
  struct State: Equatable {
    /// List of downloads
    var downloads: [Download] = []
    /// Loading state
    var isLoading = false
    /// Error message
    var errorMessage: String?
    /// Total storage used
    var storageUsed: Int64 = 0
    /// Available storage (total device storage)
    var storageAvailable: Int64 = 0
    /// Show delete confirmation
    var showDeleteConfirmation = false
    /// Download to delete
    var downloadToDelete: Download?
    /// Show storage info
    var showStorageInfo = false
    /// Show player
    var showPlayer = false
    /// Download to play
    var downloadToPlay: Download?
    /// Show offline player
    var showOfflinePlayer = false
    /// Download to play offline
    var offlineDownloadToPlay: Download?
    /// Downloads being converted (downloadId -> progress)
    var convertingDownloads: [String: Double] = [:]
  }

  enum Action: Equatable {
    /// View appeared
    case onAppear
    /// View disappeared
    case onDisappear
    /// Refresh downloads
    case refresh
    /// Auto refresh tick
    case autoRefreshTick
    /// Downloads loaded
    case downloadsLoaded([Download])
    /// Storage info updated
    case storageInfoUpdated(used: Int64, available: Int64)
    /// Download tapped
    case downloadTapped(Download)
    /// Dismiss player
    case dismissPlayer
    /// Show offline player
    case showOfflinePlayer(Download)
    /// Dismiss offline player
    case dismissOfflinePlayer
    /// Delete download tapped
    case deleteDownloadTapped(Download)
    /// Confirm delete
    case confirmDelete
    /// Cancel delete
    case cancelDelete
    /// Download deleted
    case downloadDeleted(String)
    /// Pause download
    case pauseDownload(String)
    /// Resume download
    case resumeDownload(String)
    /// Cancel download
    case cancelDownload(String)
    /// Storage info tapped
    case storageInfoTapped
    /// Dismiss storage info
    case dismissStorageInfo
    /// Convert HLS to MP4
    case convertToMP4(Download)
    /// Conversion progress updated
    case conversionProgress(String, Double)
    /// Conversion completed successfully
    case conversionSuccess(String, URL)
    /// Conversion failed
    case conversionFailure(String, String)
    /// Error occurred
    case errorOccurred(String)
  }

  @Dependency(\.continuousClock) var clock

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        /// Load downloads and start auto-refresh
        return .merge(
          .send(.refresh),
          .run { send in
            for await _ in await clock.timer(interval: .seconds(5)) {
              await send(.autoRefreshTick)
            }
          }
          .cancellable(id: "autoRefresh")
        )

      case .onDisappear:
        /// Stop auto-refresh when view disappears
        return .cancel(id: "autoRefresh")

      case .autoRefreshTick:
        /// Auto-refresh downloads without showing loading state
        return .run { [self] send in
          await MainActor.run {
            let manager = DownloadQueueManager.shared
            
            // Ensure manager is initialized
            manager.initialize()
            
            // Debug logging
            manager.debugDownloadCounts()
            
            let allDownloads =
              manager.activeDownloads + manager.queuedDownloads + manager.completedDownloads
              + manager.failedDownloads
            
            AppLogger.shared.log("Loading \(allDownloads.count) downloads in DownloadsFeature", level: .debug)
            send(.downloadsLoaded(allDownloads))

            /// Calculate actual storage usage from file system
            let usedStorage = FileManager.getTotalDownloadsSize()
            let totalStorage = self.getTotalDeviceStorage()
            send(.storageInfoUpdated(used: usedStorage, available: totalStorage))
          }
        }

      case .refresh:
        /// Refresh downloads list
        state.isLoading = true
        state.errorMessage = nil

        return .run { [self] send in
          /// Fetch downloads from DownloadQueueManager
          await MainActor.run {
            let manager = DownloadQueueManager.shared
            
            // Ensure manager is initialized
            manager.initialize()
            
            // Debug logging
            manager.debugDownloadCounts()
            
            let allDownloads =
              manager.activeDownloads + manager.queuedDownloads + manager.completedDownloads
              + manager.failedDownloads
            
            AppLogger.shared.log("Refreshing \(allDownloads.count) downloads in DownloadsFeature", level: .debug)
            send(.downloadsLoaded(allDownloads))

            /// Calculate actual storage usage from file system
            let usedStorage = FileManager.getTotalDownloadsSize()
            let totalStorage = self.getTotalDeviceStorage()
            send(.storageInfoUpdated(used: usedStorage, available: totalStorage))
          }
        }

      case .downloadsLoaded(let downloads):
        /// Update downloads list
        state.isLoading = false
        state.downloads = downloads
        return .none

      case .storageInfoUpdated(let used, let available):
        /// Update storage info
        state.storageUsed = used
        state.storageAvailable = available
        return .none

      case .downloadTapped(let download):
        /// Handle download tap (play downloaded content)
        // Only play if download is completed
        guard download.state == .completed else { return .none }

        // Use offline player for local files
        state.offlineDownloadToPlay = download
        state.showOfflinePlayer = true
        return .none

      case .dismissPlayer:
        /// Dismiss player
        state.showPlayer = false
        state.downloadToPlay = nil
        return .none

      case .showOfflinePlayer(let download):
        /// Show offline player
        state.offlineDownloadToPlay = download
        state.showOfflinePlayer = true
        return .none

      case .dismissOfflinePlayer:
        /// Dismiss offline player
        state.showOfflinePlayer = false
        state.offlineDownloadToPlay = nil
        return .none

      case .deleteDownloadTapped(let download):
        /// Show delete confirmation
        state.downloadToDelete = download
        state.showDeleteConfirmation = true
        return .none

      case .confirmDelete:
        /// Delete download
        guard let download = state.downloadToDelete else { return .none }
        state.showDeleteConfirmation = false

        return .run { send in
          await MainActor.run {
            DownloadQueueManager.shared.deleteDownload(download.id)
          }
          await send(.downloadDeleted(download.id))
          await send(.refresh)
        }

      case .cancelDelete:
        /// Cancel delete
        state.showDeleteConfirmation = false
        state.downloadToDelete = nil
        return .none

      case .downloadDeleted:
        /// Download deleted successfully
        return .send(.refresh)

      case .pauseDownload(let id):
        /// Pause download
        return .run { send in
          await MainActor.run {
            DownloadQueueManager.shared.pauseDownload(id)
          }
          await send(.refresh)
        }

      case .resumeDownload(let id):
        /// Resume download
        return .run { send in
          await MainActor.run {
            DownloadQueueManager.shared.resumeDownload(id)
          }
          await send(.refresh)
        }

      case .cancelDownload(let id):
        /// Cancel download
        return .run { send in
          await MainActor.run {
            DownloadQueueManager.shared.cancelDownload(id)
          }
          await send(.refresh)
        }

      case .storageInfoTapped:
        /// Show storage info
        state.showStorageInfo = true
        return .none

      case .dismissStorageInfo:
        /// Dismiss storage info
        state.showStorageInfo = false
        return .none

      case .convertToMP4(let download):
        /// Convert HLS download to MP4
        guard let localFilePath = download.localFilePath,
              FileManager.isHLSPackage(at: localFilePath) else {
          return .send(.errorOccurred("File is not an HLS package"))
        }
        
        state.convertingDownloads[download.id] = 0.0
        
        return .run { send in
          do {
            let mp4URL = try await FileManager.convertHLSToMP4(
              movpkgURL: localFilePath,
              deleteOriginal: true,
              progress: { progress in
                Task { @MainActor in
                  send(.conversionProgress(download.id, progress))
                }
              }
            )
            await send(.conversionSuccess(download.id, mp4URL))
          } catch {
            await send(.conversionFailure(download.id, error.localizedDescription))
          }
        }

      case .conversionProgress(let downloadId, let progress):
        /// Update conversion progress
        state.convertingDownloads[downloadId] = progress
        return .none

      case .conversionSuccess(let downloadId, let mp4URL):
        /// Handle successful conversion
        state.convertingDownloads.removeValue(forKey: downloadId)
        
        // Update the download's local file path to point to the MP4
        if let index = state.downloads.firstIndex(where: { $0.id == downloadId }) {
          var updatedDownload = state.downloads[index]
          updatedDownload.localFilePath = mp4URL
          state.downloads[index] = updatedDownload
          
          // Update in DownloadQueueManager as well
          DownloadQueueManager.shared.updateDownloadFilePath(downloadId, newPath: mp4URL)
        }
        return .send(.refresh)

      case .conversionFailure(let downloadId, let errorMessage):
        /// Handle conversion failure
        state.convertingDownloads.removeValue(forKey: downloadId)
        return .send(.errorOccurred("Conversion failed: \(errorMessage)"))

      case .errorOccurred(let message):
        /// Handle error
        state.errorMessage = message
        state.isLoading = false
        return .none
      }
    }
  }
}