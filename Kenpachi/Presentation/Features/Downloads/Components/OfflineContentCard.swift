// OfflineContentCard.swift
// Card component for displaying individual offline content items
// Shows poster, title, metadata, and action buttons

import SwiftUI

/// Card view for displaying offline content
struct OfflineContentCard: View {
  /// Download to display
  let download: Download
  /// Current conversion progress (if converting)
  let conversionProgress: Double?
  /// Callback when card is tapped
  let onTap: () -> Void
  /// Callback when delete is tapped
  let onDelete: () -> Void
  /// Callback when convert is tapped
  let onConvert: () -> Void
  
  /// Show context menu
  @State private var showMenu = false
  
  /// Check if this is an HLS package
  private var isHLSPackage: Bool {
    guard let localFilePath = download.localFilePath else { return false }
    return FileManager.isHLSPackage(at: localFilePath)
  }
  
  /// Get file size for display
  private var fileSize: String {
    guard let filePath = download.localFilePath else { return "Unknown" }
    if let size = FileManager.getFileSize(at: filePath) {
      return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    return "Unknown"
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Poster section
      posterSection
      
      // Info section
      infoSection
    }
    .background(Color.cardBackground)
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
  }  

  /// Poster section with overlay
  private var posterSection: some View {
    Button(action: onTap) {
      ZStack {
        // Poster image
        posterImage
        
        // Conversion overlay
        if let progress = conversionProgress {
          conversionOverlay(progress: progress)
        }
        
        // File type badge
        VStack {
          HStack {
            Spacer()
            if isHLSPackage {
              fileTypeBadge
            }
          }
          Spacer()
        }
        .padding(8)
        
        // Play button overlay
        playButtonOverlay
      }
    }
    .buttonStyle(PlainButtonStyle())
    .aspectRatio(2/3, contentMode: .fit)
    .contextMenu {
      contextMenuItems
    }
  }
  
  /// Poster image view
  private var posterImage: some View {
    Group {
      if let posterURL = download.content.fullPosterURL {
        AsyncImage(url: posterURL) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          case .failure, .empty:
            placeholderImage
          @unknown default:
            placeholderImage
          }
        }
      } else {
        placeholderImage
      }
    }
    .clipped()
  }
  
  /// Placeholder image for missing posters
  private var placeholderImage: some View {
    ZStack {
      Color.gray.opacity(0.3)
      
      VStack(spacing: 8) {
        Image(systemName: download.content.type == .movie ? "film.fill" : "tv.fill")
          .font(.system(size: 32))
          .foregroundColor(.gray)
        
        Text(download.content.title)
          .font(.caption)
          .foregroundColor(.gray)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .padding(.horizontal, 8)
      }
    }
  }  

  /// Conversion progress overlay
  private func conversionOverlay(progress: Double) -> some View {
    ZStack {
      Color.black.opacity(0.7)
      
      VStack(spacing: 8) {
        ProgressView(value: progress)
          .progressViewStyle(CircularProgressViewStyle(tint: .orange))
          .scaleEffect(1.5)
        
        Text("Converting")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.white)
        
        Text("\(Int(progress * 100))%")
          .font(.caption2)
          .foregroundColor(.white.opacity(0.8))
      }
    }
  }
  
  /// File type badge
  private var fileTypeBadge: some View {
    Text("HLS")
      .font(.caption2)
      .fontWeight(.bold)
      .foregroundColor(.white)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(Color.orange)
      .cornerRadius(4)
  }
  
  /// Play button overlay
  private var playButtonOverlay: some View {
    ZStack {
      Color.black.opacity(0.3)
      
      Image(systemName: "play.circle.fill")
        .font(.system(size: 40))
        .foregroundColor(.white)
        .opacity(0.9)
    }
    .opacity(0) // Hidden by default, shows on hover/press
  }
  
  /// Info section with title and metadata
  private var infoSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      // Title
      Text(download.content.title)
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundColor(.textPrimary)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
      
      // Episode info (if applicable)
      if let episode = download.episode {
        Text(episode.formattedEpisodeId)
          .font(.caption)
          .foregroundColor(.textSecondary)
      }
      
      // Metadata row
      HStack {
        // Quality
        if let quality = download.quality {
          Text(quality.displayName)
            .font(.caption2)
            .foregroundColor(.textSecondary)
        }
        
        Spacer()
        
        // File size
        Text(fileSize)
          .font(.caption2)
          .foregroundColor(.textSecondary)
      }
      
      // Download date
      Text("Downloaded \(formatDate(download.completedAt))")
        .font(.caption2)
        .foregroundColor(.textTertiary)
    }
    .padding(12)
  }
  
  /// Context menu items
  private var contextMenuItems: some View {
    Group {
      Button(action: onTap) {
        Label("Play", systemImage: "play.fill")
      }
      
      if isHLSPackage {
        Button(action: onConvert) {
          Label("Convert to MP4", systemImage: "arrow.triangle.2.circlepath")
        }
      }
      
      Button(action: {}) {
        Label("Share", systemImage: "square.and.arrow.up")
      }
      
      Divider()
      
      Button(role: .destructive, action: onDelete) {
        Label("Delete", systemImage: "trash")
      }
    }
  }
  
  /// Format date for display
  private func formatDate(_ date: Date?) -> String {
    guard let date = date else { return "Unknown" }
    
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    return formatter.localizedString(for: date, relativeTo: Date())
  }
}

// MARK: - Preview
#Preview {
  let sampleDownload = Download(
    content: Content(
      id: "1",
      type: .movie,
      title: "Sample Movie",
      overview: "A sample movie for preview",
      voteAverage: 8.5,
      genres: [],
      cast: []
    ),
    state: .completed,
    quality: .hd1080,
    completedAt: Date()
  )
  
  OfflineContentCard(
    download: sampleDownload,
    conversionProgress: nil,
    onTap: {},
    onDelete: {},
    onConvert: {}
  )
  .frame(width: 160)
  .padding()
}