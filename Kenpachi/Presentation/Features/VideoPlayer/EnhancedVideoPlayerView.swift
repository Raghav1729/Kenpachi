import SwiftUI
import AVKit
import Combine

struct EnhancedVideoPlayerView: View {
    let content: Content
    @SwiftUI.Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject private var viewModel: VideoPlayerViewModel
    
    init(content: Content) {
        self.content = content
        self._viewModel = StateObject(wrappedValue: VideoPlayerViewModel(content: content))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                LoadingPlayerView(content: content)
            } else if let error = viewModel.error {
                ErrorPlayerView(error: error) {
                    viewModel.retryLoading()
                }
            } else if let player = viewModel.player {
                VideoPlayerContainer(
                    player: player,
                    content: content,
                    viewModel: viewModel
                )
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
        .onAppear {
            viewModel.loadVideoSources()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

struct VideoPlayerContainer: View {
    let player: AVPlayer
    let content: Content
    @ObservedObject var viewModel: VideoPlayerViewModel
    @SwiftUI.Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    
    var body: some View {
        ZStack {
            // Video Player
            VideoPlayer(player: player)
                .onTapGesture {
                    toggleControls()
                }
            
            // Custom Controls Overlay
            if showControls {
                VideoControlsOverlay(
                    content: content,
                    viewModel: viewModel,
                    onDismiss: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                .transition(.opacity)
            }
            
            // Quality Selector
            if viewModel.showQualitySelector {
                QualitySelectorView(
                    sources: viewModel.videoSources,
                    selectedSource: viewModel.selectedVideoSource,
                    onSourceSelected: { source in
                        viewModel.changeVideoSource(source)
                    },
                    onDismiss: {
                        viewModel.showQualitySelector = false
                    }
                )
            }
            
            // Subtitle Selector
            if viewModel.showSubtitleSelector {
                SubtitleSelectorView(
                    subtitles: viewModel.availableSubtitles,
                    selectedSubtitle: viewModel.selectedSubtitle,
                    onSubtitleSelected: { subtitle in
                        viewModel.selectSubtitle(subtitle)
                    },
                    onDismiss: {
                        viewModel.showSubtitleSelector = false
                    }
                )
            }
            
            // Buffering Indicator
            if viewModel.isBuffering {
                BufferingIndicator()
            }
        }
        .onReceive(viewModel.$isPlaying) { isPlaying in
            if isPlaying {
                hideControlsAfterDelay()
            } else {
                showControls = true
                cancelControlsTimer()
            }
        }
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        
        if showControls {
            hideControlsAfterDelay()
        }
    }
    
    private func hideControlsAfterDelay() {
        cancelControlsTimer()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    
    private func cancelControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = nil
    }
}

struct VideoControlsOverlay: View {
    let content: Content
    @ObservedObject var viewModel: VideoPlayerViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            // Top Controls
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
                    Text(content.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if !content.genres.isEmpty {
                        Text(content.genres.map { $0.name }.joined(separator: " • "))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.7), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            Spacer()
            
            // Center Play/Pause Button
            Button(action: {
                viewModel.togglePlayPause()
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
                    .padding(20)
            }
            
            Spacer()
            
            // Bottom Controls
            VStack(spacing: 16) {
                // Progress Bar
                VideoProgressSlider(
                    currentTime: $viewModel.currentTime,
                    duration: $viewModel.duration,
                    onSeek: { time in
                        viewModel.seek(to: time)
                    }
                )
                
                // Control Buttons
                HStack(spacing: 30) {
                    Button(action: {
                        viewModel.seekBackward()
                    }) {
                        Image(systemName: "gobackward.10")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        viewModel.togglePlayPause()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        viewModel.seekForward()
                    }) {
                        Image(systemName: "goforward.10")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                
                // Additional Controls
                HStack {
                    Button(action: {
                        viewModel.showSubtitleSelector = true
                    }) {
                        HStack {
                            Image(systemName: "textformat")
                            Text("Subtitles")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.showQualitySelector = true
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text(viewModel.selectedVideoSource?.quality.displayName ?? "Auto")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "airplayvideo")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

struct LoadingPlayerView: View {
    let content: Content
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2)
            
            Text("Loading \(content.title)...")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Preparing video sources...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct ErrorPlayerView: View {
    let error: StreamingError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Playback Error")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
    }
}

struct BufferingIndicator: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Buffering...")
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(20)
        .background(Color.black.opacity(0.7))
        .cornerRadius(10)
    }
}

#Preview {
    EnhancedVideoPlayerView(content: MockData.sampleMovies.first!)
}