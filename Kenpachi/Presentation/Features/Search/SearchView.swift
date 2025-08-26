import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [Content] = []
    @State private var isSearching = false
    @State private var recentSearches = ["Avatar", "Marvel", "Star Wars", "Disney"]
    @State private var selectedContent: Content?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText, onSearchButtonClicked: performSearch)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                if searchText.isEmpty {
                    // Recent Searches and Suggestions
                    RecentSearchesView(
                        recentSearches: recentSearches,
                        onSearchTapped: { query in
                            searchText = query
                            performSearch()
                        }
                    )
                } else if isSearching {
                    // Loading State
                    LoadingView()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    // No Results
                    NoResultsView(query: searchText)
                } else {
                    // Search Results
                    SearchResultsView(
                        results: searchResults,
                        onContentTapped: { content in
                            selectedContent = content
                        }
                    )
                }
                
                Spacer()
            }
            .background(Color.black)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
        .sheet(item: $selectedContent) { content in
            ContentDetailView(content: content)
        }
        .onChange(of: searchText) { newValue in
            if newValue.isEmpty {
                searchResults = []
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        
        // Simulate search delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Simple mock search
            let allContent = MockData.sampleMovies + MockData.sampleTVShows + MockData.sampleAnime
            searchResults = allContent.filter { content in
                content.title.localizedCaseInsensitiveContains(searchText) ||
                content.overview.localizedCaseInsensitiveContains(searchText)
            }
            isSearching = false
            
            // Add to recent searches if not already there
            if !recentSearches.contains(searchText) {
                recentSearches.insert(searchText, at: 0)
                if recentSearches.count > 10 {
                    recentSearches.removeLast()
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search movies, shows, and more...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct RecentSearchesView: View {
    let recentSearches: [String]
    let onSearchTapped: (String) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Searches")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        ForEach(recentSearches, id: \.self) { search in
                            Button(action: {
                                onSearchTapped(search)
                            }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.gray)
                                    
                                    Text(search)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                
                // Popular Searches
                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular Searches")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    let popularSearches = ["Marvel", "Disney", "Star Wars", "Pixar", "National Geographic"]
                    ForEach(popularSearches, id: \.self) { search in
                        Button(action: {
                            onSearchTapped(search)
                        }) {
                            HStack {
                                Image(systemName: "flame")
                                    .foregroundColor(.orange)
                                
                                Text(search)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding(.top, 20)
        }
    }
}

struct SearchResultsView: View {
    let results: [Content]
    let onContentTapped: (Content) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                Text("\(results.count) Results")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                
                ForEach(results) { content in
                    SearchResultCard(content: content) {
                        onContentTapped(content)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 20)
        }
    }
}

struct SearchResultCard: View {
    let content: Content
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Poster
                AsyncImage(url: URL(string: content.posterURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(2/3, contentMode: .fill)
                }
                .frame(width: 80, height: 120)
                .cornerRadius(8)
                .clipped()
                
                // Content Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(content.contentType.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(content.overview)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(String(format: "%.1f", content.rating))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            Text("Searching...")
                .foregroundColor(.gray)
                .padding(.top, 16)
            Spacer()
        }
    }
}

struct NoResultsView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No results for \"\(query)\"")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Try searching for something else")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}

#Preview {
    SearchView()
        .preferredColorScheme(.dark)
}