// PlayerFeature.swift
// YouTube style video player feature
// Manages playback with clean, minimal controls

import AVFoundation
import ComposableArchitecture
import Foundation

@Reducer
struct PlayerFeature {

  @ObservableState
  struct State: Equatable {
    /// Content being played
    let content: Content
    /// Selected season (for TV shows)
    let season: Season?
    /// Selected episode (for TV shows)
    let episode: Episode?
    /// Available streaming links
    var streamingLinks: [ExtractedLink] = []
    /// Currently selected link
    var selectedLink: ExtractedLink?
    /// Loading state
    var isLoading = false
    /// Error message
    var errorMessage: String?
    /// Player controls visibility
    var showControls = true
    /// Settings panel visibility
    var showSettings = false
    /// Speed menu visibility
    var showSpeedMenu = false
    /// Source selection menu visibility
    var showSourceMenu = false
    /// Playback state
    var isPlaying = false
    /// Current playback time
    var currentTime: TimeInterval = 0
    /// Total duration
    var duration: TimeInterval = 0
    /// Playback speed
    var playbackSpeed: Float = 1.0
    /// Available playback speeds
    var availablePlaybackSpeeds: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    /// Volume level
    var volume: Float = 1.0
    /// Is muted
    var isMuted = false
    /// Available qualities
    var availableQualities: [String] = []
    /// Selected quality
    var selectedQuality: String?
    /// Is seeking
    var isSeeking = false
    /// Buffering state
    var isBuffering = false
    /// AirPlay availability
    var isAirPlayAvailable = false
    /// Is casting via AirPlay
    var isCasting = false
    /// Connected AirPlay device name
    var connectedDeviceName: String?
    /// Picture-in-Picture availability
    var isPiPSupported = false
    /// Picture-in-Picture active state
    var isPiPActive = false
    /// Picture-in-Picture possible state
    var isPiPPossible = false
    /// Available subtitles
    var availableSubtitles: [Subtitle] = []
    /// Selected subtitle
    var selectedSubtitle: Subtitle?
    /// Show subtitle menu
    var showSubtitleMenu = false

    init(content: Content, season: Season?, episode: Episode?, streamingLinks: [ExtractedLink]) {
      self.content = content
      self.season = season
      self.episode = episode
      self.streamingLinks = streamingLinks
      self.selectedLink = streamingLinks.first
      self.availableQualities = Array(Set(streamingLinks.compactMap { $0.quality })).sorted()
      self.selectedQuality = streamingLinks.first?.quality

      // Initialize PiP as supported by default (will be updated by the service)
      self.isPiPSupported = true

      // Add sample subtitles for testing
      self.availableSubtitles = [
        Subtitle(id: "none", name: "None", language: "none", url: ""),
        Subtitle(id: "en", name: "English", language: "en", url: ""),
        Subtitle(id: "es", name: "Spanish", language: "es", url: ""),
        Subtitle(id: "fr", name: "French", language: "fr", url: ""),
      ]
      self.selectedSubtitle = Subtitle.none
    }
  }

  enum Action: Equatable {
    /// Player lifecycle
    case onAppear
    case onDisappear

    /// Playback controls
    case playPauseTapped
    case seekTo(TimeInterval)
    case skipForward(TimeInterval)
    case skipBackward(TimeInterval)
    case performSeek(TimeInterval)  // Internal action for actual seeking

    /// Settings
    case playbackSpeedChanged(Float)
    case qualitySelected(String)
    case volumeChanged(Float)
    case muteToggled

    /// UI controls
    case toggleControls
    case toggleSettings
    case toggleSpeedMenu
    case toggleSourceMenu
    case toggleSubtitleMenu
    case subtitleSelected(Subtitle?)

    /// State updates
    case timeUpdated(current: TimeInterval, duration: TimeInterval)
    case playbackStateChanged(Bool)
    case seekingStateChanged(Bool)
    case bufferingStateChanged(Bool)
    case linkSelected(ExtractedLink)

    /// Casting
    case airPlayTapped
    case airPlayAvailabilityChanged(Bool)
    case castingStateChanged(Bool)
    case airPlayDeviceChanged(String?)

    /// Picture-in-Picture
    case pipTapped
    case pipStateChanged(isActive: Bool, isPossible: Bool, isSupported: Bool)

    /// Error handling
    case errorOccurred(String)
    case tryNextStream

    /// Navigation
    case dismiss
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.isLoading = false
        state.showControls = true
        return .none

      case .onDisappear:
        // Save watch history when leaving the player
        let content = state.content
        let episode = state.episode
        let season = state.season
        let currentTime = state.currentTime
        let duration = state.duration

        return .run { _ in
          do {
            try await WatchHistoryManager.shared.updateWatchHistory(
              content: content,
              season: season,
              episode: episode,
              currentTime: currentTime,
              duration: duration
            )
          } catch {
            await AppLogger.shared.log("Failed to update watch history: \(error)", level: .warning)
          }
        }

