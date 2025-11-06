// PlayerView.swift
// YouTube style video player
// Clean, minimal design with smooth animations and modern controls

import AVKit
import Combine
import ComposableArchitecture
import SwiftUI

struct PlayerView: View {
  let store: StoreOf<PlayerFeature>

  @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
  @State private var player: AVPlayer?
  @State private var playerLayer: AVPlayerLayer?
  @State private var controlsTimer: Timer?
  @State private var cancellables = Set<AnyCancellable>()
  @State private var lastSeekTime: TimeInterval = 0
  @State private var shouldSeek = false
  @State private var isMinimized = false

  // Services
  @StateObject private var airPlayService = AirPlayService()
  @StateObject private var pipService = PictureInPictureService()

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        Color.black.ignoresSafeArea()

        /// Video player
        if let player = player {
          YouTubeStyleVideoPlayer(
            player: player,
            onPlayerLayerReady: { layer in
              playerLayer = layer
              setupPiP(with: layer, viewStore: viewStore)
            }
          )
          .ignoresSafeArea()
          .overlay(
            /// Transparent tap area to capture gestures
            Color.clear
              .contentShape(Rectangle())
              .onTapGesture {
                _ = withAnimation(.easeInOut(duration: 0.25)) {
                  viewStore.send(.toggleControls)
                }
                if viewStore.showControls {
                  resetControlsTimer(viewStore: viewStore)
                }
              }
          )
        } else if viewStore.isLoading {
          ProgressView()
            .tint(.white)
            .scaleEffect(1.5)
        }

        /// Buffering indicator
        if viewStore.isBuffering {
          ProgressView()
            .tint(.white)
            .scaleEffect(1.2)
        }

        /// Controls overlay
        if viewStore.showControls {
          YouTubeStylePlayerControls(
            store: store,
            airPlayService: airPlayService,
            pipService: pipService,
            onDismiss: { dismiss() },
            onSeek: { time in
              seekPlayer(to: time)
            }
          )
          .transition(.opacity)
        }

        /// Settings panel
        if viewStore.showSettings {
          YouTubeStyleSettingsPanel(store: store)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }

        /// Speed menu
        if viewStore.showSpeedMenu {
          YouTubeStyleSpeedMenu(store: store)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        /// Source selection menu
        if viewStore.showSourceMenu {
          YouTubeStyleSourceMenu(store: store)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        /// Subtitle selection menu
        if viewStore.showSubtitleMenu {
          YouTubeStyleSubtitleMenu(store: store)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        /// Error overlay
        if let error = viewStore.errorMessage {
          ErrorOverlay(message: error, onDismiss: { dismiss() })
        }
      }
      .statusBar(hidden: true)
      .persistentSystemOverlays(.hidden)
      .onAppear {
        setOrientation(.landscapeRight)
        viewStore.send(.onAppear)
        setupPlayer(viewStore: viewStore)
        setupServices(viewStore: viewStore)
        resetControlsTimer(viewStore: viewStore)

        // Setup app lifecycle notifications for PiP
        setupAppLifecycleObservers(viewStore: viewStore)
      }
      .onDisappear {
        setOrientation(.portrait)
        viewStore.send(.onDisappear)
        cleanupPlayer()
        cleanupServices()
      }
      .onChange(of: viewStore.selectedLink) { _, link in
        if let link = link { updatePlayerItem(with: link) }
      }
      .onChange(of: viewStore.isPlaying) { _, isPlaying in
        isPlaying ? player?.play() : player?.pause()
        isPlaying ? resetControlsTimer(viewStore: viewStore) : controlsTimer?.invalidate()
      }
      .onChange(of: viewStore.playbackSpeed) { _, speed in
        player?.rate = speed
      }
      .onChange(of: viewStore.volume) { _, volume in
        player?.volume = volume
      }
      .onChange(of: viewStore.isMuted) { _, isMuted in
        player?.isMuted = isMuted
      }
      .onChange(of: viewStore.selectedSubtitle) { _, subtitle in
        applySubtitle(subtitle)
      }
    }
  }

