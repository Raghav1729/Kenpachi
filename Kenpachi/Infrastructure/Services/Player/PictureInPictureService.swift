// PictureInPictureService.swift
// Manages Picture-in-Picture functionality for video playback
// Provides seamless background video viewing experience

import AVKit
import Combine
import Foundation
import UIKit

/// Service for managing Picture-in-Picture functionality
@MainActor
final class PictureInPictureService: NSObject, ObservableObject {
  
  // MARK: - Published Properties
  
  /// Whether PiP is supported on the current device
  @Published var isPiPSupported = false
  
  /// Whether PiP is currently active
  @Published var isPiPActive = false
  
  /// Whether PiP is possible with current content
  @Published var isPiPPossible = false
  
  /// Whether PiP was started automatically
  @Published var wasStartedAutomatically = false
  
  // MARK: - Private Properties
  
  /// Picture-in-Picture controller
  private var pipController: AVPictureInPictureController?
  
  /// Current player layer
  private var playerLayer: AVPlayerLayer?
  
  /// Cancellables for Combine subscriptions
  private var cancellables = Set<AnyCancellable>()
  
  /// Delegate callbacks
  private var onPiPWillStart: (() -> Void)?
  private var onPiPDidStart: (() -> Void)?
  private var onPiPWillStop: (() -> Void)?
  private var onPiPDidStop: (() -> Void)?
  private var onRestoreUserInterface: (() -> Void)?
  
  // MARK: - Initialization
  
  override init() {
    super.init()
    setupPictureInPicture()
  }
  
  // MARK: - Public Methods
  
  /// Sets up PiP with the given player layer
  /// - Parameter playerLayer: The AVPlayerLayer to use for PiP
  func setupPiP(with playerLayer: AVPlayerLayer) {
    self.playerLayer = playerLayer
    
    guard AVPictureInPictureController.isPictureInPictureSupported() else {
      isPiPSupported = false
      return
    }
    
    isPiPSupported = true
    
    // Create PiP controller
    pipController = AVPictureInPictureController(playerLayer: playerLayer)
    pipController?.delegate = self
    
    // Observe PiP possibility
    observePiPPossibility()
  }
  
  /// Sets up PiP with the given content source
  /// - Parameter contentSource: The AVPictureInPictureController.ContentSource
  @available(iOS 15.0, *)
  func setupPiP(with contentSource: AVPictureInPictureController.ContentSource) {
    guard AVPictureInPictureController.isPictureInPictureSupported() else {
      isPiPSupported = false
      return
    }
    
    isPiPSupported = true
    
    // Create PiP controller with content source
    pipController = AVPictureInPictureController(contentSource: contentSource)
    pipController?.delegate = self
    
    // Observe PiP possibility
    observePiPPossibility()
  }
  
  /// Starts Picture-in-Picture mode
  func startPiP() {
    guard let pipController = pipController,
          pipController.isPictureInPicturePossible else {
      return
    }
    
    pipController.startPictureInPicture()
  }
  
  /// Stops Picture-in-Picture mode
  func stopPiP() {
    guard let pipController = pipController,
          pipController.isPictureInPictureActive else {
      return
    }
    
    pipController.stopPictureInPicture()
  }
  
  /// Sets the delegate callbacks
  /// - Parameters:
  ///   - onWillStart: Called when PiP will start
  ///   - onDidStart: Called when PiP did start
  ///   - onWillStop: Called when PiP will stop
  ///   - onDidStop: Called when PiP did stop
  ///   - onRestoreUserInterface: Called when user interface should be restored
  func setCallbacks(
    onWillStart: (() -> Void)? = nil,
    onDidStart: (() -> Void)? = nil,
    onWillStop: (() -> Void)? = nil,
    onDidStop: (() -> Void)? = nil,
    onRestoreUserInterface: (() -> Void)? = nil
  ) {
    self.onPiPWillStart = onWillStart
    self.onPiPDidStart = onDidStart
    self.onPiPWillStop = onWillStop
    self.onPiPDidStop = onDidStop
    self.onRestoreUserInterface = onRestoreUserInterface
  }
  
  /// Cleans up PiP resources
  func cleanup() {
    pipController?.delegate = nil
    pipController = nil
    playerLayer = nil
    cancellables.removeAll()
  }
  
  // MARK: - Private Methods
  
  /// Sets up Picture-in-Picture support
  private func setupPictureInPicture() {
    // Check if PiP is supported
    isPiPSupported = AVPictureInPictureController.isPictureInPictureSupported()
    
    // Configure audio session for PiP
    configureAudioSession()
    
    // Observe app lifecycle for PiP management
    observeAppLifecycle()
  }
  
  /// Configures the audio session for PiP support
  private func configureAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .moviePlayback)
      try audioSession.setActive(true)
    } catch {
      print("Failed to configure audio session for PiP: \(error)")
    }
  }
  
  /// Observes PiP possibility changes
  private func observePiPPossibility() {
    guard let pipController = pipController else { return }
    
    pipController.publisher(for: \.isPictureInPicturePossible)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isPossible in
        self?.isPiPPossible = isPossible
      }
      .store(in: &cancellables)
  }
  
  /// Observes app lifecycle events
  private func observeAppLifecycle() {
    // Observe app entering background
    NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.handleAppDidEnterBackground()
      }
      .store(in: &cancellables)
    
    // Observe app becoming active
    NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.handleAppDidBecomeActive()
      }
      .store(in: &cancellables)
  }
  
  /// Handles app entering background
  private func handleAppDidEnterBackground() {
    // Automatically start PiP if possible and content is playing
    guard let pipController = pipController,
          pipController.isPictureInPicturePossible,
          !pipController.isPictureInPictureActive,
          let player = playerLayer?.player,
          player.rate > 0 else {
      return
    }
    
    // Start PiP automatically
    wasStartedAutomatically = true
    pipController.startPictureInPicture()
  }
  
  /// Handles app becoming active
  private func handleAppDidBecomeActive() {
    // Reset automatic start flag
    wasStartedAutomatically = false
  }
}

// MARK: - AVPictureInPictureControllerDelegate

extension PictureInPictureService: AVPictureInPictureControllerDelegate {
  
  func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    isPiPActive = true
    onPiPWillStart?()
  }
  
  func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    onPiPDidStart?()
  }
  
  func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    onPiPWillStop?()
  }
  
  func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    isPiPActive = false
    onPiPDidStop?()
  }
  
  func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, 
                                 restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
    // Restore the user interface
    onRestoreUserInterface?()
    
    // Complete the restoration
    completionHandler(true)
  }
  
  func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, 
                                 failedToStartPictureInPictureWithError error: Error) {
    print("Failed to start Picture-in-Picture: \(error.localizedDescription)")
    isPiPActive = false
  }
}