import SwiftUI

struct CategoryCard: View {
    let title: String
    let imageName: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: AppTheme.current.cornerRadius.medium)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.current.colors.accent.opacity(0.8),
                                AppTheme.current.colors.accent.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                
                // Content
                VStack(spacing: 8) {
                    Image(systemName: imageName)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(AppTheme.current.typography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryRow: View {
    let categories: [CategoryItem]
    let onCategoryTap: (CategoryItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Browse by Category")
                .font(AppTheme.current.typography.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.current.colors.textPrimary)
                .padding(.horizontal, AppTheme.current.spacing.screenPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(categories) { category in
                        CategoryCard(
                            title: category.name,
                            imageName: category.iconName
                        ) {
                            onCategoryTap(category)
                        }
                        .frame(width: 160)
                    }
                }
                .padding(.horizontal, AppTheme.current.spacing.screenPadding)
            }
        }
    }
}

struct CategoryItem: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let contentType: ContentType?
    
    static let disneyCategories: [CategoryItem] = [
        CategoryItem(name: "Disney", iconName: "sparkles", contentType: nil),
        CategoryItem(name: "Pixar", iconName: "cube.fill", contentType: nil),
        CategoryItem(name: "Marvel", iconName: "shield.fill", contentType: nil),
        CategoryItem(name: "Star Wars", iconName: "star.fill", contentType: nil),
        CategoryItem(name: "National Geographic", iconName: "globe.americas.fill", contentType: nil),
        CategoryItem(name: "Movies", iconName: "film.fill", contentType: .movie),
        CategoryItem(name: "Series", iconName: "tv.fill", contentType: .tvShow),
        CategoryItem(name: "Documentaries", iconName: "doc.fill", contentType: nil)
    ]
}

#Preview {
    CategoryRow(
        categories: CategoryItem.disneyCategories,
        onCategoryTap: { _ in }
    )
    .preferredColorScheme(.dark)
    .background(Color.black)
}