  /// Performs seek on the player
  /// - Parameter time: Target time in seconds
  private func seekPlayer(to time: TimeInterval) {
    guard let player = player else { return }
    let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
  }

  private func setupPlayer(viewStore: ViewStoreOf<PlayerFeature>) {
    guard let link = viewStore.selectedLink,
      let url = URL(string: link.url)
    else {
      viewStore.send(.errorOccurred("Invalid streaming URL"))
      return
    }

    // Configure audio session for AirPlay and PiP
    configureAudioSession()

    var asset = AVURLAsset(url: url)
    if link.requiresReferer, let headers = link.headers {
      asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
    }

    let playerItem = AVPlayerItem(asset: asset)
    let newPlayer = AVPlayer(playerItem: playerItem)
    newPlayer.allowsExternalPlayback = true
    newPlayer.usesExternalPlaybackWhileExternalScreenIsActive = true

    let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in

      let current = time.seconds
      var duration = playerItem.duration.seconds

      // Handle live streams or unknown duration
      if duration.isNaN || duration.isInfinite {
        duration = 0
      }

      // Only update if we have valid time values
      if !current.isNaN && !current.isInfinite && current >= 0 {
        viewStore.send(.timeUpdated(current: current, duration: max(duration, 0)))
      }
    }

    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: .main
    ) { _ in
      viewStore.send(.playbackStateChanged(false))
    }

    playerItem.publisher(for: \.status)
      .sink { status in
        switch status {
        case .readyToPlay:
          // Player is ready, update duration if available
          let duration = playerItem.duration.seconds
          if !duration.isNaN && !duration.isInfinite && duration > 0 {
            viewStore.send(.timeUpdated(current: 0, duration: duration))
          }
        case .failed:
          viewStore.send(.tryNextStream)
        case .unknown:
          break
        @unknown default:
          break
        }
      }
      .store(in: &cancellables)

    // Observe duration changes
    playerItem.publisher(for: \.duration)
      .sink { duration in
        let durationSeconds = duration.seconds
        if !durationSeconds.isNaN && !durationSeconds.isInfinite && durationSeconds > 0 {
          viewStore.send(
            .timeUpdated(current: newPlayer.currentTime().seconds, duration: durationSeconds))
        }
      }
      .store(in: &cancellables)

    self.player = newPlayer

    // Update AirPlay service with new player
    airPlayService.setPlayer(newPlayer)

    newPlayer.play()
    viewStore.send(.playbackStateChanged(true))
  }

  private func updatePlayerItem(with link: ExtractedLink) {
    guard let url = URL(string: link.url) else { return }

    var asset = AVURLAsset(url: url)
    if link.requiresReferer, let headers = link.headers {
      asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
    }

    let playerItem = AVPlayerItem(asset: asset)
    player?.replaceCurrentItem(with: playerItem)

    // Update AirPlay service with the new player item
    if let player = player {
      airPlayService.setPlayer(player)
    }

    player?.play()
  }

  private func cleanupPlayer() {
    player?.pause()
    player = nil
    playerLayer = nil
    controlsTimer?.invalidate()
    cancellables.removeAll()
  }

  private func setupServices(viewStore: ViewStoreOf<PlayerFeature>) {
    // Setup AirPlay service
    if let player = player {
      airPlayService.setPlayer(player)

      // Monitor AirPlay state changes
      airPlayService.$isAirPlayAvailable
        .receive(on: DispatchQueue.main)
        .sink { isAvailable in
          viewStore.send(.airPlayAvailabilityChanged(isAvailable))
        }
        .store(in: &cancellables)

      airPlayService.$isAirPlayActive
        .receive(on: DispatchQueue.main)
        .sink { isActive in
          viewStore.send(.castingStateChanged(isActive))
        }
        .store(in: &cancellables)

      airPlayService.$connectedDeviceName
        .receive(on: DispatchQueue.main)
        .sink { deviceName in
          viewStore.send(.airPlayDeviceChanged(deviceName))
        }
        .store(in: &cancellables)
    }

    // Setup PiP callbacks
    pipService.setCallbacks(
      onWillStart: {
        // Hide controls when PiP starts
        if viewStore.showControls {
          viewStore.send(.toggleControls)
        }
      },
      onDidStart: {
        // Update state
        viewStore.send(
          .pipStateChanged(
            isActive: true,
            isPossible: pipService.isPiPPossible,
            isSupported: pipService.isPiPSupported
          ))
      },
      onDidStop: {
        // Update state
        viewStore.send(
          .pipStateChanged(
            isActive: false,
            isPossible: pipService.isPiPPossible,
            isSupported: pipService.isPiPSupported
          ))
      },
      onRestoreUserInterface: {
        // Show controls when returning from PiP
        if !viewStore.showControls {
          viewStore.send(.toggleControls)
        }
      }
    )

    // Monitor PiP service state changes
    pipService.$isPiPSupported
      .combineLatest(pipService.$isPiPPossible, pipService.$isPiPActive)
      .receive(on: DispatchQueue.main)
      .sink { isSupported, isPossible, isActive in
        viewStore.send(
          .pipStateChanged(
            isActive: isActive,
            isPossible: isPossible,
            isSupported: isSupported
          ))
      }
      .store(in: &cancellables)
  }

  private func setupPiP(with layer: AVPlayerLayer, viewStore: ViewStoreOf<PlayerFeature>) {
    // Setup PiP with error handling
    do {
      pipService.setupPiP(with: layer)

      // Update initial PiP state
      viewStore.send(
        .pipStateChanged(
          isActive: pipService.isPiPActive,
          isPossible: pipService.isPiPPossible,
          isSupported: pipService.isPiPSupported
        ))
    } catch {
      print("Failed to setup Picture-in-Picture: \(error)")
      viewStore.send(
        .pipStateChanged(
          isActive: false,
          isPossible: false,
          isSupported: false
        ))
    }
  }

  private func cleanupServices() {
    airPlayService.cleanup()
    pipService.cleanup()
  }

  private func configureAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(
        .playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetoothA2DP])
      try audioSession.setActive(true)
    } catch {
      print("Failed to configure audio session: \(error)")
    }
  }

  private func applySubtitle(_ subtitle: Subtitle?) {
    guard let player = player,
      let currentItem = player.currentItem
    else { return }

    // Disable all current subtitle tracks using async loading
    let asset = currentItem.asset
    Task {
      if let characteristics = try? await asset.load(
        .availableMediaCharacteristicsWithMediaSelectionOptions)
      {
        for characteristic in characteristics {
          if let group = try? await asset.loadMediaSelectionGroup(for: characteristic) {
            if group.allowsEmptySelection {
              currentItem.select(nil, in: group)
            }
          }
        }
      }
    }

    // If subtitle is nil or "none", keep subtitles disabled
    guard let subtitle = subtitle,
      subtitle.id != "none",
      !subtitle.url.isEmpty
    else { return }

    // For now, we'll handle subtitle loading in a future implementation
    // This would involve loading external subtitle files and applying them
    print("Selected subtitle: \(subtitle.name) (\(subtitle.language))")
  }

  private func setupAppLifecycleObservers(viewStore: ViewStoreOf<PlayerFeature>) {
    // Observe app entering background for automatic PiP
    NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
      .receive(on: DispatchQueue.main)
      .sink { _ in
        // Automatically start PiP when app goes to background if possible
        if viewStore.isPiPSupported && viewStore.isPiPPossible && !viewStore.isPiPActive
          && viewStore.isPlaying
        {
          pipService.startPiP()
        }
      }
      .store(in: &cancellables)

    // Observe app becoming active
    NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
      .receive(on: DispatchQueue.main)
      .sink { _ in
        // Update states when app becomes active
        viewStore.send(
          .pipStateChanged(
            isActive: pipService.isPiPActive,
            isPossible: pipService.isPiPPossible,
            isSupported: pipService.isPiPSupported
          ))
      }
      .store(in: &cancellables)
  }

  private func resetControlsTimer(viewStore: ViewStoreOf<PlayerFeature>) {
    controlsTimer?.invalidate()
    guard viewStore.isPlaying else { return }

    controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
      if viewStore.isPlaying && viewStore.showControls {
        _ = withAnimation(.easeInOut(duration: 0.25)) {
          viewStore.send(.toggleControls)
        }
      }
    }
  }

  private func setOrientation(_ orientation: UIInterfaceOrientation) {
    if #available(iOS 16.0, *) {
      guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
      scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation.toMask))
    } else {
      UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    }
  }
}

