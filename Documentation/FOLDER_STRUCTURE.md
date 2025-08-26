# 🏗️ Improved Kenpachi Folder Structure

## 📁 Recommended Project Organization

```
Kenpachi/
├── 🚀 Application/                    # App lifecycle & configuration
│   ├── App/
│   │   ├── KenpachiApp.swift         # Main app entry point
│   ├── Configuration/
│   │   ├── Environment.swift         # Environment configs
│   │   ├── FeatureFlags.swift        # Feature toggles
│   │   └── AppConfiguration.swift    # App-wide settings
│   └── Constants/
│       ├── AppConstants.swift        # Global constants
│       ├── APIConstants.swift        # API endpoints
│       └── UserDefaultsKeys.swift    # UserDefaults keys
│
├── 🎯 Domain/                         # Business logic (Pure Swift)
│   ├── Entities/                     # Core business models
│   │   ├── Content/
│   │   │   ├── Content.swift
│   │   │   ├── Movie.swift
│   │   │   ├── TVShow.swift
│   │   │   ├── Episode.swift
│   │   │   └── Season.swift
│   │   ├── User/
│   │   │   ├── User.swift
│   │   │   ├── Profile.swift
│   │   │   └── Preferences.swift
│   │   ├── Streaming/
│   │   │   ├── VideoSource.swift
│   │   │   ├── StreamingQuality.swift
│   │   │   └── SubtitleTrack.swift
│   │   └── Download/
│   │       ├── DownloadItem.swift
│   │       ├── DownloadQueue.swift
│   │       └── DownloadProgress.swift
│   ├── UseCases/                     # Business use cases
│   │   ├── Content/
│   │   │   ├── GetTrendingContentUseCase.swift
│   │   │   ├── SearchContentUseCase.swift
│   │   │   ├── GetContentDetailsUseCase.swift
│   │   │   └── GetRelatedContentUseCase.swift
│   │   ├── Streaming/
│   │   │   ├── GetVideoSourcesUseCase.swift
│   │   │   ├── StartStreamingUseCase.swift
│   │   │   └── UpdateWatchProgressUseCase.swift
│   │   ├── Download/
│   │   │   ├── DownloadContentUseCase.swift
│   │   │   ├── ManageDownloadQueueUseCase.swift
│   │   │   └── GetDownloadsUseCase.swift
│   │   └── User/
│   │       ├── ManageWatchlistUseCase.swift
│   │       ├── UpdatePreferencesUseCase.swift
│   │       └── GetWatchHistoryUseCase.swift
│   └── Repositories/                 # Repository protocols (interfaces)
│       ├── ContentRepositoryProtocol.swift
│       ├── StreamingRepositoryProtocol.swift
│       ├── DownloadRepositoryProtocol.swift
│       ├── UserRepositoryProtocol.swift
│       └── SearchRepositoryProtocol.swift
│
├── 🔧 Infrastructure/                 # External concerns
│   ├── Network/
│   │   ├── Core/
│   │   │   ├── NetworkService.swift
│   │   │   ├── HTTPClient.swift
│   │   │   ├── NetworkError.swift
│   │   │   └── RequestBuilder.swift
│   │   ├── Scrapers/
│   │   │   ├── Base/
│   │   │   │   ├── ScraperProtocol.swift
│   │   │   │   ├── ExtractorProtocol.swift
│   │   │   │   └── ScraperError.swift
│   │   │   ├── Providers/
│   │   │   │   ├── FlixHQScraper.swift
│   │   │   │   ├── HiAnimeScraper.swift
│   │   │   │   └── GogoAnimeScraper.swift
│   │   │   └── Extractors/
│   │   │       ├── VidCloudExtractor.swift
│   │   │       ├── StreamSBExtractor.swift
│   │   │       └── MixDropExtractor.swift
│   │   └── API/
│   │       ├── TMDBService.swift
│   │       └── MetadataService.swift
│   ├── Persistence/
│   │   ├── Core/
│   │   │   ├── PersistenceService.swift
│   │   │   ├── DatabaseManager.swift
│   │   │   └── CacheManager.swift
│   │   ├── UserDefaults/
│   │   │   ├── UserDefaultsService.swift
│   │   │   └── PreferencesStorage.swift
│   │   ├── FileSystem/
│   │   │   ├── FileManager+Extensions.swift
│   │   │   ├── DownloadManager.swift
│   │   │   └── CacheStorage.swift
│   │   └── CoreData/ (if using CoreData)
│   │       ├── CoreDataStack.swift
│   │       ├── Models/
│   │       └── Migrations/
│   ├── Repositories/                 # Repository implementations
│   │   ├── ContentRepository.swift
│   │   ├── StreamingRepository.swift
│   │   ├── DownloadRepository.swift
│   │   ├── UserRepository.swift
│   │   └── SearchRepository.swift
│   └── External/
│       ├── Analytics/
│       │   ├── AnalyticsService.swift
│       │   └── EventTracker.swift
│       ├── Notifications/
│           ├── NotificationService.swift
│           └── PushNotificationHandler.swift
│
├── 🎨 Presentation/                   # UI Layer
│   ├── DesignSystem/
│   │   ├── Theme/
│   │   │   ├── AppTheme.swift
│   │   │   ├── Colors.swift
│   │   │   ├── Typography.swift
│   │   │   ├── Spacing.swift
│   │   │   └── Shadows.swift
│   │   ├── Components/
│   │   │   ├── Base/
│   │   │   │   ├── BaseButton.swift
│   │   │   │   ├── BaseCard.swift
│   │   │   │   └── BaseTextField.swift
│   │   │   ├── Buttons/
│   │   │   │   ├── PlayButton.swift
│   │   │   │   ├── DownloadButton.swift
│   │   │   │   ├── FavoriteButton.swift
│   │   │   │   └── ActionButton.swift
│   │   │   ├── Cards/
│   │   │   │   ├── ContentCard.swift
│   │   │   │   ├── HeroCard.swift
│   │   │   │   ├── EpisodeCard.swift
│   │   │   │   └── DownloadCard.swift
│   │   │   ├── Navigation/
│   │   │   │   ├── TabBar.swift
│   │   │   │   ├── NavigationBar.swift
│   │   │   │   └── CategoryBar.swift
│   │   │   ├── Input/
│   │   │   │   ├── SearchBar.swift
│   │   │   │   ├── QualitySelector.swift
│   │   │   │   └── FilterSelector.swift
│   │   │   ├── Loading/
│   │   │   │   ├── LoadingView.swift
│   │   │   │   ├── SkeletonLoader.swift
│   │   │   │   └── ProgressIndicator.swift
│   │   │   ├── Layout/
│   │   │   │   ├── ContentRow.swift
│   │   │   │   ├── GridLayout.swift
│   │   │   │   └── CarouselView.swift
│   │   │   └── Media/
│   │   │       ├── VideoPlayer.swift
│   │   │       ├── ImageLoader.swift
│   │   │       └── ThumbnailView.swift
│   │   └── Modifiers/
│   │       ├── ViewModifiers.swift
│   │       ├── ButtonStyles.swift
│   │       └── TextStyles.swift
│   ├── Features/                     # Feature-specific UI
│   │   ├── Home/
│   │   │   ├── HomeFeature.swift     # TCA Feature
│   │   │   ├── HomeView.swift        # Main view
│   │   │   ├── Components/
│   │   │   │   ├── HeroSection.swift
│   │   │   │   ├── CategorySection.swift
│   │   │   │   └── ContentSection.swift
│   │   ├── Search/
│   │   │   ├── SearchFeature.swift
│   │   │   ├── SearchView.swift
│   │   │   ├── Components/
│   │   │   │   ├── SearchResults.swift
│   │   │   │   ├── SearchFilters.swift
│   │   │   │   └── RecentSearches.swift
│   │   ├── ContentDetail/
│   │   │   ├── ContentDetailFeature.swift
│   │   │   ├── ContentDetailView.swift
│   │   │   ├── Components/
│   │   │   │   ├── DetailHeader.swift
│   │   │   │   ├── EpisodesList.swift
│   │   │   │   ├── CastCrew.swift
│   │   │   │   └── RelatedContent.swift
│   │   ├── Player/
│   │   │   ├── PlayerFeature.swift
│   │   │   ├── PlayerView.swift
│   │   │   ├── Components/
│   │   │   │   ├── PlayerControls.swift
│   │   │   │   ├── QualitySelector.swift
│   │   │   │   ├── SubtitleSelector.swift
│   │   │   │   └── PlaybackSettings.swift
│   │   ├── Downloads/
│   │   │   ├── DownloadsFeature.swift
│   │   │   ├── DownloadsView.swift
│   │   │   ├── Components/
│   │   │   │   ├── DownloadsList.swift
│   │   │   │   ├── DownloadProgress.swift
│   │   │   │   └── DownloadSettings.swift
│   │   ├── Profile/
│   │   │   ├── ProfileFeature.swift
│   │   │   ├── ProfileView.swift
│   │   │   ├── Components/
│   │   │   │   ├── ProfileHeader.swift
│   │   │   │   ├── SettingsSection.swift
│   │   │   │   └── WatchHistory.swift
│   └── Utils/
│       ├── Extensions/
│       │   ├── View+Extensions.swift
│       │   ├── Color+Extensions.swift
│       │   ├── String+Extensions.swift
│       │   └── Date+Extensions.swift
│       ├── Helpers/
│       │   ├── ImageCache.swift
│       │   ├── HapticFeedback.swift
│       │   └── AccessibilityHelper.swift
│       └── Protocols/
│           ├── ViewProtocols.swift
│           └── ComponentProtocols.swift
│
│
├── 📱 Resources/                      # App resources
│   ├── Assets.xcassets/
│   │   ├── Colors/
│   │   ├── Images/
│   │   ├── Icons/
│   │   └── AppIcon.appiconset/
│   ├── Fonts/
│   ├── Localizable/
│   │   ├── Localizable.xcstrings
│   ├── Data/
│   │   ├── SampleData.json
│   │   └── MockResponses/
│   └── Configuration/
│       ├── Debug.xcconfig
│       ├── Release.xcconfig
│       └── Kenpachi.entitlements
│
├── 📱 Kenpachi.entitlements
│
└── 📚 Documentation/                  # Project documentation
    ├── Architecture.md
    ├── API.md
    ├── Scrapers.md
    ├── Testing.md
    └── Deployment.md
```

