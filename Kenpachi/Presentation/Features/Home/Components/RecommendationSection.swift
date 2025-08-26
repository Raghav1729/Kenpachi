import SwiftUI

struct RecommendationSection: View {
    let title: String
    let subtitle: String?
    let content: [Content]
    let onContentTap: (Content) -> Void
    let onSeeAll: (() -> Void)?
    
    init(
        title: String,
        subtitle: String? = nil,
        content: [Content],
        onContentTap: @escaping (Content) -> Void,
        onSeeAll: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.onContentTap = onContentTap
        self.onSeeAll = onSeeAll
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if let onSeeAll = onSeeAll {
                    Button(action: onSeeAll) {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Content Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(content) { item in
                        RecommendationCard(content: item) {
                            onContentTap(item)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct RecommendationCard: View {
    let content: Content
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Poster Image
                ZStack {
                    AsyncImage(url: URL(string: content.posterURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(2/3, contentMode: .fill)
                    }
                    .frame(width: 140)
                    .cornerRadius(8)
                    .clipped()
                    
                    // Hover overlay
                    if isHovered {
                        Color.black.opacity(0.3)
                            .cornerRadius(8)
                        
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            Text("Play")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Content Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        if content.rating > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                                
                                Text(String(format: "%.1f", content.rating))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        if let releaseDate = content.releaseDate {
                            let year = Calendar.current.component(.year, from: releaseDate)
                            Text(String(year))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if !content.genres.isEmpty {
                        Text(content.genres.prefix(2).map { $0.name }.joined(separator: " • "))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: 140)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

struct ContinueWatchingCard: View {
    let content: Content
    let progress: Double // 0.0 to 1.0
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Backdrop Image with Progress
                ZStack(alignment: .bottom) {
                    AsyncImage(url: URL(string: content.backdropURL ?? content.posterURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                    }
                    .frame(width: 200)
                    .cornerRadius(8)
                    .clipped()
                    
                    // Play overlay
                    Color.black.opacity(0.4)
                        .cornerRadius(8)
                    
                    VStack {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        
                        Text("Continue")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    // Progress Bar
                    VStack {
                        Spacer()
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 3)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * progress, height: 3)
                            }
                        }
                        .frame(height: 3)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                }
                
                // Content Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(Int(progress * 100))% watched")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 200)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.black
        
        ScrollView {
            VStack(spacing: 32) {
                RecommendationSection(
                    title: "Trending Now",
                    subtitle: "Popular on Disney+",
                    content: MockData.sampleMovies,
                    onContentTap: { _ in },
                    onSeeAll: { }
                )
                
                RecommendationSection(
                    title: "Continue Watching",
                    content: MockData.sampleMovies,
                    onContentTap: { _ in }
                )
            }
        }
    }
}