extension UIInterfaceOrientation {
  var toMask: UIInterfaceOrientationMask {
    switch self {
    case .portrait: return .portrait
    case .landscapeLeft: return .landscapeLeft
    case .landscapeRight: return .landscapeRight
    default: return .all
    }
  }
}

// MARK: - YouTube Style Video Player
struct YouTubeStyleVideoPlayer: UIViewRepresentable {
  let player: AVPlayer
  let onPlayerLayerReady: (AVPlayerLayer) -> Void

  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.backgroundColor = .black

    let playerLayer = AVPlayerLayer(player: player)
    playerLayer.videoGravity = .resizeAspect
    playerLayer.frame = view.bounds

    view.layer.addSublayer(playerLayer)

    // Notify that player layer is ready
    DispatchQueue.main.async {
      onPlayerLayerReady(playerLayer)
    }

    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    if let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer {
      playerLayer.frame = uiView.bounds
    }
  }
}

// MARK: - YouTube Style Player Controls
struct YouTubeStylePlayerControls: View {
  let store: StoreOf<PlayerFeature>
  let airPlayService: AirPlayService
  let pipService: PictureInPictureService
  let onDismiss: () -> Void
  let onSeek: (TimeInterval) -> Void

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack(spacing: 0) {
        /// Top bar with dismiss button and title
        HStack {
          Button(action: onDismiss) {
            Image(systemName: "chevron.left")
              .font(.title2)
              .foregroundColor(.white)
              .frame(width: 44, height: 44)
          }

          Spacer()

          Text(viewStore.content.title)
            .font(.headline)
            .foregroundColor(.white)
            .lineLimit(1)
            .padding(.trailing, 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(
          LinearGradient(
            colors: [.black.opacity(0.8), .clear],
            startPoint: .top,
            endPoint: .bottom
          )
          .frame(height: 120)
        )

        Spacer()

        /// Center controls with YouTube-style play/pause button
        HStack(spacing: 60) {
          // Skip backward button
          Button {
            let newTime = max(viewStore.currentTime - 10, 0)
            viewStore.send(.skipBackward(10))
            onSeek(newTime)
          } label: {
            ZStack {
              Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 50, height: 50)

              Image(systemName: "gobackward.10")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            }
          }

          // Play/Pause button with YouTube-style design
          Button {
            viewStore.send(.playPauseTapped)
          } label: {
            ZStack {
              Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 70, height: 70)

              Image(systemName: viewStore.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.black)
                .offset(x: viewStore.isPlaying ? 0 : 2)  // Slight offset for play icon
            }
          }

          // Skip forward button
          Button {
            let newTime = min(viewStore.currentTime + 10, viewStore.duration)
            viewStore.send(.skipForward(10))
            onSeek(newTime)
          } label: {
            ZStack {
              Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 50, height: 50)

              Image(systemName: "goforward.10")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            }
          }
        }

