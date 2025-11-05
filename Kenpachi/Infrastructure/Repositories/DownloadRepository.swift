// DownloadRepository.swift
// Implementation of download repository
// Manages download data persistence and operations

import Foundation

/// Repository for managing downloads
final class DownloadRepository: DownloadRepositoryProtocol {
  /// Shared singleton instance
  static let shared = DownloadRepository()
  
  /// In-memory storage (TODO: Replace with CoreData)
  private var downloads: [Download] = []
  
  /// Private initializer for singleton
  private init() {}
  
  /// Fetch all downloads
  func fetchDownloads() async throws -> [Download] {
    /// TODO: Fetch from CoreData
    return downloads
  }
  
  /// Fetch download by ID
  func fetchDownload(id: String) async throws -> Download? {
    /// TODO: Fetch from CoreData
    return downloads.first { $0.id == id }
  }
  
  /// Create new download
  func createDownload(_ download: Download) async throws -> Download {
    /// TODO: Save to CoreData
    downloads.append(download)
    return download
  }
  
  /// Update existing download
  func updateDownload(_ download: Download) async throws -> Download {
    /// TODO: Update in CoreData
    if let index = downloads.firstIndex(where: { $0.id == download.id }) {
      downloads[index] = download
    }
    return download
  }
  
  /// Delete download
  func deleteDownload(id: String) async throws {
    // Find the download
    guard let download = downloads.first(where: { $0.id == id }) else {
      return
    }
    
    // Delete the file from file system if it exists
    if let localFilePath = download.localFilePath {
      FileManager.deleteDownloadedFile(at: localFilePath)
    }
    
    /// TODO: Delete from CoreData
    downloads.removeAll { $0.id == id }
  }
  
  /// Start download
  func startDownload(id: String) async throws {
    /// TODO: Implement download start logic
    guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
    downloads[index].state = .downloading
    downloads[index].updatedAt = Date()
  }
  
  /// Pause download
  func pauseDownload(id: String) async throws {
    /// TODO: Implement download pause logic
    guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
    downloads[index].state = .paused
    downloads[index].updatedAt = Date()
  }
  
  /// Resume download
  func resumeDownload(id: String) async throws {
    /// TODO: Implement download resume logic
    guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
    downloads[index].state = .downloading
    downloads[index].updatedAt = Date()
  }
  
  /// Cancel download
  func cancelDownload(id: String) async throws {
    /// TODO: Implement download cancel logic
    try await deleteDownload(id: id)
  }
  
  /// Get storage info
  func getStorageInfo() async throws -> (used: Int64, available: Int64) {
    // Get actual storage usage from file system
    let used = FileManager.getTotalDownloadsSize()
    
    // Get available storage from file system
    let available = FileManager.getAvailableStorageSpace() ?? 0
    
    return (used, available)
  }
  
  /// Clear completed downloads
  func clearCompletedDownloads() async throws {
    // Get completed downloads
    let completedDownloads = downloads.filter { $0.state == .completed }
    
    // Delete each completed download (including file)
    for download in completedDownloads {
      try await deleteDownload(id: download.id)
    }
    
    AppLogger.shared.log(
      "Cleared \(completedDownloads.count) completed downloads",
      level: .info
    )
  }
}
