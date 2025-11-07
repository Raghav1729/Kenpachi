// OfflinePlayerView.swift
// Simple offline video player for downloaded content
// Provides basic playback controls for local files

import SwiftUI
import AVKit

/// Offline video player view
struct OfflinePlayerView: View {
  /// Download to play
  let download: Download
  /// Callback when player is dismissed
  let onDismiss: () -> Void
  
  /// AVPlayer instance
  @State private var player: AVPlayer?
  /// Show player controls
  @State private var showControls = true
  /// Player error
  @State private var playerError: String?
  
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      
      if let player = player {
        // Use AVPlayerViewController wrapper for better HLS support
        AVPlayerViewControllerWrapper(player: player)
          .ignoresSafeArea()
          .onTapGesture {
            showControls.toggle()
          }
      } else if let error = playerError {
        errorView(error)
      } else {
        loadingView
      }
      
      // Back button overlay (always visible)
      VStack {
        HStack {
          Button(action: onDismiss) {
            HStack(spacing: 8) {
              Image(systemName: "chevron.left")
                .font(.title3)
              Text("common.back")
                .font(.headline)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.6))
            .cornerRadius(20)
          }
          .padding()
          
          Spacer()
        }
        Spacer()
      }
    }
    .onAppear {
      setupPlayer()
    }
    .onDisappear {
      player?.pause()
      player = nil
    }
    .statusBarHidden(false)
    .navigationBarHidden(true)
  }
  
  /// Top controls
  private var topControls: some View {
    HStack {
      Button(action: onDismiss) {
        Image(systemName: "xmark")
          .font(.title2)
          .foregroundColor(.white)
          .padding()
          .background(Color.black.opacity(0.5))
          .clipShape(Circle())
      }
      
      Spacer()
      
      VStack(alignment: .trailing) {
        Text(download.content.title)
          .font(.headline)
          .foregroundColor(.white)
        
        if let episode = download.episode {
          Text(episode.formattedEpisodeId)
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.8))
        }
      }
    }
    .padding()
    .background(
      LinearGradient(
        colors: [.black.opacity(0.6), .clear],
        startPoint: .top,
        endPoint: .bottom
      )
    )
  }
  
  /// Bottom controls
  private var bottomControls: some View {
    VStack {
      // File info
      HStack {
        if let quality = download.quality {
          Text(quality.displayName)
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
        }
        
        Spacer()
        
        if let filePath = download.localFilePath,
           let fileSize = FileManager.getFileSize(at: filePath) {
          Text(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
        }
      }
      .padding(.horizontal)
    }
    .padding()
    .background(
      LinearGradient(
        colors: [.clear, .black.opacity(0.6)],
        startPoint: .top,
        endPoint: .bottom
      )
    )
  }
  
  /// Loading view
  private var loadingView: some View {
    VStack(spacing: 20) {
      ProgressView()
        .scaleEffect(1.5)
        .tint(.white)
      
      Text("player.loading")
        .font(.headline)
        .foregroundColor(.white)
    }
  }
  
  /// Error view
  private func errorView(_ error: String) -> some View {
    VStack(spacing: 20) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 50))
        .foregroundColor(.red)
      
      Text("player.error.playback")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.white)
      
      Text(error)
        .font(.body)
        .foregroundColor(.white.opacity(0.8))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
      
      Button("common.dismiss") {
        onDismiss()
      }
      .foregroundColor(.white)
      .padding(.horizontal, 20)
      .padding(.vertical, 10)
      .background(Color.blue)
      .cornerRadius(8)
    }
  }
  
  /// Setup AVPlayer
  private func setupPlayer() {
    guard let filePath = download.localFilePath else {
      playerError = "File path not found"
      return
    }
    
    guard FileManager.default.fileExists(atPath: filePath.path) else {
      playerError = "Downloaded file not found at: \(filePath.path)"
      return
    }
    
    // Create AVPlayer with the file URL
    let asset = AVURLAsset(url: filePath)
    let playerItem = AVPlayerItem(asset: asset)
    player = AVPlayer(playerItem: playerItem)
    
    // Configure audio session for playback
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      AppLogger.shared.log("Failed to configure audio session: \(error)", level: .warning)
    }
    
    // Log file info for debugging
    AppLogger.shared.log("Playing file: \(filePath.lastPathComponent)", level: .info)
    AppLogger.shared.log("File path: \(filePath.path)", level: .debug)
    
    if FileManager.isHLSPackage(at: filePath) {
      AppLogger.shared.log("Playing HLS package (.movpkg)", level: .info)
    } else {
      AppLogger.shared.log("Playing regular video file", level: .info)
    }
  }
}

#Preview {
  let sampleDownload = Download(
    content: Content(
      id: "1",
      type: .movie,
      title: "Sample Movie",
      overview: "A sample movie",
      voteAverage: 8.5,
      genres: [],
      cast: []
    ),
    state: .completed,
    quality: .hd1080,
    localFilePath: URL(string: "file://sample.mp4")
  )
  
  OfflinePlayerView(
    download: sampleDownload,
    onDismiss: {}
  )
}

// MARK: - AVPlayerViewController Wrapper
/// UIViewControllerRepresentable wrapper for AVPlayerViewController
/// Provides better HLS playback support than SwiftUI's VideoPlayer
struct AVPlayerViewControllerWrapper: UIViewControllerRepresentable {
  let player: AVPlayer
  
  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let controller = AVPlayerViewController()
    controller.player = player
    controller.showsPlaybackControls = true
    controller.allowsPictureInPicturePlayback = true
    controller.entersFullScreenWhenPlaybackBegins = false
    controller.exitsFullScreenWhenPlaybackEnds = false
    
    // Start playback
    player.play()
    
    return controller
  }
  
  func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    // Update if needed
  }
}