      case .playPauseTapped:
        state.isPlaying.toggle()
        return .none

      case .seekTo(let time):
        /// Clamp time to valid range
        let clampedTime = max(0, min(time, state.duration))
        state.currentTime = clampedTime
        state.isSeeking = false
        return .none

      case .skipForward(let interval):
        let newTime = min(state.currentTime + interval, state.duration)
        state.currentTime = newTime
        return .none

      case .skipBackward(let interval):
        let newTime = max(state.currentTime - interval, 0)
        state.currentTime = newTime
        return .none

      case .performSeek:
        /// This action is handled in the view layer
        return .none

      case .playbackSpeedChanged(let speed):
        state.playbackSpeed = speed
        state.showSpeedMenu = false
        state.showSettings = false
        return .none

      case .qualitySelected(let quality):
        state.selectedQuality = quality
        state.showSettings = false
        if let link = state.streamingLinks.first(where: { $0.quality == quality }) {
          state.selectedLink = link
        }
        return .none

      case .volumeChanged(let volume):
        state.volume = volume
        if volume > 0 && state.isMuted {
          state.isMuted = false
        }
        return .none

      case .muteToggled:
        state.isMuted.toggle()
        return .none

      case .toggleControls:
        state.showControls.toggle()
        return .none

      case .toggleSettings:
        state.showSettings.toggle()
        // Close other menus
        state.showSpeedMenu = false
        state.showSourceMenu = false
        state.showSubtitleMenu = false
        return .none

      case .toggleSpeedMenu:
        state.showSpeedMenu.toggle()
        // Close other menus
        state.showSettings = false
        state.showSourceMenu = false
        state.showSubtitleMenu = false
        return .none

      case .toggleSourceMenu:
        state.showSourceMenu.toggle()
        // Close other menus
        state.showSpeedMenu = false
        state.showSettings = false
        state.showSubtitleMenu = false
        return .none

      case .toggleSubtitleMenu:
        state.showSubtitleMenu.toggle()
        // Close other menus
        state.showSpeedMenu = false
        state.showSourceMenu = false
        state.showSettings = false
        return .none

      case .subtitleSelected(let subtitle):
        state.selectedSubtitle = subtitle
        state.showSubtitleMenu = false
        return .none

      case .timeUpdated(let current, let duration):
        /// Only update time if we're not actively seeking
        if !state.isSeeking {
          state.currentTime = current
        }
        state.duration = duration
        return .none

      case .playbackStateChanged(let isPlaying):
        state.isPlaying = isPlaying
        // When playback pauses/stops, persist watch history
        if !isPlaying {
          let content = state.content
          let episode = state.episode
          let season = state.season
          let currentTime = state.currentTime
          let duration = state.duration

          return .run { _ in
            do {
              try await WatchHistoryManager.shared.updateWatchHistory(
                content: content,
                season: season,
                episode: episode,
                currentTime: currentTime,
                duration: duration
              )
            } catch {
              await AppLogger.shared.log(
                "Failed to update watch history: \(error)", level: .warning)
            }
          }
        }
        return .none

      case .seekingStateChanged(let isSeeking):
        state.isSeeking = isSeeking
        return .none

      case .bufferingStateChanged(let isBuffering):
        state.isBuffering = isBuffering
        return .none

      case .linkSelected(let link):
        state.selectedLink = link
        state.selectedQuality = link.quality
        state.showSourceMenu = false
        return .none

      case .airPlayTapped:
        // AirPlay action is handled in the view layer through the AirPlayService
        // This action can be used for analytics or state updates if needed
        return .none

      case .airPlayAvailabilityChanged(let isAvailable):
        state.isAirPlayAvailable = isAvailable
        return .none

      case .castingStateChanged(let isCasting):
        state.isCasting = isCasting
        return .none

      case .airPlayDeviceChanged(let deviceName):
        state.connectedDeviceName = deviceName
        return .none

      case .pipTapped:
        // PiP action is handled in the view layer through the PictureInPictureService
        // This action can be used for analytics or state updates if needed
        return .none

      case .pipStateChanged(let isActive, let isPossible, let isSupported):
        state.isPiPActive = isActive
        state.isPiPPossible = isPossible
        state.isPiPSupported = isSupported
        return .none

      case .errorOccurred(let message):
        state.errorMessage = message
        state.isLoading = false
        return .none

      case .tryNextStream:
        guard let currentLink = state.selectedLink,
          let currentIndex = state.streamingLinks.firstIndex(of: currentLink),
          currentIndex + 1 < state.streamingLinks.count
        else {
          state.errorMessage = "All streaming sources failed"
          return .none
        }

        let nextLink = state.streamingLinks[currentIndex + 1]
        state.selectedLink = nextLink
        state.selectedQuality = nextLink.quality
        state.errorMessage = nil
        return .none

      case .dismiss:
        return .none
      }
    }
  }
}
