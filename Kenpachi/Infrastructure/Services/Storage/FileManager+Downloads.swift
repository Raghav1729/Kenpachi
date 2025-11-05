// FileManager+Downloads.swift
// Extension for managing download file operations
// Provides utilities for download directory management

import Foundation

/// Extension for download-related file operations
extension FileManager {
  
  /// Gets the Kenpachi downloads directory (accessible in Files app)
  /// - Returns: URL to Downloads directory in Documents (visible in Files app)
  static func getKenpachiDownloadsDirectory() -> URL? {
    let fileManager = FileManager.default
    
    // Get Documents directory - this is the root visible in Files app when UIFileSharingEnabled is true
    guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
      AppLogger.shared.log("Failed to get Documents directory", level: .error)
      return nil
    }
    
    // Create Downloads subdirectory directly in Documents
    // This will appear as "Downloads" folder in Files app under "On My iPhone" > "Kenpachi"
    let downloadsURL = documentsURL.appendingPathComponent("Downloads", isDirectory: true)
    
    // Create directory if it doesn't exist
    if !fileManager.fileExists(atPath: downloadsURL.path) {
      do {
        try fileManager.createDirectory(
          at: downloadsURL,
          withIntermediateDirectories: true,
          attributes: nil
        )
        
        AppLogger.shared.log(
          "Created downloads directory: \(downloadsURL.path)",
          level: .info
        )
        AppLogger.shared.log(
          "Files will be visible in Files app: On My iPhone > Kenpachi > Downloads",
          level: .info
        )
      } catch {
        AppLogger.shared.log(
          "Failed to create downloads directory: \(error)",
          level: .error
        )
        return nil
      }
    }
    
