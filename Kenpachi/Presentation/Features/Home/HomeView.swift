import SwiftUI
import ComposableArchitecture

struct HomeView: View {
    @State private var selectedContent: Content?
    @State private var selectedCategory: CategoryItem?
    @State private var selectedBrand: DisneyBrand?
    @State private var showingPlayer = false
    @State private var playerContent: Content?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 32) {
                    // Hero Section
                    HeroCard(
                        content: MockData.getHeroContent(),
                        onPlay: {
                            playerContent = MockData.getHeroContent()
                            showingPlayer = true
                        },
                        onAddToWatchlist: {
                            // TODO: Implement watchlist
                            print("Added to watchlist: \(MockData.getHeroContent().title)")
                        }
                    )
                    .padding(.horizontal, AppTheme.current.spacing.screenPadding)
                    
                    // Disney Brand Section
                    DisneyBrandSection { brand in
                        selectedBrand = brand
                        print("Selected brand: \(brand.displayName)")
                    }
                    
                    // Continue Watching Section
                    if !MockData.getContinueWatching().isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Continue Watching")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(MockData.getContinueWatching()) { content in
                                        ContinueWatchingCard(
                                            content: content,
                                            progress: Double.random(in: 0.1...0.8)
                                        ) {
                                            playerContent = content
                                            showingPlayer = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    
                    // Enhanced Content Sections
                    RecommendationSection(
                        title: "Trending Now",
                        subtitle: "Popular on Disney+",
                        content: MockData.sampleMovies,
                        onContentTap: { content in
                            selectedContent = content
                        },
                        onSeeAll: {
                            print("See all trending")
                        }
                    )
                    
                    RecommendationSection(
                        title: "Disney Originals",
                        subtitle: "Exclusive Disney+ content",
                        content: MockData.sampleTVShows,
                        onContentTap: { content in
                            selectedContent = content
                        }
                    )
                    
                    RecommendationSection(
                        title: "Marvel Movies",
                        subtitle: "Superhero adventures",
                        content: MockData.sampleMovies.shuffled(),
                        onContentTap: { content in
                            selectedContent = content
                        }
                    )
                    
                    RecommendationSection(
                        title: "Star Wars Collection",
                        subtitle: "A galaxy far, far away",
                        content: MockData.sampleTVShows.shuffled(),
                        onContentTap: { content in
                            selectedContent = content
                        }
                    )
                    
                    RecommendationSection(
                        title: "Pixar Favorites",
                        subtitle: "Animated classics",
                        content: MockData.sampleMovies.shuffled(),
                        onContentTap: { content in
                            selectedContent = content
                        }
                    )
                    
                    // Bottom spacing for tab bar
                    Spacer(minLength: 100)
                }
            }
            .background(AppTheme.current.colors.background)
            .navigationBarHidden(true)
        }
        .sheet(item: $selectedContent) { content in
            ContentDetailView(content: content)
        }
        .sheet(item: $selectedCategory) { category in
            CategoryDetailView(category: category)
        }
        .fullScreenCover(isPresented: $showingPlayer) {
            if let content = playerContent {
                EnhancedVideoPlayerView(content: content)
            }
        }
    }
}







#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}