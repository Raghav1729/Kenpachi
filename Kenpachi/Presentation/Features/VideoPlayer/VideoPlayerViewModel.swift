import Foundation
import AVFoundation
import Combine

@MainActor
final class VideoPlayerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var player: AVPlayer?
    @Published var isLoading = false
    @Published var isPlaying = false
    @Published var isBuffering = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var error: StreamingError?
    
    // Video Sources
    @Published var videoSources: [VideoSource] = []
    @Published var selectedVideoSource: VideoSource?
    @Published var showQualitySelector = false
    
    // Subtitles
    @Published var availableSubtitles: [SubtitleTrack] = []
    @Published var selectedSubtitle: SubtitleTrack?
    @Published var showSubtitleSelector = false
    
    // MARK: - Private Properties
    private let content: Content
    private let streamingService: StreamingServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var timeObserver: Any?
    private var playerItemObserver: NSKeyValueObservation?
    
    // MARK: - Initialization
    init(
        content: Content,
        streamingService: StreamingServiceProtocol = StreamingService()
    ) {
        self.content = content
        self.streamingService = streamingService
        setupNotifications()
    }
    
    deinit {
        Task { @MainActor in
            cleanup()
        }
    }
    
    // MARK: - Public Methods
    func loadVideoSources() {
        isLoading = true
        error = nil
        
        streamingService.getVideoSources(for: content.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] sources in
                    self?.handleVideoSources(sources)
                }
            )
            .store(in: &cancellables)
    }
    
    func changeVideoSource(_ source: VideoSource) {
        guard source.id != selectedVideoSource?.id else { return }
        
        let currentTime = self.currentTime
        selectedVideoSource = source
        showQualitySelector = false
        
        loadVideoForSource(source) { [weak self] in
            // Resume from the same position
            self?.seek(to: currentTime)
        }
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        
        if player.rate == 0 {
            player.play()
            isPlaying = true
        } else {
            player.pause()
            isPlaying = false
        }
    }
    
    func seek(to time: Double) {
        guard let player = player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime)
    }
    
    func seekForward() {
        let newTime = min(currentTime + 10, duration)
        seek(to: newTime)
    }
    
    func seekBackward() {
        let newTime = max(currentTime - 10, 0)
        seek(to: newTime)
    }
    
    func selectSubtitle(_ subtitle: SubtitleTrack?) {
        selectedSubtitle = subtitle
        showSubtitleSelector = false
        
        guard let player = player,
              let playerItem = player.currentItem else { return }
        
        // For now, just store the selection
        // In a real app, you would apply the subtitle track to the player
        print("Selected subtitle: \(subtitle?.label ?? "Off")")
    }
    
    func retryLoading() {
        error = nil
        loadVideoSources()
    }
    
    func cleanup() {
        player?.pause()
        player = nil
        
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        playerItemObserver?.invalidate()
        playerItemObserver = nil
        
        cancellables.removeAll()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Methods
    private func handleVideoSources(_ sources: [VideoSource]) {
        videoSources = sources
        
        // Select first source (we'll add default logic later)
        let defaultSource = sources.first
        guard let source = defaultSource else {
            handleError(.noSourcesAvailable)
            return
        }
        
        selectedVideoSource = source
        loadVideoForSource(source)
    }
    
    private func loadVideoForSource(_ source: VideoSource, completion: (() -> Void)? = nil) {
        isLoading = true
        
        streamingService.getStreamingURL(for: source)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    if case .failure(let error) = completionResult {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] url in
                    self?.setupPlayer(with: url, completion: completion)
                }
            )
            .store(in: &cancellables)
    }
    
    private func setupPlayer(with url: URL, completion: (() -> Void)? = nil) {
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        // Setup player observers
        setupPlayerObservers(for: newPlayer)
        setupPlayerItemObservers(for: playerItem)
        
        player = newPlayer
        isLoading = false
        
        // Load available subtitles
        loadAvailableSubtitles(from: playerItem)
        
        completion?()
    }
    
    private func setupPlayerObservers(for player: AVPlayer) {
        // Time observer
        let timeInterval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }
    
    private func setupPlayerItemObservers(for playerItem: AVPlayerItem) {
        // Duration observer
        playerItemObserver = playerItem.observe(\.duration) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.duration = item.duration.seconds
            }
        }
        
        // Status observer
        playerItemObserver = playerItem.observe(\.status) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self?.isLoading = false
                case .failed:
                    if let error = item.error {
                        self?.handleError(.networkError)
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func setupNotifications() {
        // Playback finished
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
        }
        
        // Playback stalled
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isBuffering = true
        }
        
        // Playback resumed
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewAccessLogEntry,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isBuffering = false
        }
    }
    
    private func loadAvailableSubtitles(from playerItem: AVPlayerItem) {
        var subtitles: [SubtitleTrack] = []
        
        // Add "Off" option
        subtitles.append(SubtitleTrack(
            id: "off",
            url: "",
            language: "Off",
            languageCode: "off",
            label: "Off",
            format: .srt,
            isDefault: true,
            isForced: false,
            isSDH: false,
            encoding: nil,
            fileSize: nil,
            lastModified: nil
        ))
        
        // For now, add some sample subtitle tracks
        // In a real app, you would extract these from the video or get them from your API
        let sampleSubtitles = [
            SubtitleTrack(
                id: "en",
                url: "",
                language: "English",
                languageCode: "en",
                label: "English",
                format: .srt,
                isDefault: false,
                isForced: false,
                isSDH: false,
                encoding: nil,
                fileSize: nil,
                lastModified: nil
            ),
            SubtitleTrack(
                id: "es",
                url: "",
                language: "Spanish",
                languageCode: "es",
                label: "Español",
                format: .srt,
                isDefault: false,
                isForced: false,
                isSDH: false,
                encoding: nil,
                fileSize: nil,
                lastModified: nil
            )
        ]
        subtitles.append(contentsOf: sampleSubtitles)
        
        availableSubtitles = subtitles
        selectedSubtitle = subtitles.first // Default to "Off"
    }
    
    private func handleError(_ error: StreamingError) {
        isLoading = false
        self.error = error
        print("Streaming error: \(error.localizedDescription)")
    }
}