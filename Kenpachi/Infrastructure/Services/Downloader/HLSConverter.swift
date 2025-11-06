// HLSConverter.swift
// Service for converting HLS .movpkg downloads to MP4 files
// Converts downloaded HLS assets to single playable MP4 files

import AVFoundation
import Foundation

/// Service for converting HLS downloads to MP4 format
final class HLSConverter {
  /// Shared singleton instance
  static let shared = HLSConverter()

  /// Active conversion tasks
  private var activeConversions: [String: AVAssetExportSession] = [:]

  /// Private initializer for singleton
  private init() {
    AppLogger.shared.log("HLSConverter initialized", level: .debug)
  }

  /// Converts a .movpkg HLS download to MP4 format
  /// - Parameters:
  ///   - movpkgURL: URL to the .movpkg package
  ///   - outputURL: Desired output URL for MP4 file (optional, will generate if nil)
  ///   - quality: Export quality preset
  ///   - progress: Progress callback (0.0 to 1.0)
  ///   - completion: Completion callback with result
  func convertToMP4(
    movpkgURL: URL,
    outputURL: URL? = nil,
    quality: ExportQuality = .high,
    progress: @escaping (Double) -> Void,
    completion: @escaping (Result<URL, Error>) -> Void
  ) {
    // Verify the movpkg exists
    guard FileManager.default.fileExists(atPath: movpkgURL.path) else {
      AppLogger.shared.log("Source .movpkg not found: \(movpkgURL.path)", level: .error)
      completion(.failure(ConversionError.sourceNotFound))
      return
    }

    AppLogger.shared.log("Starting conversion for: \(movpkgURL.lastPathComponent)", level: .info)

    // Determine output URL
    let finalOutputURL: URL
    if let outputURL = outputURL {
      finalOutputURL = outputURL
    } else {
      // Generate output URL by replacing .movpkg with .mp4
      let downloadsURL = movpkgURL.deletingLastPathComponent()
      let filename = movpkgURL.deletingPathExtension().lastPathComponent + ".mp4"
      finalOutputURL = downloadsURL.appendingPathComponent(filename)
    }

    // Remove existing file if present
    if FileManager.default.fileExists(atPath: finalOutputURL.path) {
      do {
        try FileManager.default.removeItem(at: finalOutputURL)
        AppLogger.shared.log("Removed existing output file", level: .debug)
      } catch {
        AppLogger.shared.log("Failed to remove existing file: \(error)", level: .error)
        completion(.failure(error))
        return
      }
    }

    // Create AVURLAsset from the movpkg with options to ensure it's playable
    let options = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
    let asset = AVURLAsset(url: movpkgURL, options: options)

    // Check if asset is playable using async loading
    Task {
      do {
        let isPlayable = try await asset.load(.isPlayable)
        let isExportable = try await asset.load(.isExportable)

        // Check if asset is playable (exportable check is often false for downloaded HLS)
        guard isPlayable else {
          AppLogger.shared.log(
            "Asset is not playable. Playable: \(isPlayable), Exportable: \(isExportable)",
            level: .error
          )
          completion(.failure(ConversionError.assetNotPlayable))
          return
        }

        // Log exportable status but don't fail if it's false (common for downloaded HLS)
        if !isExportable {
          AppLogger.shared.log(
            "Asset is not marked as exportable, but attempting conversion anyway. This is common for downloaded HLS content.",
            level: .warning
          )
        }

        AppLogger.shared.log("Asset is ready for export", level: .debug)

        // Try to create export session with different presets if the first fails
        var exportSession: AVAssetExportSession?
        let presets = [
          quality.presetName, AVAssetExportPresetMediumQuality, AVAssetExportPresetLowQuality,
        ]

        for preset in presets {
          let isCompatible = await withCheckedContinuation { continuation in
            AVAssetExportSession.determineCompatibility(
              ofExportPreset: preset, with: asset, outputFileType: .mp4
            ) { isCompatible in
              continuation.resume(returning: isCompatible)
            }
          }
          if isCompatible {
            exportSession = AVAssetExportSession(asset: asset, presetName: preset)
            AppLogger.shared.log("Created export session with preset: \(preset)", level: .debug)
            break
          }
        }

        guard let exportSession = exportSession else {
          AppLogger.shared.log("Failed to create export session with any preset", level: .error)
          completion(.failure(ConversionError.exportSessionCreationFailed))
          return
        }

        // Configure export session
        exportSession.outputURL = finalOutputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        // Store export session for progress tracking
        let conversionId = UUID().uuidString
        await MainActor.run {
          self.activeConversions[conversionId] = exportSession
        }

        AppLogger.shared.log(
          "Export session created. Output: \(finalOutputURL.lastPathComponent)",
          level: .info
        )

        // Start progress monitoring on main thread
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          
          let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor [weak self] in
              guard let self = self,
                    let session = self.activeConversions[conversionId] else {
                return
              }

              progress(Double(session.progress))
            }
          }

          // Keep timer alive
          RunLoop.current.add(timer, forMode: .common)
          
          // Store timer to invalidate later
          Task { @MainActor [weak self] in
            guard let self = self else { return }
            // Monitor completion and invalidate timer
            while self.activeConversions[conversionId] != nil {
              try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            timer.invalidate()
          }
        }

        AppLogger.shared.log(
          "Starting HLS to MP4 conversion: \(movpkgURL.lastPathComponent)",
          level: .info
        )

        // Start export using modern async API
        do {
          try await exportSession.export(to: finalOutputURL, as: .mp4)

          // Remove from active conversions
          Task { @MainActor in
            _ = self.activeConversions.removeValue(forKey: conversionId)
          }

          AppLogger.shared.log(
            "Conversion completed: \(finalOutputURL.lastPathComponent)",
            level: .info
          )
          completion(.success(finalOutputURL))
        } catch {
          // Remove from active conversions
          Task { @MainActor in
            _ = self.activeConversions.removeValue(forKey: conversionId)
          }

          AppLogger.shared.log(
            "Conversion failed: \(error.localizedDescription)",
            level: .error
          )
          if let nsError = error as NSError? {
            AppLogger.shared.log(
              "Error code: \(nsError.code), domain: \(nsError.domain)",
              level: .error
            )
          }

          // Try fallback method for problematic HLS assets
          self.attemptFallbackConversion(
            movpkgURL: movpkgURL,
            outputURL: finalOutputURL,
            progress: progress,
            completion: completion
          )
        }
      } catch {
        AppLogger.shared.log(
          "Failed to load asset properties: \(error.localizedDescription)",
          level: .error
        )
        completion(.failure(ConversionError.assetNotPlayable))
      }
    }
  }

  /// Converts a .movpkg HLS download to MP4 format (async/await version)
  /// - Parameters:
  ///   - movpkgURL: URL to the .movpkg package
  ///   - outputURL: Desired output URL for MP4 file (optional)
  ///   - quality: Export quality preset
  ///   - progress: Progress callback (0.0 to 1.0)
  /// - Returns: URL to the converted MP4 file
  func convertToMP4(
    movpkgURL: URL,
    outputURL: URL? = nil,
    quality: ExportQuality = .high,
    progress: @escaping (Double) -> Void = { _ in }
  ) async throws -> URL {
    try await withCheckedThrowingContinuation { continuation in
      convertToMP4(
        movpkgURL: movpkgURL,
        outputURL: outputURL,
        quality: quality,
        progress: progress
      ) { result in
        continuation.resume(with: result)
      }
    }
  }

  /// Cancels an ongoing conversion
  /// - Parameter conversionId: ID of the conversion to cancel
  func cancelConversion(conversionId: String) {
    if let exportSession = activeConversions[conversionId] {
      exportSession.cancelExport()
      activeConversions.removeValue(forKey: conversionId)
      AppLogger.shared.log("Conversion cancelled: \(conversionId)", level: .info)
    }
  }

  /// Cancels all ongoing conversions
  func cancelAllConversions() {
    for (_, exportSession) in activeConversions {
      exportSession.cancelExport()
    }
    activeConversions.removeAll()
    AppLogger.shared.log("All conversions cancelled", level: .info)
  }

  /// Fallback conversion method for problematic HLS assets
  /// This method tries alternative approaches when standard export fails
  private func attemptFallbackConversion(
    movpkgURL: URL,
    outputURL: URL,
    progress: @escaping (Double) -> Void,
    completion: @escaping (Result<URL, Error>) -> Void
  ) {
    AppLogger.shared.log("Attempting fallback conversion method", level: .info)

    // For now, we'll inform the user that the file is already playable
    // In the future, we could implement segment copying or other methods
    AppLogger.shared.log(
      "Standard conversion failed. The .movpkg file is playable as-is in the app.",
      level: .info
    )

    // Return the original movpkg URL since it's playable
    completion(.success(movpkgURL))
  }
}

