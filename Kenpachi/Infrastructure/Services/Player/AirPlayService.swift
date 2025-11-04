// AirPlayService.swift
// Manages AirPlay functionality for video streaming
// Provides seamless casting to Apple TV and compatible devices

import AVFoundation
import Combine
import Foundation

/// Service for managing AirPlay functionality
@MainActor
final class AirPlayService: ObservableObject {
  
  // MARK: - Published Properties
  
  /// Whether AirPlay is currently available
  @Published var isAirPlayAvailable = false
  
  /// Whether content is currently being cast via AirPlay
  @Published var isAirPlayActive = false
  
  /// Name of the currently connected AirPlay device
  @Published var connectedDeviceName: String?
  
  // MARK: - Private Properties
  
  /// Current AVPlayer instance
  private var player: AVPlayer?
  
  /// Cancellables for Combine subscriptions
  private var cancellables = Set<AnyCancellable>()
  
  /// Route detector for monitoring AirPlay availability
  private var routeDetector: AVRouteDetector?
  
  // MARK: - Initialization
  
  init() {
    setupRouteDetection()
    observeAirPlayStatus()
  }
  
  deinit {
    // Automatic cleanup will handle cancellables and routeDetector
    // No manual cleanup needed in deinit for @MainActor classes
  }
  
  // MARK: - Public Methods
  
  /// Sets the player instance to monitor for AirPlay
  /// - Parameter player: The AVPlayer instance
  func setPlayer(_ player: AVPlayer) {
    self.player = player
    
    // Enable external playback for AirPlay
    player.allowsExternalPlayback = true
    player.usesExternalPlaybackWhileExternalScreenIsActive = true
    
    // Monitor external playback status
    observeExternalPlayback(for: player)
  }
  
  /// Removes the current player reference
  func removePlayer() {
    self.player = nil
    cancellables.removeAll()
  }
  
  /// Cleans up resources
  func cleanup() {
    removePlayer()
    
    // Disable route detection
    routeDetector?.isRouteDetectionEnabled = false
    routeDetector = nil
    
    // Clear state
    isAirPlayAvailable = false
    isAirPlayActive = false
    connectedDeviceName = nil
  }
  

  
  /// Presents the AirPlay route picker
  func presentAirPlayPicker() {
    // This will be handled by the AVRoutePickerView in the UI
    // The service provides the state management
  }
  
  /// Disconnects from the current AirPlay device
  func disconnectAirPlay() {
    guard let player = player else { return }
    
    // Force playback back to local device
    player.allowsExternalPlayback = false
    
    // Re-enable external playback after a brief delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      player.allowsExternalPlayback = true
    }
  }
  
  // MARK: - Private Methods
  
  /// Sets up route detection for AirPlay availability
  private func setupRouteDetection() {
    // Check if we're in simulator - route detection may not work properly
    #if targetEnvironment(simulator)
    print("AirPlay route detection disabled in simulator")
    isAirPlayAvailable = false
    return
    #endif
    
    // Create route detector safely with error handling
    let detector = AVRouteDetector()
    routeDetector = detector
    
    // Enable route detection with a slight delay to avoid initialization issues
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self, weak detector] in
      guard let self = self, let detector = detector else { return }
      
      do {
        detector.isRouteDetectionEnabled = true
        
        // Monitor route detector availability with error handling
        detector.publisher(for: \.multipleRoutesDetected)
          .receive(on: DispatchQueue.main)
          .catch { error -> Just<Bool> in
            print("Route detection error: \(error)")
            return Just(false)
          }
          .sink { [weak self] isAvailable in
            self?.isAirPlayAvailable = isAvailable
          }
          .store(in: &self.cancellables)
      } catch {
        print("Failed to setup route detection: \(error)")
        // Fall back to basic AirPlay detection
        self.isAirPlayAvailable = false
      }
    }
  }
  
  /// Observes general AirPlay status changes
  private func observeAirPlayStatus() {
    // Monitor audio session route changes
    NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] notification in
        self?.handleRouteChange(notification)
      }
      .store(in: &cancellables)
  }
  
  /// Observes external playback status for a specific player
  /// - Parameter player: The AVPlayer to monitor
  private func observeExternalPlayback(for player: AVPlayer) {
    // Monitor external playback active status
    player.publisher(for: \.isExternalPlaybackActive)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isActive in
        self?.isAirPlayActive = isActive
        self?.updateConnectedDeviceName(for: player)
      }
      .store(in: &cancellables)
  }
  
  /// Handles audio session route changes
  /// - Parameter notification: The route change notification
  private func handleRouteChange(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
      return
    }
    
    switch reason {
    case .newDeviceAvailable, .oldDeviceUnavailable:
      // Update AirPlay availability
      updateAirPlayAvailability()
    default:
      break
    }
  }
  

  
  /// Updates the connected device name
  /// - Parameter player: The current player
  private func updateConnectedDeviceName(for player: AVPlayer) {
    if player.isExternalPlaybackActive {
      // Get the current audio route
      let audioSession = AVAudioSession.sharedInstance()
      let currentRoute = audioSession.currentRoute
      
      // Find AirPlay output
      if let airPlayOutput = currentRoute.outputs.first(where: { $0.portType == .airPlay }) {
        connectedDeviceName = airPlayOutput.portName
      } else {
        // Fallback: if external playback is active but no AirPlay port found,
        // it might be a different type of external playback
        connectedDeviceName = "External Device"
      }
    } else {
      connectedDeviceName = nil
    }
  }
  
  /// Updates AirPlay availability based on current routes
  private func updateAirPlayAvailability() {
    // Primary check: use route detector for multiple routes (if available)
    if let detector = routeDetector {
      isAirPlayAvailable = detector.multipleRoutesDetected
    }
    
    // Secondary check: examine current audio session routes
    do {
      let audioSession = AVAudioSession.sharedInstance()
      let currentRoute = audioSession.currentRoute
      
      // Check if AirPlay routes are currently active
      let hasActiveAirPlayRoutes = currentRoute.outputs.contains { $0.portType == .airPlay }
      
      // Update availability if AirPlay routes are found
      if hasActiveAirPlayRoutes {
        isAirPlayAvailable = true
      }
    } catch {
      print("Failed to check audio session routes: \(error)")
    }
  }
}

// MARK: - Extensions

extension AVAudioSessionPortDescription {
  /// Whether this port is an AirPlay device
  var isAirPlayDevice: Bool {
    return portType == .airPlay
  }
}