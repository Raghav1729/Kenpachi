// PlayerView.swift
// Disney Plus style video player
// Landscape-only with fullscreen controls, PiP, AirPlay, subtitles, and advanced gestures

import AVKit
import Combine
import ComposableArchitecture
import SwiftUI
import UIKit

struct PlayerView: View {
  let store: StoreOf<PlayerFeature>

  @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
  @State private var player: AVPlayer?
  @State private var playerLayer: AVPlayerLayer?
  @State private var controlsTimer: Timer?
  @State private var cancellables = Set<AnyCancellable>()
  
  // Services
  @StateObject private var airPlayService = AirPlayService()
  @StateObject private var pipService = PictureInPictureService()
  
  // Gesture states
  @State private var currentScale: CGFloat = 1.0
  @State private var lastScale: CGFloat = 1.0

  var body: some View {
    WithViewStore(store, observe: \.self) { viewStore in
      ZStack {
        Color.black.ignoresSafeArea()

        // Video player
        if let player = player {
          DisneyPlusVideoPlayer(
            player: player,
            scale: currentScale,
            onPlayerLayerReady: { layer in
              playerLayer = layer
              setupPiP(with: layer, viewStore: viewStore)
            }
          )
          .ignoresSafeArea()
          .highPriorityGesture(
            // Double tap left to skip backward
            TapGesture(count: 2)
              .onEnded { _ in
                let newTime = max(viewStore.currentTime - 10, 0)
                viewStore.send(.skipBackward(10))
                seekPlayer(to: newTime)
              },
            including: .subviews
          )
          .gesture(
            // Pinch to zoom
            MagnificationGesture()
              .onChanged { value in
                currentScale = min(max(lastScale * value, 1.0), 3.0)
              }
              .onEnded { _ in
                lastScale = currentScale
              }
          )
        } else if viewStore.isLoading {
          ProgressView()
            .tint(.white)
            .scaleEffect(1.5)
        }

        // Buffering indicator
        if viewStore.isBuffering {
          ProgressView()
            .tint(.white)
            .scaleEffect(1.2)
        }
        
        

        // Controls overlay
        if viewStore.showControls {
          DisneyPlusPlayerControls(
            store: store,
            airPlayService: airPlayService,
            pipService: pipService,
            onDismiss: { dismiss() },
            onSeek: { time in seekPlayer(to: time) }
          )
          .transition(.opacity)
        }

        // Settings panel
        if viewStore.showSettings {
          DisneyPlusSettingsPanel(store: store)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }

        // Speed menu
        if viewStore.showSpeedMenu {
          DisneyPlusSpeedMenu(store: store)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        // Source selection menu
        if viewStore.showSourceMenu {
          DisneyPlusSourceMenu(store: store)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        // Subtitle selection menu
        if viewStore.showSubtitleMenu {
          DisneyPlusSubtitleMenu(store: store)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        // Error overlay
        if let error = viewStore.errorMessage {
          ErrorOverlay(message: error, onDismiss: { dismiss() })
        }
      }
      // Make taps anywhere on the player surface show controls and reset timer
      .contentShape(Rectangle())
      .simultaneousGesture(
        TapGesture()
          .onEnded {
            if !viewStore.showControls {
              _ = withAnimation(.easeInOut(duration: 0.25)) {
                viewStore.send(.toggleControls)
              }
            }
            resetControlsTimer(viewStore: viewStore)
          }
      )
      .statusBar(hidden: true)
      .persistentSystemOverlays(.hidden)
      .onAppear {
        enforceLandscape()
        viewStore.send(.onAppear)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          setupPlayer(viewStore: viewStore)
          setupServices(viewStore: viewStore)
          resetControlsTimer(viewStore: viewStore)
          setupAppLifecycleObservers(viewStore: viewStore)
        }
      }
      .onDisappear {
        enforcePortrait()
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
        if isPlaying { enforceLandscape() }
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
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
        let orientation = UIDevice.current.orientation
        if orientation.isPortrait {
          enforceLandscape()
        }
      }
    }
  }
  
  // MARK: - Gesture Handlers

  // MARK: - Player Setup
  
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

      if duration.isNaN || duration.isInfinite {
        duration = 0
      }

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
    if let player = player {
      airPlayService.setPlayer(player)

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

    pipService.setCallbacks(
      onWillStart: {
        if viewStore.showControls {
          viewStore.send(.toggleControls)
        }
      },
      onDidStart: {
        viewStore.send(
          .pipStateChanged(
            isActive: true,
            isPossible: pipService.isPiPPossible,
            isSupported: pipService.isPiPSupported
          ))
      },
      onDidStop: {
        viewStore.send(
          .pipStateChanged(
            isActive: false,
            isPossible: pipService.isPiPPossible,
            isSupported: pipService.isPiPSupported
          ))
      },
      onRestoreUserInterface: {
        if !viewStore.showControls {
          viewStore.send(.toggleControls)
        }
      }
    )

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
    do {
      pipService.setupPiP(with: layer)
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

    guard let subtitle = subtitle,
      subtitle.id != "none",
      !subtitle.url.isEmpty
    else { return }

    print("Selected subtitle: \(subtitle.name) (\(subtitle.language))")
  }

  private func setupAppLifecycleObservers(viewStore: ViewStoreOf<PlayerFeature>) {
    NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
      .receive(on: DispatchQueue.main)
      .sink { _ in
        if viewStore.isPiPSupported && viewStore.isPiPPossible && !viewStore.isPiPActive
          && viewStore.isPlaying
        {
          pipService.startPiP()
        }
      }
      .store(in: &cancellables)

    NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
      .receive(on: DispatchQueue.main)
      .sink { _ in
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

    controlsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
      // Don't hide controls if any menu is open
      let hasOpenMenu = viewStore.showSettings || viewStore.showSpeedMenu || 
                        viewStore.showSourceMenu || viewStore.showSubtitleMenu
      
      if viewStore.isPlaying && viewStore.showControls && !hasOpenMenu {
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

  private func setOrientationMask(_ mask: UIInterfaceOrientationMask) {
    if #available(iOS 16.0, *) {
      guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
      scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
    } else {
      // Best-effort fallback for < iOS 16: set a representative orientation
      if mask.contains(.landscape) {
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
      } else if mask.contains(.portrait) {
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
      }
    }
  }

  private func enforceLandscape() {
    DispatchQueue.main.async {
      setOrientationMask(.landscape)
      setOrientation(.landscapeRight)
    }
    // Reassert shortly after to ensure rotation when coming from strict portrait
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      setOrientationMask(.landscape)
      setOrientation(.landscapeRight)
    }
  }

  private func enforcePortrait() {
    DispatchQueue.main.async {
      setOrientationMask(.portrait)
      setOrientation(.portrait)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      setOrientationMask(.portrait)
      setOrientation(.portrait)
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

// MARK: - Disney Plus Video Player
struct DisneyPlusVideoPlayer: UIViewRepresentable {
  let player: AVPlayer
  let scale: CGFloat
  let onPlayerLayerReady: (AVPlayerLayer) -> Void

  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.backgroundColor = .black

    let playerLayer = AVPlayerLayer(player: player)
    playerLayer.videoGravity = .resizeAspect
    playerLayer.frame = view.bounds

    view.layer.addSublayer(playerLayer)

    DispatchQueue.main.async {
      onPlayerLayerReady(playerLayer)
    }

    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    if let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer {
      playerLayer.frame = uiView.bounds
      
      // Apply zoom transform
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      playerLayer.transform = CATransform3DMakeScale(scale, scale, 1)
      CATransaction.commit()
    }
  }
}

// MARK: - Brightness Indicator

// MARK: - Disney Plus Player Controls
struct DisneyPlusPlayerControls: View {
  let store: StoreOf<PlayerFeature>
  let airPlayService: AirPlayService
  let pipService: PictureInPictureService
  let onDismiss: () -> Void
  let onSeek: (TimeInterval) -> Void

  var body: some View {
    WithViewStore(self.store, observe: \.self) { viewStore in
      VStack(spacing: 0) {
        // Top bar
        HStack(spacing: 16) {
          Button(action: onDismiss) {
            HStack(spacing: 8) {
              Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
              Text("common.back")
                .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
              Capsule()
                .fill(Color.white.opacity(0.2))
            )
          }

          Spacer()

          VStack(alignment: .trailing, spacing: 2) {
            Text(viewStore.content.title)
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(.white)
              .lineLimit(1)
            
            if let episode = viewStore.episode {
              Text("S\(String(format: "%02d", episode.seasonNumber))E\(String(format: "%02d", episode.episodeNumber)) - \(episode.name)")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(
          LinearGradient(
            colors: [.black.opacity(0.7), .clear],
            startPoint: .top,
            endPoint: .bottom
          )
          .frame(height: 100)
        )

        Spacer()

        // Center controls
        HStack(spacing: 50) {
          // Skip backward 10 seconds
          Button {
            let newTime = max(viewStore.currentTime - 10, 0)
            viewStore.send(.skipBackward(10))
            onSeek(newTime)
          } label: {
            VStack(spacing: 8) {
              ZStack {
                Circle()
                  .fill(Color.white.opacity(0.15))
                  .frame(width: 60, height: 60)
                
                Image(systemName: "gobackward.10")
                  .font(.system(size: 24, weight: .medium))
                  .foregroundColor(.white)
              }
            }
          }

          // Play/Pause
          Button {
            viewStore.send(.playPauseTapped)
          } label: {
            ZStack {
              Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 80, height: 80)

              Image(systemName: viewStore.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .offset(x: viewStore.isPlaying ? 0 : 3)
            }
          }

          // Skip forward 30 seconds
          Button {
            let newTime = min(viewStore.currentTime + 30, viewStore.duration)
            viewStore.send(.skipForward(30))
            onSeek(newTime)
          } label: {
            VStack(spacing: 8) {
              ZStack {
                Circle()
                  .fill(Color.white.opacity(0.15))
                  .frame(width: 60, height: 60)
                
                Image(systemName: "goforward.30")
                  .font(.system(size: 24, weight: .medium))
                  .foregroundColor(.white)
              }
            }
          }
        }

        Spacer()

        // Bottom bar
        VStack(spacing: 12) {
          // Progress bar
          VStack(spacing: 8) {
            DisneyPlusProgressBar(
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
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .monospacedDigit()

              Spacer()

              Text(formatTime(viewStore.duration))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .monospacedDigit()
            }
          }

          // Control buttons
          HStack(spacing: 20) {
            // Source selection
            if viewStore.streamingLinks.count > 1 {
              ControlButton(
                icon: "antenna.radiowaves.left.and.right",
                label: viewStore.selectedLink?.server ?? "Source",
                isActive: viewStore.showSourceMenu
              ) {
                viewStore.send(.toggleSourceMenu)
              }
            }

            // Subtitles
            if !viewStore.availableSubtitles.isEmpty {
              ControlButton(
                icon: "captions.bubble",
                label: viewStore.selectedSubtitle?.language.uppercased() ?? "CC",
                isActive: viewStore.showSubtitleMenu || (viewStore.selectedSubtitle?.id != "none")
              ) {
                viewStore.send(.toggleSubtitleMenu)
              }
            }

            // Speed
            ControlButton(
              icon: "speedometer",
              label: String(format: "%.1fx", viewStore.playbackSpeed),
              isActive: viewStore.showSpeedMenu
            ) {
              viewStore.send(.toggleSpeedMenu)
            }

            // AirPlay
            ZStack {
              ModernAirPlayButton(isActive: viewStore.isCasting)
                .frame(width: 40, height: 40)
            }

            // Picture-in-Picture
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
                  .font(.system(size: 20))
                  .foregroundColor(
                    viewStore.isPiPActive ? .blue : (viewStore.isPiPPossible ? .white : .gray)
                  )
                  .frame(width: 40, height: 40)
              }
              .disabled(!viewStore.isPiPPossible)
            }

            // Settings
            ControlButton(
              icon: "gearshape.fill",
              label: nil,
              isActive: viewStore.showSettings
            ) {
              viewStore.send(.toggleSettings)
            }
          }
          .padding(.horizontal, 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(
          LinearGradient(
            colors: [.clear, .black.opacity(0.7)],
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

// MARK: - Control Button
struct ControlButton: View {
  let icon: String
  let label: String?
  let isActive: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundColor(isActive ? .blue : .white)
          .frame(width: 40, height: 40)
        
        if let label = label {
          Text(label)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(isActive ? .blue : .white.opacity(0.8))
            .lineLimit(1)
        }
      }
    }
  }
}

// MARK: - Disney Plus Progress Bar
struct DisneyPlusProgressBar: View {
  let currentTime: TimeInterval
  let duration: TimeInterval
  let onSeek: (TimeInterval) -> Void
  let onSeekingChanged: (Bool) -> Void

  @State private var isDragging = false
  @State private var dragValue: Double = 0

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        // Background track
        Capsule()
          .fill(Color.white.opacity(0.3))
          .frame(height: isDragging ? 6 : 4)

        // Progress
        Capsule()
          .fill(Color.blue)
          .frame(width: progressWidth(in: geometry.size.width), height: isDragging ? 6 : 4)

        // Thumb
        Circle()
          .fill(Color.white)
          .frame(width: isDragging ? 18 : 0, height: isDragging ? 18 : 0)
          .offset(x: progressWidth(in: geometry.size.width) - (isDragging ? 9 : 0))
          .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
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

// MARK: - Disney Plus Settings Panel
struct DisneyPlusSettingsPanel: View {
  let store: StoreOf<PlayerFeature>

  var body: some View {
    WithViewStore(self.store, observe: { (state: PlayerFeature.State) in state }) { viewStore in
      HStack {
        Spacer()

        VStack(spacing: 0) {
          // Header
          HStack {
            Text("settings.title")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.white)

            Spacer()

            Button {
              viewStore.send(.toggleSettings)
            } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.6))
            }
          }
          .padding()
          .background(Color(white: 0.15))

          ScrollView {
            VStack(spacing: 0) {
              // Playback Speed
              PlayerSettingsSection(title: "settings.player.playback_speed") {
                ForEach(viewStore.availablePlaybackSpeeds, id: \.self) { speed in
                  PlayerSettingsRow(
                    title: speed == 1.0 ? "player.speed.normal" : "\(String(format: "%.2fx", speed))",
                    isSelected: speed == viewStore.playbackSpeed
                  ) {
                    viewStore.send(.playbackSpeedChanged(speed))
                  }
                }
              }

              // Quality
              if !viewStore.availableQualities.isEmpty {
                PlayerSettingsSection(title: "settings.player.default_quality") {
                  ForEach(viewStore.availableQualities, id: \.self) { quality in
                    PlayerSettingsRow(
                      title: quality,
                      isSelected: quality == viewStore.selectedQuality
                    ) {
                      viewStore.send(.qualitySelected(quality))
                    }
                  }
                }
              }

              // Audio
              PlayerSettingsSection(title: "Audio") {
                PlayerSettingsRow(
                  title: viewStore.isMuted ? "Unmute" : "Mute",
                  isSelected: viewStore.isMuted
                ) {
                  viewStore.send(.muteToggled)
                }
              }
            }
          }
        }
        .frame(width: 300)
        .background(Color(white: 0.1))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        .padding()
      }
    }
  }
}

// MARK: - Player Settings Section
struct PlayerSettingsSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(title)
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(.white.opacity(0.6))
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)

      content
      
      Divider()
        .background(Color.white.opacity(0.1))
        .padding(.top, 8)
    }
  }
}

// MARK: - Player Settings Row
struct PlayerSettingsRow: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Text(title)
          .font(.system(size: 15))
          .foregroundColor(.white)

        Spacer()

        if isSelected {
          Image(systemName: "checkmark")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.blue)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
    }
  }
}

// MARK: - Disney Plus Speed Menu
struct DisneyPlusSpeedMenu: View {
  let store: StoreOf<PlayerFeature>

  var body: some View {
    WithViewStore(self.store, observe: { (state: PlayerFeature.State) in state }) { viewStore in
      VStack {
        Spacer()

        VStack(spacing: 0) {
          // Header
          HStack {
            Text("player.menu.playback_speed.title")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.white)

            Spacer()

            Button {
              viewStore.send(.toggleSpeedMenu)
            } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.6))
            }
          }
          .padding()
          .background(Color(white: 0.15))

          // Speed options
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
            ForEach(viewStore.availablePlaybackSpeeds, id: \.self) { speed in
              Button {
                viewStore.send(.playbackSpeedChanged(speed))
                viewStore.send(.toggleSpeedMenu)
              } label: {
                VStack(spacing: 8) {
                  Text(speed == 1.0 ? "player.speed.normal" : "\(String(format: "%.2fx", speed))")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(speed == viewStore.playbackSpeed ? .blue : .white)

                  if speed == viewStore.playbackSpeed {
                    Circle()
                      .fill(Color.blue)
                      .frame(width: 6, height: 6)
                  } else {
                    Circle()
                      .stroke(Color.white.opacity(0.3), lineWidth: 1)
                      .frame(width: 6, height: 6)
                  }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  RoundedRectangle(cornerRadius: 8)
                    .fill(
                      speed == viewStore.playbackSpeed
                        ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                )
              }
            }
          }
          .padding()
        }
        .background(Color(white: 0.1))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: -10)
        .padding()
      }
    }
  }
}

