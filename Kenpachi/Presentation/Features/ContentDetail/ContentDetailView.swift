import SwiftUI

struct ContentDetailView: View {
  let content: Content
  @SwiftUI.Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @State private var isInWatchlist = false
  @State private var isFavorite = false
  @State private var showingPlayer = false

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 0) {
          // Hero Image
          ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: content.backdropURL ?? content.posterURL ?? "")) { image in
              image
                .resizable()
                .aspectRatio(16 / 9, contentMode: .fill)
            } placeholder: {
              Rectangle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(16 / 9, contentMode: .fill)
            }
            .frame(height: 250)
            .clipped()

            // Close Button
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
              Image(systemName: "xmark")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
            }
            .padding(16)

            // Play Button Overlay
            Button(action: { showingPlayer = true }) {
              Image(systemName: "play.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          }

          // Content Info
          VStack(alignment: .leading, spacing: 16) {
            // Title and Basic Info
            VStack(alignment: .leading, spacing: 8) {
              Text(content.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

              HStack {
                // Rating
                HStack(spacing: 4) {
                  Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                  Text(String(format: "%.1f", content.rating))
                    .foregroundColor(.white)
                }

                Text("•")
                  .foregroundColor(.gray)

                // Content Type
                Text(content.contentType.rawValue.capitalized)
                  .foregroundColor(.gray)

                if let runtime = content.runtime {
                  Text("•")
                    .foregroundColor(.gray)

                  Text("\(runtime)m")
                    .foregroundColor(.gray)
                }
              }
              .font(.subheadline)

              // Genres
              Text(content.genres.map { $0.name }.joined(separator: " • "))
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            // Action Buttons
            HStack(spacing: 12) {
              // Play Button
              Button(action: { showingPlayer = true }) {
                HStack {
                  Image(systemName: "play.fill")
                  Text("Play")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(8)
              }

              // Download Button
              Button(action: {}) {
                Image(systemName: "arrow.down.circle")
                  .font(.title2)
                  .foregroundColor(.white)
                  .frame(width: 44, height: 44)
                  .background(Color.gray.opacity(0.3))
                  .clipShape(Circle())
              }

              // Watchlist Button
              Button(action: { isInWatchlist.toggle() }) {
                Image(systemName: isInWatchlist ? "checkmark" : "plus")
                  .font(.title2)
                  .foregroundColor(.white)
                  .frame(width: 44, height: 44)
                  .background(Color.gray.opacity(0.3))
                  .clipShape(Circle())
              }

              // Favorite Button
              Button(action: { isFavorite.toggle() }) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                  .font(.title2)
                  .foregroundColor(isFavorite ? .red : .white)
                  .frame(width: 44, height: 44)
                  .background(Color.gray.opacity(0.3))
                  .clipShape(Circle())
              }
            }

            // Overview
            VStack(alignment: .leading, spacing: 8) {
              Text("Overview")
                .font(.headline)
                .foregroundColor(.white)

              Text(content.overview)
                .font(.body)
                .foregroundColor(.gray)
                .lineSpacing(4)
            }

            // Additional Info for TV Shows
            if content.contentType == .tvShow {
              TVShowInfo(content: content)
            }

            // Cast & Crew (Mock data)
            CastCrewSection()

            // Related Content
            RelatedContentSection()
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 24)
        }
      }
      .background(Color.black)
      .navigationBarHidden(true)
    }
    .fullScreenCover(isPresented: $showingPlayer) {
      EnhancedVideoPlayerView(content: content)
    }
  }
}

struct TVShowInfo: View {
  let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Show Info")
        .font(.headline)
        .foregroundColor(.white)

