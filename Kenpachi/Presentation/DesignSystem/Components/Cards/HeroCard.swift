import SwiftUI

struct HeroCard: View {
    let content: Content
    let onPlay: () -> Void
    let onAddToWatchlist: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            AsyncImage(url: URL(string: content.backdropURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(AppTheme.current.colors.surface)
                    .overlay(
                        ProgressView()
                            .tint(AppTheme.current.colors.accent)
                    )
            }
            .frame(height: 500)
            .clipped()
            
            // Gradient Overlay
            LinearGradient(
                colors: [
                    AppTheme.current.colors.gradientEnd,
                    AppTheme.current.colors.gradientStart.opacity(0.8),
                    AppTheme.current.colors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Content Info
            VStack(alignment: .leading, spacing: 16) {
                // Disney Plus Logo (if available)
                if content.contentType == .movie {
                    HStack {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(AppTheme.current.colors.accent)
                        Text("DISNEY+")
                            .font(AppTheme.current.typography.labelSmall)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.current.colors.accent)
                    }
                }
                
                // Title
                Text(content.title)
                    .font(AppTheme.current.typography.displayLarge)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.current.colors.textPrimary)
                    .lineLimit(2)
                
                // Genres and Rating
                HStack {
                    Text(content.genres.prefix(2).map { $0.name }.joined(separator: " • "))
                        .font(AppTheme.current.typography.bodyMedium)
                        .foregroundColor(AppTheme.current.colors.textSecondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", content.rating))
                            .font(AppTheme.current.typography.labelMedium)
                            .foregroundColor(AppTheme.current.colors.textSecondary)
                    }
                }
                
                // Overview
                if !content.overview.isEmpty {
                    Text(content.overview)
                        .font(AppTheme.current.typography.bodyMedium)
                        .foregroundColor(AppTheme.current.colors.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    // Play Button
                    PlayButton(action: onPlay)
                    
                    // Watchlist Button
                    ActionButton(
                        title: "Watchlist",
                        style: .secondary
                    ) {
                        onAddToWatchlist()
                    }
                    
                    Spacer()
                    
                    // Share Button
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(AppTheme.current.colors.textSecondary)
                    }
                }
                .padding(.bottom, AppTheme.current.spacing.lg)
            }
            .padding(.horizontal, AppTheme.current.spacing.screenPadding)
            .padding(.bottom, AppTheme.current.spacing.lg)
        }
        .cornerRadius(AppTheme.current.cornerRadius.large)
    }
}

#Preview {
    HeroCard(
        content: MockData.sampleMovies.first!,
        onPlay: {},
        onAddToWatchlist: {}
    )
    .preferredColorScheme(.dark)
}