        Spacer()

        /// Bottom bar with progress bar and controls
        VStack(spacing: 16) {
          /// Progress bar with time
          VStack(spacing: 8) {
            YouTubeStyleProgressBar(
              currentTime: viewStore.currentTime,
              duration: viewStore.duration,
              onSeek: { time in
                viewStore.send(.seekTo(time))
                onSeek(time)
              },
              onSeekingChanged: { viewStore.send(.seekingStateChanged($0)) }
            )

            HStack {
              Text(formatTime(viewStore.currentTime))
                .font(.caption)
                .foregroundColor(.white)
                .monospacedDigit()

              Spacer()

              Text(formatTime(viewStore.duration))
                .font(.caption)
                .foregroundColor(.white)
                .monospacedDigit()
            }
          }

          /// Bottom action buttons in YouTube style
          HStack(spacing: 25) {
            /// Episodes button
            if viewStore.episode != nil {
              Button {
                // Handle episodes
              } label: {
                VStack(spacing: 4) {
                  Image(systemName: "list.bullet")
                    .font(.title2)
                    .foregroundColor(.white)
                }
              }
            }

            /// Stream Selection (show when multiple streams available)
            if viewStore.streamingLinks.count > 1 {
              Button {
                viewStore.send(.toggleSourceMenu)
              } label: {
                VStack(spacing: 4) {
                  Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundColor(viewStore.showSourceMenu ? .red : .white)

                  if let selectedLink = viewStore.selectedLink {
                    Text(selectedLink.server)
                      .font(.caption2)
                      .foregroundColor(
                        viewStore.showSourceMenu ? .red.opacity(0.8) : .white.opacity(0.8)
                      )
                      .lineLimit(1)
                  }
                }
              }
            }

            /// Subtitles button
            if !viewStore.availableSubtitles.isEmpty {
              Button {
                viewStore.send(.toggleSubtitleMenu)
              } label: {
                VStack(spacing: 4) {
                  Image(systemName: "captions.bubble")
                    .font(.title2)
                    .foregroundColor(viewStore.showSubtitleMenu ? .red : .white)

                  if let selectedSubtitle = viewStore.selectedSubtitle,
                    selectedSubtitle.id != "none"
                  {
                    Text(selectedSubtitle.language.uppercased())
                      .font(.caption2)
                      .foregroundColor(
                        viewStore.showSubtitleMenu ? .red.opacity(0.8) : .white.opacity(0.8)
                      )
                      .lineLimit(1)
                  }
                }
              }
            }

            /// Speed button
            Button {
              viewStore.send(.toggleSpeedMenu)
            } label: {
              VStack(spacing: 4) {
                Image(systemName: "speedometer")
                  .font(.title2)
                  .foregroundColor(viewStore.showSpeedMenu ? .red : .white)

                Text("\(String(format: "%.1fx", viewStore.playbackSpeed))")
                  .font(.caption2)
                  .foregroundColor(
                    viewStore.showSpeedMenu ? .red.opacity(0.8) : .white.opacity(0.8))
              }
            }

            /// AirPlay button
            ModernAirPlayButton(isActive: viewStore.isCasting)
              .frame(width: 44, height: 44)

            /// Picture-in-Picture button
            if viewStore.isPiPSupported {
              Button {
                viewStore.send(.pipTapped)
                if viewStore.isPiPActive {
                  pipService.stopPiP()
                } else {
                  pipService.startPiP()
                }
              } label: {
                Image(systemName: viewStore.isPiPActive ? "pip.exit" : "pip.enter")
                  .font(.title2)
                  .foregroundColor(
                    viewStore.isPiPActive ? .red : (viewStore.isPiPPossible ? .white : .gray)
                  )
                  .frame(width: 44, height: 44)
              }
              .disabled(!viewStore.isPiPPossible)
            }

            /// Settings button
            Button {
              viewStore.send(.toggleSettings)
            } label: {
              Image(systemName: "gear")
                .font(.title2)
                .foregroundColor(viewStore.showSettings ? .red : .white)
                .frame(width: 44, height: 44)
            }
          }
          .padding(.horizontal)
        }
        .padding(.bottom, 20)
        .background(
          LinearGradient(
            colors: [.clear, .black.opacity(0.8)],
            startPoint: .top,
            endPoint: .bottom
          )
          .frame(height: 140)
        )
      }
    }
  }

  private func formatTime(_ time: TimeInterval) -> String {
    guard !time.isNaN && !time.isInfinite && time >= 0 else { return "0:00" }
    let hours = Int(time) / 3600
    let minutes = Int(time) / 60 % 60
    let seconds = Int(time) % 60
    return hours > 0
      ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
      : String(format: "%d:%02d", minutes, seconds)
  }
}