// MARK: - Disney Plus Source Menu
struct DisneyPlusSourceMenu: View {
  let store: StoreOf<PlayerFeature>

  var body: some View {
    WithViewStore(self.store, observe: { (state: PlayerFeature.State) in state }) { viewStore in
      VStack {
        Spacer()

        VStack(spacing: 0) {
          // Header
          HStack {
            Text("player.menu.source.title")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.white)

            Spacer()

            Button {
              viewStore.send(.toggleSourceMenu)
            } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.6))
            }
          }
          .padding()
          .background(Color(white: 0.15))

          // Source options
          ScrollView {
            LazyVStack(spacing: 10) {
              ForEach(viewStore.streamingLinks, id: \.url) { link in
                Button {
                  viewStore.send(.linkSelected(link))
                  viewStore.send(.toggleSourceMenu)
                } label: {
                  HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                      Text(link.server)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                      Text(link.quality ?? "Auto Quality")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    if link.url == viewStore.selectedLink?.url {
                      Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                    } else {
                      Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    }
                  }
                  .padding(16)
                  .background(
                    RoundedRectangle(cornerRadius: 8)
                      .fill(
                        link.url == viewStore.selectedLink?.url
                          ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                  )
                }
              }
            }
            .padding()
          }
          .frame(maxHeight: 300)
        }
        .background(Color(white: 0.1))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: -10)
        .padding()
      }
    }
  }
}