    return downloadsURL
  }
  
  /// Gets all downloaded files in the Kenpachi/Downloads directory
  /// - Returns: Array of file URLs
  static func getDownloadedFiles() -> [URL] {
    guard let downloadsURL = getKenpachiDownloadsDirectory() else {
      return []
    }
    
    let fileManager = FileManager.default
    
    do {
      let fileURLs = try fileManager.contentsOfDirectory(
        at: downloadsURL,
        includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
        options: [.skipsHiddenFiles]
      )
      
      return fileURLs
    } catch {
      AppLogger.shared.log(
        "Failed to list downloaded files: \(error)",
        level: .error
      )
      return []
    }
  }
  
  /// Gets the size of a file at the given URL
  /// - Parameter url: File URL
  /// - Returns: File size in bytes, or nil if unable to determine
  static func getFileSize(at url: URL) -> Int64? {
    let fileManager = FileManager.default
    
    // Check if it's a directory (like .movpkg for HLS downloads)
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
      return nil
    }
    
    if isDirectory.boolValue {
      // For directories (like .movpkg), calculate total size of all contents
      return getDirectorySize(at: url)
    } else {
      // For regular files, get file size directly
      do {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        if let fileSize = attributes[.size] as? Int64 {
          return fileSize
        }
      } catch {
        AppLogger.shared.log(
          "Failed to get file size for \(url.lastPathComponent): \(error)",
          level: .error
        )
      }
    }
    
    return nil
  }
  
  /// Gets the total size of a directory and all its contents
  /// - Parameter url: Directory URL
  /// - Returns: Total size in bytes
  private static func getDirectorySize(at url: URL) -> Int64 {
    let fileManager = FileManager.default
    var totalSize: Int64 = 0
    
    guard let enumerator = fileManager.enumerator(
      at: url,
      includingPropertiesForKeys: [.fileSizeKey],
      options: [.skipsHiddenFiles]
    ) else {
      return 0
    }
    
    for case let fileURL as URL in enumerator {
      do {
        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        if let fileSize = attributes[.size] as? Int64 {
          totalSize += fileSize
        }
      } catch {
        // Continue even if one file fails
        continue
      }
    }
    
    return totalSize
  }
  
  /// Deletes a downloaded file
  /// - Parameter url: File URL to delete
  /// - Returns: True if deletion was successful
  @discardableResult
  static func deleteDownloadedFile(at url: URL) -> Bool {
    let fileManager = FileManager.default
    
    do {
      try fileManager.removeItem(at: url)
      AppLogger.shared.log(
        "Deleted file: \(url.lastPathComponent)",
        level: .info
      )
      return true
    } catch {
      AppLogger.shared.log(
        "Failed to delete file \(url.lastPathComponent): \(error)",
        level: .error
      )
      return false
    }
  }
  
  /// Gets total size of all downloads
  /// - Returns: Total size in bytes
  static func getTotalDownloadsSize() -> Int64 {
    let files = getDownloadedFiles()
    var totalSize: Int64 = 0
    
    for file in files {
      if let size = getFileSize(at: file) {
        totalSize += size
      }
    }
    
    return totalSize
  }
  
  /// Gets available storage space
  /// - Returns: Available space in bytes, or nil if unable to determine
  static func getAvailableStorageSpace() -> Int64? {
    let fileManager = FileManager.default
    
    do {
      let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
      if let freeSize = attributes[.systemFreeSize] as? Int64 {
        return freeSize
      }
    } catch {
      AppLogger.shared.log(
        "Failed to get available storage: \(error)",
        level: .error
      )
    }
    
    return nil
  }
  
  /// Clears all downloaded files
  /// - Returns: Number of files deleted
  @discardableResult
  static func clearAllDownloads() -> Int {
    let files = getDownloadedFiles()
    var deletedCount = 0
    
    for file in files {
      if deleteDownloadedFile(at: file) {
        deletedCount += 1
      }
    }
    
    AppLogger.shared.log(
      "Cleared \(deletedCount) downloaded files",
      level: .info
    )
    
    return deletedCount
  }
  
  /// Checks if a file exists at the given path
  /// - Parameter url: File URL to check
  /// - Returns: True if file exists
  static func downloadedFileExists(at url: URL) -> Bool {
    return FileManager.default.fileExists(atPath: url.path)
  }
  
  /// Checks if a download is an HLS package (.movpkg)
  /// - Parameter url: File URL to check
  /// - Returns: True if it's an HLS package
  static func isHLSPackage(at url: URL) -> Bool {
    return url.pathExtension.lowercased() == "movpkg"
  }
  
  /// Converts all .movpkg files in downloads to MP4 format
  /// - Parameter progress: Progress callback for each file
  /// - Returns: Number of files converted successfully
  @discardableResult
  static func convertAllHLSToMP4(progress: @escaping (String, Double) -> Void = { _, _ in }) async -> Int {
    let files = getDownloadedFiles()
    let movpkgFiles = files.filter { isHLSPackage(at: $0) }
    
    guard !movpkgFiles.isEmpty else {
      AppLogger.shared.log("No .movpkg files to convert", level: .info)
      return 0
    }
    
    AppLogger.shared.log("Found \(movpkgFiles.count) .movpkg files to convert", level: .info)
    
    var successCount = 0
    
    for movpkgURL in movpkgFiles {
      do {
        let mp4URL = try await HLSConverter.shared.convertToMP4(
          movpkgURL: movpkgURL,
          quality: .high,
          progress: { conversionProgress in
            progress(movpkgURL.lastPathComponent, conversionProgress)
          }
        )
        
        // Delete original .movpkg after successful conversion
        try FileManager.default.removeItem(at: movpkgURL)
        
        AppLogger.shared.log(
          "Converted and deleted: \(movpkgURL.lastPathComponent) -> \(mp4URL.lastPathComponent)",
          level: .info
        )
        
        successCount += 1
      } catch {
        AppLogger.shared.log(
          "Failed to convert \(movpkgURL.lastPathComponent): \(error)",
          level: .error
        )
      }
    }
    
    AppLogger.shared.log(
      "Conversion complete: \(successCount)/\(movpkgFiles.count) files converted",
      level: .info
    )
    
    return successCount
  }
  
  /// Converts a specific .movpkg file to MP4
  /// - Parameters:
  ///   - movpkgURL: URL to the .movpkg file
  ///   - deleteOriginal: Whether to delete the original .movpkg after conversion
  ///   - progress: Progress callback
  /// - Returns: URL to the converted MP4 file
  static func convertHLSToMP4(
    movpkgURL: URL,
    deleteOriginal: Bool = true,
    progress: @escaping (Double) -> Void = { _ in }
  ) async throws -> URL {
    let mp4URL = try await HLSConverter.shared.convertToMP4(
      movpkgURL: movpkgURL,
      quality: .high,
      progress: progress
    )
    
    if deleteOriginal {
      try FileManager.default.removeItem(at: movpkgURL)
      AppLogger.shared.log("Deleted original .movpkg file", level: .info)
    }
    
    return mp4URL
  }
  
  /// Creates a test file to verify file sharing is working
  /// This helps debug if files are visible in the Files app
  /// - Returns: True if test file was created successfully
  @discardableResult
  static func createTestFile() -> Bool {
    guard let downloadsURL = getKenpachiDownloadsDirectory() else {
      AppLogger.shared.log("Failed to get downloads directory for test file", level: .error)
      return false
    }
    
    let testFileURL = downloadsURL.appendingPathComponent("TEST_FILE_SHARING.txt")
    
    let testContent = """
    Kenpachi File Sharing Test
    ==========================
    
    If you can see this file in the Files app, file sharing is working correctly!
    
    Location: On My iPhone > Kenpachi > Downloads
    
    This means:
    ✅ UIFileSharingEnabled is set correctly
    ✅ Files are being saved to the right location
    ✅ The Files app can access your downloads
    
    You can safely delete this test file.
    
    Created: \(Date())
    Path: \(testFileURL.path)
    """
    
    do {
      try testContent.write(to: testFileURL, atomically: true, encoding: .utf8)
      AppLogger.shared.log("Test file created at: \(testFileURL.path)", level: .info)
      AppLogger.shared.log("Check Files app: On My iPhone > Kenpachi > Downloads", level: .info)
      return true
    } catch {
      AppLogger.shared.log("Failed to create test file: \(error)", level: .error)
      return false
    }
  }
  
  /// Verifies file sharing setup by checking if test file is accessible
  /// - Returns: Diagnostic information about file sharing setup
  static func verifyFileSharing() -> String {
    var diagnostics = "File Sharing Diagnostics\n"
    diagnostics += "========================\n\n"
    
    // Check if we can get downloads directory
    if let downloadsURL = getKenpachiDownloadsDirectory() {
      diagnostics += "✅ Downloads directory accessible\n"
      diagnostics += "   Path: \(downloadsURL.path)\n\n"
      
      // Check if directory exists
      let fileManager = FileManager.default
      var isDirectory: ObjCBool = false
      if fileManager.fileExists(atPath: downloadsURL.path, isDirectory: &isDirectory) {
        diagnostics += "✅ Directory exists\n"
        diagnostics += "   Is directory: \(isDirectory.boolValue)\n\n"
      } else {
        diagnostics += "❌ Directory does not exist\n\n"
      }
      
      // List files in directory
      do {
        let files = try fileManager.contentsOfDirectory(atPath: downloadsURL.path)
        diagnostics += "📁 Files in directory: \(files.count)\n"
        if files.isEmpty {
          diagnostics += "   (No files yet)\n\n"
        } else {
          for file in files {
            diagnostics += "   - \(file)\n"
          }
          diagnostics += "\n"
        }
      } catch {
        diagnostics += "❌ Failed to list files: \(error)\n\n"
      }
      
      // Check if we can create a test file
      if createTestFile() {
        diagnostics += "✅ Test file created successfully\n"
        diagnostics += "   Check Files app: On My iPhone > Kenpachi > Downloads\n\n"
      } else {
        diagnostics += "❌ Failed to create test file\n\n"
      }
      
    } else {
      diagnostics += "❌ Cannot access downloads directory\n\n"
    }
    
    // Check Info.plist keys (this is informational)
    diagnostics += "⚠️  IMPORTANT: Verify Info.plist keys are set:\n"
    diagnostics += "   1. UIFileSharingEnabled = YES\n"
    diagnostics += "   2. LSSupportsOpeningDocumentsInPlace = YES\n\n"
    diagnostics += "   Without these keys, files won't appear in Files app!\n"
    
    return diagnostics
  }
  

}