## 🎯 Key Improvements

### 1. **Clean Architecture Separation**
- **Domain**: Pure business logic (no dependencies)
- **Infrastructure**: External concerns (network, database, etc.)
- **Presentation**: UI layer with TCA features

### 2. **Feature-Based Organization**
- Each feature is self-contained
- Components organized by type and purpose
- Clear separation of concerns

### 3. **Scalable Design System**
- Centralized theme and components
- Reusable UI elements
- Consistent styling approach

### 4. **Testability**
- Clear test structure
- Separated by layer and type
- Mock and fixture support

### 5. **Resource Management**
- Organized assets and configurations
- Localization support
- Environment-specific configs

## 🔄 Migration Strategy

### Phase 1: Core Structure
1. Create new folder structure
2. Move domain models to `Domain/Entities/`
3. Extract use cases from current services
4. Create repository protocols

### Phase 2: Infrastructure
1. Move network code to `Infrastructure/Network/`
2. Organize scrapers by provider
3. Create persistence layer
4. Implement repository concrete classes

### Phase 3: Presentation
1. Move theme to `Presentation/DesignSystem/`
2. Organize components by type
3. Refactor features to use new structure
4. Create shared UI components

### Phase 4: Testing & Documentation
1. Set up test structure
2. Add unit tests for use cases
3. Create integration tests
4. Document architecture decisions