// MARK: - YouTube Style Progress Bar
struct YouTubeStyleProgressBar: View {
  let currentTime: TimeInterval
  let duration: TimeInterval
  let onSeek: (TimeInterval) -> Void
  let onSeekingChanged: (Bool) -> Void

  @State private var isDragging = false
  @State private var dragValue: Double = 0

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        /// Background track
        Capsule()
          .fill(Color.white.opacity(0.3))
          .frame(height: 3)

        /// Progress
        Capsule()
          .fill(Color.red)
          .frame(width: progressWidth(in: geometry.size.width), height: 3)

        /// Thumb
        Circle()
          .fill(Color.white)
          .frame(width: isDragging ? 20 : 12, height: isDragging ? 20 : 12)
          .offset(x: progressWidth(in: geometry.size.width) - (isDragging ? 10 : 6))
          .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
          .opacity(isDragging || currentTime > 0 ? 1 : 0)
      }
      .animation(.easeOut(duration: 0.2), value: isDragging)
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            if !isDragging {
              isDragging = true
              onSeekingChanged(true)
            }
            let progress = min(max(0, value.location.x / geometry.size.width), 1)
            dragValue = progress * duration
          }
          .onEnded { value in
            isDragging = false
            onSeekingChanged(false)
            let progress = min(max(0, value.location.x / geometry.size.width), 1)
            onSeek(progress * duration)
          }
      )
    }
    .frame(height: 30)
  }

  private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
    guard duration > 0 else { return 0 }
    let progress = isDragging ? dragValue / duration : currentTime / duration
    return totalWidth * CGFloat(progress)
  }
}

