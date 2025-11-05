// OfflineContentView.swift
// Component for displaying offline/downloaded content
// Provides a clean interface for browsing downloaded files

import SwiftUI

/// View for displaying offline downloaded content
struct OfflineContentView: View {
  /// List of downloaded content
  let downloads: [Download]
  /// Callback when content is tapped
  let onContentTapped: (Download) -> Void
  /// Callback when content is deleted
  let onContentDeleted: (Download) -> Void
  /// Callback when content is converted
  let onContentConverted: (Download) -> Void
  /// Current conversion progress for downloads
  let conversionProgress: [String: Double]
  
  /// Grid layout for content
  private let columns = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12)
  ]
  
  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 16) {
        ForEach(completedDownloads) { download in
          OfflineContentCard(
            download: download,
            conversionProgress: conversionProgress[download.id],
            onTap: { onContentTapped(download) },
            onDelete: { onContentDeleted(download) },
            onConvert: { onContentConverted(download) }
          )
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 8)
    }
  }
  
  /// Filter to show only completed downloads
  private var completedDownloads: [Download] {
    downloads.filter { $0.state == .completed }
  }
}