      VStack(spacing: 8) {
        if let seasons = content.numberOfSeasons {
          InfoRow(title: "Seasons", value: "\(seasons)")
        }

        if let episodes = content.numberOfEpisodes {
          InfoRow(title: "Episodes", value: "\(episodes)")
        }

        if let status = content.status {
          InfoRow(title: "Status", value: status)
        }

        if let firstAirDate = content.firstAirDate {
          InfoRow(
            title: "First Aired",
            value: {
              let formatter = DateFormatter()
              formatter.dateFormat = "yyyy"
              return formatter.string(from: firstAirDate)
            }())
        }
      }
    }
  }
}

struct InfoRow: View {
  let title: String
  let value: String

  var body: some View {
    HStack {
      Text(title)
        .foregroundColor(.gray)

      Spacer()

      Text(value)
        .foregroundColor(.white)
    }
    .font(.subheadline)
  }
}

struct CastCrewSection: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Cast & Crew")
        .font(.headline)
        .foregroundColor(.white)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(0..<5) { index in
            CastMemberCard(
              name: "Actor \(index + 1)",
              character: "Character \(index + 1)"
            )
          }
        }
        .padding(.horizontal, 1)
      }
    }
  }
}

struct CastMemberCard: View {
  let name: String
  let character: String

  var body: some View {
    VStack(spacing: 8) {
      Circle()
        .fill(Color.gray.opacity(0.3))
        .frame(width: 80, height: 80)
        .overlay(
          Image(systemName: "person.fill")
            .font(.title)
            .foregroundColor(.gray)
        )

      VStack(spacing: 2) {
        Text(name)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.white)
          .lineLimit(1)

        Text(character)
          .font(.caption2)
          .foregroundColor(.gray)
          .lineLimit(1)
      }
    }
    .frame(width: 80)
  }
}

struct RelatedContentSection: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("More Like This")
        .font(.headline)
        .foregroundColor(.white)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(MockData.sampleMovies.prefix(5)) { content in
            RelatedContentCard(content: content)
          }
        }
        .padding(.horizontal, 1)
      }
    }
  }
}

struct RelatedContentCard: View {
  let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      AsyncImage(url: URL(string: content.posterURL ?? "")) { image in
        image
          .resizable()
          .aspectRatio(2 / 3, contentMode: .fill)
      } placeholder: {
        Rectangle()
          .fill(Color.gray.opacity(0.3))
          .aspectRatio(2 / 3, contentMode: .fill)
      }
      .frame(width: 100, height: 150)
      .cornerRadius(8)
      .clipped()

      Text(content.title)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .lineLimit(2)
        .frame(width: 100, alignment: .leading)
    }
  }
}

struct SimpleVideoPlayerView: View {
  let content: Content
  @SwiftUI.Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack {
        HStack {
          Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "xmark")
              .font(.title2)
              .foregroundColor(.white)
          }

          Spacer()

          Text(content.title)
            .font(.headline)
            .foregroundColor(.white)

          Spacer()

          Button(action: {}) {
            Image(systemName: "ellipsis")
              .font(.title2)
              .foregroundColor(.white)
          }
        }
        .padding()

        Spacer()

        // Video Player Placeholder
        Rectangle()
          .fill(Color.gray.opacity(0.3))
          .aspectRatio(16 / 9, contentMode: .fit)
          .overlay(
            VStack {
              Image(systemName: "play.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)

              Text("Video Player")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.top, 16)
            }
          )

        Spacer()

        // Player Controls
        HStack {
          Button(action: {}) {
            Image(systemName: "backward.fill")
              .font(.title)
              .foregroundColor(.white)
          }

          Spacer()

          Button(action: {}) {
            Image(systemName: "play.fill")
              .font(.system(size: 40))
              .foregroundColor(.white)
          }

          Spacer()

          Button(action: {}) {
            Image(systemName: "forward.fill")
              .font(.title)
              .foregroundColor(.white)
          }
        }
        .padding(.horizontal, 60)
        .padding(.bottom, 40)
      }
    }
  }
}

#Preview {
  ContentDetailView(content: MockData.sampleMovies.first!)
    .preferredColorScheme(ColorScheme.dark)
}