// MARK: - YouTube Style Settings Panel
struct YouTubeStyleSettingsPanel: View {
  let store: StoreOf<PlayerFeature>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      HStack {
        Spacer()

        VStack(spacing: 0) {
          /// Header
          HStack {
            Text("Settings")
              .font(.headline)
              .foregroundColor(.white)

            Spacer()

            Button {
              viewStore.send(.toggleSettings)
            } label: {
              Image(systemName: "xmark")
                .foregroundColor(.white)
            }
          }
          .padding()
          .background(Color.black.opacity(0.95))

          ScrollView {
            VStack(spacing: 0) {
              /// Playback Speed
              PlayerSettingsSection(title: "Playback Speed") {
                ForEach(viewStore.availablePlaybackSpeeds, id: \.self) { speed in
                  SettingsButton(
                    title: speed == 1.0 ? "Normal" : "\(String(format: "%.2fx", speed))",
                    isSelected: speed == viewStore.playbackSpeed
                  ) {
                    viewStore.send(.playbackSpeedChanged(speed))
                  }
                }
              }

              /// Quality
              if !viewStore.availableQualities.isEmpty {
                PlayerSettingsSection(title: "Quality") {
                  ForEach(viewStore.availableQualities, id: \.self) { quality in
                    SettingsButton(
                      title: quality,
                      isSelected: quality == viewStore.selectedQuality
                    ) {
                      viewStore.send(.qualitySelected(quality))
                    }
                  }
                }
              }

              /// Audio
              PlayerSettingsSection(title: "Audio") {
                SettingsButton(
                  title: viewStore.isMuted ? "Unmute" : "Mute",
                  isSelected: viewStore.isMuted
                ) {
                  viewStore.send(.muteToggled)
                }
              }
            }
          }
        }
        .frame(width: 280)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.95))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding()
      }
    }
  }
}

