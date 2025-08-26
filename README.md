# Kenpachi - Disney+ Clone

A modern streaming app built with SwiftUI and The Composable Architecture (TCA), featuring content discovery, video streaming, downloads, and user management.

## Features

- 🎬 **Content Discovery**: Browse trending movies, TV shows, and anime
- 🔍 **Advanced Search**: Search with filters and suggestions
- 📱 **Multiple Profiles**: Family-friendly profile management
- ⬇️ **Offline Downloads**: Download content for offline viewing
- 🎮 **Video Player**: Custom video player with quality selection
- 🎨 **Modern UI**: Disney+ inspired design system
- 🏗️ **Clean Architecture**: Domain-driven design with TCA

## Architecture

The app follows Clean Architecture principles with three main layers:

### 🚀 Application Layer
- App lifecycle and configuration
- Environment settings and feature flags
- Global constants and configurations

### 🎯 Domain Layer
- Business entities (Content, User, Downloads)
- Use cases for business logic
- Repository protocols (interfaces)

### 🔧 Infrastructure Layer
- Network services and API clients
- Content scrapers for streaming sources
- Data persistence and caching
- Repository implementations

### 🎨 Presentation Layer
- SwiftUI views and components
- TCA features and reducers
- Design system and theming

## Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **The Composable Architecture (TCA)** - State management and architecture
- **Combine** - Reactive programming
- **Alamofire** - HTTP networking
- **Kingfisher** - Image loading and caching

## Content Sources

The app integrates with multiple content providers:

- **TMDB API** - Movie and TV show metadata
- **FlixHQ** - Streaming sources
- **HiAnime** - Anime content
- **GogoAnime** - Additional anime sources

## Getting Started

1. Clone the repository
2. Open `Kenpachi.xcodeproj` in Xcode
3. Add your TMDB API key in `TMDBService.swift`
4. Build and run the project

## Project Structure

```
Kenpachi/
├── Application/          # App configuration and constants
├── Domain/              # Business logic and entities
├── Infrastructure/      # External services and data
├── Presentation/        # UI components and features
└── Resources/          # Assets and configurations
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is for educational purposes only. Please respect content creators and use legal streaming services.

## Disclaimer

This app is a clone for learning purposes. All content and trademarks belong to their respective owners.