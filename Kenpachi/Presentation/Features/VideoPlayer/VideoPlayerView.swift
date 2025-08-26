import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let content: Content
    @SwiftUI.Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var showControls = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isBuffering = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        setupPlayer()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                // Loading state
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                    
                    Text("Loading \(content.title)...")
                        .foregroundColor(.white)
                        .padding(.top, 20)
                }
            }
            
            // Custom Controls Overlay
            if showControls {
                VStack {
                    // Top Controls
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
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
                    
                    // Bottom Controls
                    VStack(spacing: 16) {
                        // Progress Bar
                        VideoProgressBar(
                            currentTime: $currentTime,
                            duration: $duration,
                            onSeek: { time in
                                player?.seek(to: CMTime(seconds: time, preferredTimescale: 1))
                            }
                        )
                        
                        // Playback Controls
                        HStack(spacing: 30) {
                            Button(action: {
                                seekBackward()
                            }) {
                                Image(systemName: "gobackward.10")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: {
                                togglePlayPause()
                            }) {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: {
                                seekForward()
                            }) {
                                Image(systemName: "goforward.10")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Additional Controls
                        HStack {
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "textformat")
                                    Text("Subtitles")
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "speaker.wave.2")
                                    Text("Audio")
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
            
            // Buffering Indicator
            if isBuffering {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Buffering...")
                        .foregroundColor(.white)
                        .padding(.top, 8)
                }
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
                .padding()
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls.toggle()
            }
        }
        .onAppear {
            setupPlayer()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }
    
    private func setupPlayer() {
        // In a real app, you would get the video URL from your content service
        // For demo purposes, we'll use a sample video URL
        guard let url = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") else {
            return
        }
        
        player = AVPlayer(url: url)
        
        // Add observers for player state
        if let player = player {
            // Time observer
            let timeInterval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { time in
                currentTime = time.seconds
            }
            
            // Duration observer
            player.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    if let duration = player.currentItem?.duration {
                        self.duration = duration.seconds
                    }
                }
            }
            
            // Playback state observer
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                self.isPlaying = false
            }
        }
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if player.rate == 0 {
            player.play()
            isPlaying = true
        } else {
            player.pause()
            isPlaying = false
        }
    }
    
    private func seekForward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        player.seek(to: newTime)
    }
    
    private func seekBackward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        player.seek(to: newTime)
    }
}

struct VideoProgressBar: View {
    @Binding var currentTime: Double
    @Binding var duration: Double
    let onSeek: (Double) -> Void
    
    @State private var isDragging = false
    @State private var dragValue: Double = 0
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return isDragging ? dragValue : currentTime / duration
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    // Progress
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 4)
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .offset(x: geometry.size.width * progress - 6)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            dragValue = min(max(0, value.location.x / geometry.size.width), 1)
                        }
                        .onEnded { value in
                            isDragging = false
                            let seekTime = dragValue * duration
                            onSeek(seekTime)
                        }
                )
            }
            .frame(height: 12)
            
            // Time Labels
            HStack {
                Text(formatTime(isDragging ? dragValue * duration : currentTime))
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        guard !time.isNaN && !time.isInfinite else { return "0:00" }
        
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    VideoPlayerView(content: MockData.sampleMovies.first!)
}