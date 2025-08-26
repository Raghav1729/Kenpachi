import SwiftUI

struct CategoryDetailView: View {
    let category: CategoryItem
    @SwiftUI.Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var selectedContent: Content?
    @State private var searchText = ""
    
    var filteredContent: [Content] {
        let allContent = MockData.sampleMovies + MockData.sampleTVShows
        
        var filtered = allContent
        
        // Filter by content type if specified
        if let contentType = category.contentType {
            filtered = filtered.filter { $0.contentType == contentType }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.overview.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(AppTheme.current.colors.textPrimary)
                        }
                        
                        Spacer()
                        
                        Text(category.name)
                            .font(AppTheme.current.typography.titleLarge)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.current.colors.textPrimary)
                        
                        Spacer()
                        
                        // Placeholder for balance
                        Color.clear
                            .frame(width: 24, height: 24)
                    }
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.current.colors.textSecondary)
                        
                        TextField("Search \(category.name)...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(AppTheme.current.colors.textPrimary)
                    }
                    .padding()
                    .background(AppTheme.current.colors.surface)
                    .cornerRadius(AppTheme.current.cornerRadius.medium)
                }
                .padding(AppTheme.current.spacing.screenPadding)
                .background(AppTheme.current.colors.background)
                
                // Content Grid
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 16
                    ) {
                        ForEach(filteredContent) { content in
                            ContentGridItem(content: content) {
                                selectedContent = content
                            }
                        }
                    }
                    .padding(AppTheme.current.spacing.screenPadding)
                }
                .background(AppTheme.current.colors.background)
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $selectedContent) { content in
            ContentDetailView(content: content)
        }
    }
}

struct ContentGridItem: View {
    let content: Content
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Poster Image
                AsyncImage(url: URL(string: content.posterURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(AppTheme.current.colors.surface)
                        .aspectRatio(2/3, contentMode: .fit)
                        .overlay(
                            ProgressView()
                                .tint(AppTheme.current.colors.accent)
                        )
                }
                .cornerRadius(AppTheme.current.cornerRadius.medium)
                .clipped()
                
                // Title
                Text(content.title)
                    .font(AppTheme.current.typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.current.colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    
                    Text(String(format: "%.1f", content.rating))
                        .font(AppTheme.current.typography.labelSmall)
                        .foregroundColor(AppTheme.current.colors.textSecondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CategoryDetailView(category: CategoryItem.disneyCategories.first!)
        .preferredColorScheme(.dark)
}