// MARK: - YouTube Style Speed Menu
struct YouTubeStyleSpeedMenu: View {
  let store: StoreOf<PlayerFeature>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        Spacer()

        VStack(spacing: 0) {
          /// Header
          HStack {
            Text("Speed")
              .font(.headline)
              .foregroundColor(.white)

            Spacer()

            Button {
              viewStore.send(.toggleSpeedMenu)
            } label: {
              Image(systemName: "xmark")
                .foregroundColor(.white)
            }
          }
          .padding()
          .background(Color.black.opacity(0.95))

          /// Speed options
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
            ForEach(viewStore.availablePlaybackSpeeds, id: \.self) { speed in
              Button {
                viewStore.send(.playbackSpeedChanged(speed))
                viewStore.send(.toggleSpeedMenu)
              } label: {
                VStack(spacing: 8) {
                  Text(speed == 1.0 ? "Normal" : "\(String(format: "%.2fx", speed))")
                    .font(.headline)
                    .foregroundColor(speed == viewStore.playbackSpeed ? .red : .white)

                  if speed == viewStore.playbackSpeed {
                    Circle()
                      .fill(Color.red)
                      .frame(width: 8, height: 8)
                  } else {
                    Circle()
                      .stroke(Color.white.opacity(0.3), lineWidth: 1)
                      .frame(width: 8, height: 8)
                  }
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(
                      speed == viewStore.playbackSpeed
                        ? Color.red.opacity(0.2) : Color.white.opacity(0.1))
                )
              }
            }
          }
          .padding()
        }
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.95))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
        )
        .padding()
      }
    }
  }
}

// MARK: - YouTube Style Source Menu
struct YouTubeStyleSourceMenu: View {
  let store: StoreOf<PlayerFeature>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        Spacer()

        VStack(spacing: 0) {
          /// Header
          HStack {
            Text("Sources")
              .font(.headline)
              .foregroundColor(.white)

            Spacer()

            Button {
              viewStore.send(.toggleSourceMenu)
            } label: {
              Image(systemName: "xmark")
                .foregroundColor(.white)
            }
          }
          .padding()
          .background(Color.black.opacity(0.95))

          /// Source options
          ScrollView {
            LazyVStack(spacing: 12) {
              ForEach(viewStore.streamingLinks, id: \.url) { link in
                Button {
                  viewStore.send(.linkSelected(link))
                  viewStore.send(.toggleSourceMenu)
                } label: {
                  HStack {
                    VStack(alignment: .leading, spacing: 4) {
                      Text(link.server)
                        .font(.headline)
                        .foregroundColor(.white)

                      Text(link.quality ?? "Auto Quality")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    if link.url == viewStore.selectedLink?.url {
                      Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                    } else {
                      Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 24, height: 24)
                    }
                  }
                  .padding()
                  .background(
                    RoundedRectangle(cornerRadius: 12)
                      .fill(
                        link.url == viewStore.selectedLink?.url
                          ? Color.red.opacity(0.2) : Color.white.opacity(0.1))
                  )
                }
              }
            }
            .padding()
          }
          .frame(maxHeight: 300)
        }
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.95))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
        )
        .padding()
      }
    }
  }
}

// MARK: - YouTube Style Subtitle Menu
struct YouTubeStyleSubtitleMenu: View {
  let store: StoreOf<PlayerFeature>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        Spacer()

