import SwiftUI

struct HeroSection: View {
    let content: Content
    let onTap: () -> Void
    
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
            }
            .frame(height: 400)
            .clipped()
            
            // Gradient Overlay
            LinearGradient(
                colors: [
                    AppTheme.current.colors.gradientEnd,
                    AppTheme.current.colors.gradientStart
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                Text(content.title)
                    .font(AppTheme.current.typography.headlineLarge)
                    .foregroundColor(AppTheme.current.colors.textPrimary)
                    .lineLimit(2)
                
                if !content.overview.isEmpty {
                    Text(content.overview)
                        .font(AppTheme.current.typography.bodyMedium)
                        .foregroundColor(AppTheme.current.colors.textSecondary)
                        .lineLimit(3)
                }
                
                HStack(spacing: 12) {
                    PlayButton {
                        onTap()
                    }
                    
                    ActionButton(
                        title: "More Info",
                        style: .secondary
                    ) {
                        onTap()
                    }
                }
            }
            .padding(AppTheme.current.spacing.screenPadding)
        }
        .cornerRadius(AppTheme.current.cornerRadius.card)
        .onTapGesture {
            onTap()
        }
    }
}