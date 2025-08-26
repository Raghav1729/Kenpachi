import SwiftUI

struct ContentCard: View {
  let content: Content
  let onTap: () -> Void

  private let cardWidth: CGFloat = 140
  private let cardHeight: CGFloat = 200

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Poster Image
      AsyncImage(url: URL(string: content.posterURL ?? "")) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Rectangle()
          .fill(AppTheme.current.colors.surface)
          .overlay(
            Image(systemName: "photo")
              .foregroundColor(AppTheme.current.colors.textTertiary)
          )
      }
      .frame(width: cardWidth, height: cardHeight * 0.75)
      .cornerRadius(AppTheme.current.cornerRadius.card)
      .clipped()

      // Content Info
      VStack(alignment: .leading, spacing: 4) {
        Text(content.title)
          .font(AppTheme.current.typography.labelMedium)
          .foregroundColor(AppTheme.current.colors.textPrimary)
          .lineLimit(2)
          .multilineTextAlignment(.leading)

        if content.rating > 0 {
          HStack(spacing: 4) {
            Image(systemName: "star.fill")
              .foregroundColor(.yellow)
              .font(.system(size: 10))

            Text(String(format: "%.1f", content.rating))
              .font(AppTheme.current.typography.captionSmall)
              .foregroundColor(AppTheme.current.colors.textSecondary)
          }
        }
      }
    }
    .frame(width: cardWidth)
    .onTapGesture {
      onTap()
    }
  }
}
