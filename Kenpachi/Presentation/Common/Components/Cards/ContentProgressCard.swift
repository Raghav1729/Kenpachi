// ContentProgressCard.swift
// Landscape content card with progress indicator
// Designed for continue watching and watch history features

import SwiftUI

/// A landscape card component for displaying watch history with progress
/// Features 16:9 aspect ratio with progress bar at the bottom
struct ContentProgressCard: View {
  /// The watch history entry to display
  let entry: WatchHistoryEntry
  /// Callback when card is tapped
  let onTapped: () -> Void
  /// Card width (defaults to 280 for landscape)
  var width: CGFloat = 280
  /// Whether to show title below the card
  var showTitle: Bool = true
  /// Optional remove button callback
  var onRemove: (() -> Void)?
  
  /// Computed height based on 16:9 aspect ratio
  private var height: CGFloat {
    width * 9 / 16
  }
  
  /// Formatted time remaining
  private var timeRemaining: String {
    let remaining = entry.duration - entry.currentTime
    let minutes = Int(remaining) / 60
    if minutes < 60 {
      return "\(minutes)m left"
    } else {
      let hours = minutes / 60
      let remainingMinutes = minutes % 60
      return "\(hours)h \(remainingMinutes)m left"
    }
  }
  
  var body: some View {
    Button(action: onTapped) {
      VStack(alignment: .leading, spacing: 8) {
        ZStack(alignment: .bottom) {
          /// Backdrop image with rounded corners
          if let fullPosterURL = entry.fullPosterURL {
            CachedAsyncImage(url: fullPosterURL) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()
                .cornerRadius(.radiusM)
            } placeholder: {
              /// Loading placeholder
              Rectangle()
                .fill(Color.cardBackground)
                .frame(width: width, height: height)
                .cornerRadius(.radiusM)
                .overlay(
                  ProgressView()
                    .tint(.textTertiary)
                )
            }
          } else {
            /// Fallback when no content data
            Rectangle()
              .fill(Color.cardBackground)
              .frame(width: width, height: height)
              .cornerRadius(.radiusM)
              .overlay(
                VStack(spacing: 8) {
                  Image(systemName: "film")
                    .font(.title)
                    .foregroundColor(.textTertiary)
                  Text(entry.contentId)
                    .font(.captionMedium)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                }
              )
          }
          
          /// Remove button overlay (top-right)
          if let onRemove = onRemove {
            Button(action: onRemove) {
              Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundColor(.white)
                .background(
                  Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 28, height: 28)
                )
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
          }
          
          /// Progress bar at the bottom
          if entry.progress > 0 {
            GeometryReader { geometry in
              HStack(spacing: 0) {
                /// Watched portion
                Rectangle()
                  .fill(Color.primary)
                  .frame(width: geometry.size.width * CGFloat(entry.progress))
                
                /// Unwatched portion
                Rectangle()
                  .fill(Color.white.opacity(0.3))
              }
            }
            .frame(height: 4)
            .cornerRadius(.radiusS / 2, corners: [.bottomLeft, .bottomRight])
          }
        }
        .frame(width: width, height: height)
        
        /// Title and info below card
        if showTitle {
          VStack(alignment: .leading, spacing: 4) {
            /// Content title
            Text(entry.contentId) // Will be updated when content is fetched
              .font(.labelMedium)
              .foregroundColor(.textPrimary)
              .lineLimit(1)
            
            /// Episode info and progress
            HStack(spacing: 8) {
              if let episodeId = entry.episodeId {
                Text(episodeId)
                  .font(.captionMedium)
                  .foregroundColor(.textSecondary)
              }
              
              Text(entry.formattedProgress)
                .font(.captionMedium)
                .foregroundColor(.textSecondary)
              
              if entry.duration > 0 {
                Text("• \(timeRemaining)")
                  .font(.captionMedium)
                  .foregroundColor(.textSecondary)
              }
            }
            .lineLimit(1)
          }
          .frame(width: width, alignment: .leading)
        }
      }
      .frame(alignment: .top)
    }
    .buttonStyle(ContentCardButtonStyle())
  }
}

/// Extension to support corner radius on specific corners
extension View {
  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

/// Custom shape for rounded corners on specific corners
struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners
  
  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

/// Preview provider for ContentProgressCard
#Preview("With Content") {
  ContentProgressCard(
    entry: WatchHistoryEntry(
      contentId: "movie-123",
      episodeId: nil,
      scraperSource: "FlixHQ",
      fullPosterURL: URL(string: "https://image.tmdb.org/t/p/w500/example.jpg"),
      progress: 0.65,
      currentTime: 3900,
      duration: 6000
    ),
    onTapped: {}
  )
  .padding()
  .background(Color.appBackground)
}

#Preview("With Episode") {
  ContentProgressCard(
    entry: WatchHistoryEntry(
      contentId: "show-456",
      episodeId: "S01E05",
      scraperSource: "FlixHQ",
      fullPosterURL: URL(string: "https://image.tmdb.org/t/p/w500/example.jpg"),
      progress: 0.45,
      currentTime: 1080,
      duration: 2400
    ),
    onTapped: {},
    onRemove: {}
  )
  .padding()
  .background(Color.appBackground)
}

#Preview("Without Content Data") {
  ContentProgressCard(
    entry: WatchHistoryEntry(
      contentId: "unknown-content",
      scraperSource: "FlixHQ",
      progress: 0.30,
      currentTime: 1800,
      duration: 6000
    ),
    onTapped: {}
  )
  .padding()
  .background(Color.appBackground)
}

#Preview("Multiple Cards") {
  ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 16) {
      ContentProgressCard(
        entry: WatchHistoryEntry(
          contentId: "movie-1",
          scraperSource: "FlixHQ",
          fullPosterURL: URL(string: "https://image.tmdb.org/t/p/w500/example1.jpg"),
          progress: 0.25,
          currentTime: 1500,
          duration: 6000
        ),
        onTapped: {},
        onRemove: {}
      )
      
      ContentProgressCard(
        entry: WatchHistoryEntry(
          contentId: "show-2",
          episodeId: "S01E02",
          scraperSource: "FlixHQ",
          fullPosterURL: URL(string: "https://image.tmdb.org/t/p/w500/example2.jpg"),
          progress: 0.75,
          currentTime: 1800,
          duration: 2400
        ),
        onTapped: {},
        onRemove: {}
      )
      
      ContentProgressCard(
        entry: WatchHistoryEntry(
          contentId: "movie-3",
          scraperSource: "FlixHQ",
          fullPosterURL: URL(string: "https://image.tmdb.org/t/p/w500/example3.jpg"),
          progress: 0.45,
          currentTime: 2700,
          duration: 6000
        ),
        onTapped: {}
      )
    }
    .padding()
  }
  .background(Color.appBackground)
}