        VStack(spacing: 0) {
          /// Header
          HStack {
            Text("Subtitles")
              .font(.headline)
              .foregroundColor(.white)

            Spacer()

            Button {
              viewStore.send(.toggleSubtitleMenu)
            } label: {
              Image(systemName: "xmark")
                .foregroundColor(.white)
            }
          }
          .padding()
          .background(Color.black.opacity(0.95))

          /// Subtitle options
          ScrollView {
            LazyVStack(spacing: 12) {
              // Add "None" option
              Button {
                viewStore.send(.subtitleSelected(Subtitle.none))
                viewStore.send(.toggleSubtitleMenu)
              } label: {
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("None")
                      .font(.headline)
                      .foregroundColor(.white)

                    Text("Turn off subtitles")
                      .font(.subheadline)
                      .foregroundColor(.white.opacity(0.7))
                  }

                  Spacer()

                  if viewStore.selectedSubtitle?.id == "none" || viewStore.selectedSubtitle == nil {
                    Image(systemName: "checkmark.circle.fill")
                      .foregroundColor(.red)
                      .font(.title2)
                  } else {
                    Circle()
                      .stroke(Color.white.opacity(0.3), lineWidth: 1)
                      .frame(width: 24, height: 24)
                  }
                }
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(
                      (viewStore.selectedSubtitle?.id == "none"
                        || viewStore.selectedSubtitle == nil)
                        ? Color.red.opacity(0.2) : Color.white.opacity(0.1))
                )
              }

              // Add available subtitles
              ForEach(viewStore.availableSubtitles, id: \.id) { subtitle in
                if !subtitle.isSpecialOption {
                  Button {
                    viewStore.send(.subtitleSelected(subtitle))
                    viewStore.send(.toggleSubtitleMenu)
                  } label: {
                    HStack {
                      VStack(alignment: .leading, spacing: 4) {
                        Text(subtitle.displayNameWithInfo)
                          .font(.headline)
                          .foregroundColor(.white)

                        Text(subtitle.language.uppercased())
                          .font(.subheadline)
                          .foregroundColor(.white.opacity(0.7))
                      }

                      Spacer()

                      if subtitle.id == viewStore.selectedSubtitle?.id {
                        Image(systemName: "checkmark.circle.fill")
                          .foregroundColor(.red)
                          .font(.title2)
                      } else {
                        Circle()
                          .stroke(Color.white.opacity(0.3), lineWidth: 1)
                          .frame(width: 24, height: 24)
                      }
                    }
                    .padding()
                    .background(
                      RoundedRectangle(cornerRadius: 12)
                        .fill(
                          subtitle.id == viewStore.selectedSubtitle?.id
                            ? Color.red.opacity(0.2) : Color.white.opacity(0.1))
                    )
                  }
                }
              }
            }
            .padding()
          }
          .frame(maxHeight: 300)
        }
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.95))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
        )
        .padding()
      }
    }
  }
}

struct PlayerSettingsSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .foregroundColor(.white.opacity(0.6))
        .padding(.horizontal)
        .padding(.top, 12)

      content
    }
  }
}

struct SettingsButton: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Text(title)
          .foregroundColor(.white)

        Spacer()

        if isSelected {
          Image(systemName: "checkmark")
            .foregroundColor(.red)
        }
      }
      .padding()
      .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
    }
  }
}

// MARK: - Modern AirPlay Button
struct ModernAirPlayButton: UIViewRepresentable {
  let isActive: Bool

  init(isActive: Bool = false) {
    self.isActive = isActive
  }

  func makeUIView(context: Context) -> AVRoutePickerView {
    let picker = AVRoutePickerView()
    picker.tintColor = isActive ? .systemRed : .white
    picker.activeTintColor = .systemRed
    picker.backgroundColor = .clear
    return picker
  }

  func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
    uiView.tintColor = isActive ? .systemRed : .white
  }
}

// MARK: - Error Overlay
struct ErrorOverlay: View {
  let message: String
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 50))
        .foregroundColor(.red)

      Text("Error")
        .font(.title2.bold())
        .foregroundColor(.white)

      Text(message)
        .font(.body)
        .foregroundColor(.white.opacity(0.8))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      Button(action: onDismiss) {
        Text("Close")
          .font(.headline)
          .foregroundColor(.white)
          .padding(.horizontal, 32)
          .padding(.vertical, 12)
          .background(Color.red)
          .cornerRadius(8)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.95))
  }
}