// MARK: - Disney Plus Subtitle Menu
struct DisneyPlusSubtitleMenu: View {
  let store: StoreOf<PlayerFeature>

  var body: some View {
    WithViewStore(self.store, observe: { (state: PlayerFeature.State) in state }) { viewStore in
      VStack {
        Spacer()

        VStack(spacing: 0) {
          // Header
          HStack {
            Text("player.menu.subtitles.title")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.white)

            Spacer()

            Button {
              viewStore.send(.toggleSubtitleMenu)
            } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.6))
            }
          }
          .padding()
          .background(Color(white: 0.15))

          // Subtitle options
          ScrollView {
            LazyVStack(spacing: 10) {
              // None option
              Button {
                viewStore.send(.subtitleSelected(Subtitle.none))
                viewStore.send(.toggleSubtitleMenu)
              } label: {
                HStack(spacing: 12) {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("player.subtitles.off")
                      .font(.system(size: 16, weight: .semibold))
                      .foregroundColor(.white)

                    Text("player.subtitles.none_description")
                      .font(.system(size: 13))
                      .foregroundColor(.white.opacity(0.6))
                  }

                  Spacer()

                  if viewStore.selectedSubtitle?.id == "none" || viewStore.selectedSubtitle == nil {
                    Image(systemName: "checkmark.circle.fill")
                      .font(.system(size: 22))
                      .foregroundColor(.blue)
                  } else {
                    Circle()
                      .stroke(Color.white.opacity(0.3), lineWidth: 2)
                      .frame(width: 22, height: 22)
                  }
                }
                .padding(16)
                .background(
                  RoundedRectangle(cornerRadius: 8)
                    .fill(
                      (viewStore.selectedSubtitle?.id == "none" || viewStore.selectedSubtitle == nil)
                        ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                )
              }

              // Available subtitles
              ForEach(viewStore.availableSubtitles, id: \.id) { subtitle in
                if !subtitle.isSpecialOption {
                  Button {
                    viewStore.send(.subtitleSelected(subtitle))
                    viewStore.send(.toggleSubtitleMenu)
                  } label: {
                    HStack(spacing: 12) {
                      VStack(alignment: .leading, spacing: 4) {
                        Text(subtitle.displayNameWithInfo)
                          .font(.system(size: 16, weight: .semibold))
                          .foregroundColor(.white)

                        Text(subtitle.language.uppercased())
                          .font(.system(size: 13))
                          .foregroundColor(.white.opacity(0.6))
                      }

                      Spacer()

                      if subtitle.id == viewStore.selectedSubtitle?.id {
                        Image(systemName: "checkmark.circle.fill")
                          .font(.system(size: 22))
                          .foregroundColor(.blue)
                      } else {
                        Circle()
                          .stroke(Color.white.opacity(0.3), lineWidth: 2)
                          .frame(width: 22, height: 22)
                      }
                    }
                    .padding(16)
                    .background(
                      RoundedRectangle(cornerRadius: 8)
                        .fill(
                          subtitle.id == viewStore.selectedSubtitle?.id
                            ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                    )
                  }
                }
              }
            }
            .padding()
          }
          .frame(maxHeight: 300)
        }
        .background(Color(white: 0.1))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: -10)
        .padding()
      }
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
    picker.tintColor = isActive ? .systemBlue : .white
    picker.activeTintColor = .systemBlue
    picker.backgroundColor = .clear
    return picker
  }

  func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
    uiView.tintColor = isActive ? .systemBlue : .white
  }
}

// MARK: - Error Overlay
struct ErrorOverlay: View {
  let message: String
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 60))
        .foregroundColor(.blue)

      Text("player.error.playback")
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(.white)

      Text(message)
        .font(.system(size: 16))
        .foregroundColor(.white.opacity(0.8))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      Button(action: onDismiss) {
        Text("common.back")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.white)
          .padding(.horizontal, 40)
          .padding(.vertical, 14)
          .background(
            Capsule()
              .fill(Color.blue)
          )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.95))
  }
}