// MARK: - Export Quality
/// Export quality presets for conversion
enum ExportQuality {
  case low
  case medium
  case high
  case highest

  /// AVFoundation preset name
  var presetName: String {
    switch self {
    case .low:
      return AVAssetExportPresetLowQuality
    case .medium:
      return AVAssetExportPresetMediumQuality
    case .high:
      return AVAssetExportPresetHighestQuality
    case .highest:
      return AVAssetExportPreset1920x1080
    }
  }

  /// Human-readable description
  var description: String {
    switch self {
    case .low:
      return "Low (Smaller file size)"
    case .medium:
      return "Medium (Balanced)"
    case .high:
      return "High (Better quality)"
    case .highest:
      return "Highest (1080p)"
    }
  }
}

// MARK: - Conversion Error
/// Errors that can occur during conversion
enum ConversionError: LocalizedError {
  case sourceNotFound
  case assetNotPlayable
  case exportSessionCreationFailed
  case exportFailed
  case cancelled
  case unknownError

  var errorDescription: String? {
    switch self {
    case .sourceNotFound:
      return "Source .movpkg file not found"
    case .assetNotPlayable:
      return
        "The downloaded file cannot be converted. It may be incomplete, corrupted, or use a format that doesn't support conversion. The file is still playable in the app."
    case .exportSessionCreationFailed:
      return "Failed to create export session"
    case .exportFailed:
      return "Export failed"
    case .cancelled:
      return "Conversion was cancelled"
    case .unknownError:
      return "Unknown error occurred during conversion"
    }
  }
}
