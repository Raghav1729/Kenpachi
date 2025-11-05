// OfflineLibraryView.swift
// Comprehensive offline library view for downloaded content
// Provides filtering, sorting, and organization features

import SwiftUI

/// Comprehensive offline library view
struct OfflineLibraryView: View {
  /// List of downloads
  let downloads: [Download]
  /// Callback when content is tapped
  let onContentTapped: (Download) -> Void
  /// Callback when content is deleted
  let onContentDeleted: (Download) -> Void
  /// Callback when content is converted
  let onContentConverted: (Download) -> Void
  /// Current conversion progress
  let conversionProgress: [String: Double]
  
  /// Current filter
  @State private var selectedFilter: ContentFilter = .all
  /// Current sort option
  @State private var selectedSort: SortOption = .dateAdded
  /// Search text
  @State private var searchText = ""
  /// Show filter options
  @State private var showFilters = false
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Search and filter bar
        searchAndFilterBar
        
        // Content grid
        if filteredDownloads.isEmpty {
          emptyStateView
        } else {
          contentGrid
        }
      }
      .navigationTitle("Offline Library")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { showFilters.toggle() }) {
            Image(systemName: "line.3.horizontal.decrease.circle")
          }
        }
      }
      .sheet(isPresented: $showFilters) {
        FilterSheet(
          selectedFilter: $selectedFilter,
          selectedSort: $selectedSort
        )
      }
    }
  }
  
  /// Search and filter bar
  private var searchAndFilterBar: some View {
    VStack(spacing: 12) {
      // Search bar
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.textSecondary)
        
        TextField("Search downloads...", text: $searchText)
          .textFieldStyle(PlainTextFieldStyle())
        
        if !searchText.isEmpty {
          Button(action: { searchText = "" }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.textSecondary)
          }
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color.cardBackground)
      .cornerRadius(8)
      
      // Quick filter chips
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(ContentFilter.allCases, id: \.self) { filter in
            DownloadFilterChip(
              title: filter.displayName,
              isSelected: selectedFilter == filter,
              action: { selectedFilter = filter }
            )
          }
        }
        .padding(.horizontal, 16)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(Color.appBackground)
  }
  
  /// Content grid
  private var contentGrid: some View {
    ScrollView {
      LazyVGrid(columns: gridColumns, spacing: 16) {
        ForEach(filteredDownloads) { download in
          OfflineContentCard(
            download: download,
            conversionProgress: conversionProgress[download.id],
            onTap: { onContentTapped(download) },
            onDelete: { onContentDeleted(download) },
            onConvert: { onContentConverted(download) }
          )
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 8)
    }
  }
  
  /// Empty state view
  private var emptyStateView: some View {
    VStack(spacing: 20) {
      Image(systemName: "tray")
        .font(.system(size: 60))
        .foregroundColor(.textTertiary)
      
      VStack(spacing: 8) {
        Text("No Downloads Found")
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.textPrimary)
        
        Text(emptyStateMessage)
          .font(.body)
          .foregroundColor(.textSecondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  /// Grid columns
  private var gridColumns: [GridItem] {
    [
      GridItem(.flexible(), spacing: 12),
      GridItem(.flexible(), spacing: 12)
    ]
  }
  
  /// Filtered and sorted downloads
  private var filteredDownloads: [Download] {
    let completed = downloads.filter { $0.state == .completed }
    
    // Apply content filter
    let filtered = completed.filter { download in
      // Search filter
      if !searchText.isEmpty {
        let searchLower = searchText.lowercased()
        let titleMatch = download.content.title.lowercased().contains(searchLower)
        let episodeMatch = download.episode?.name.lowercased().contains(searchLower) ?? false
        if !titleMatch && !episodeMatch {
          return false
        }
      }
      
      // Content type filter
      switch selectedFilter {
      case .all:
        return true
      case .movies:
        return download.content.type == .movie
      case .tvShows:
        return download.content.type == .tvShow
      case .anime:
        return download.content.type == .anime
      case .hls:
        guard let filePath = download.localFilePath else { return false }
        return FileManager.isHLSPackage(at: filePath)
      case .mp4:
        guard let filePath = download.localFilePath else { return false }
        return !FileManager.isHLSPackage(at: filePath)
      }
    }
    
    // Apply sorting
    return filtered.sorted { first, second in
      switch selectedSort {
      case .dateAdded:
        return (first.completedAt ?? Date.distantPast) > (second.completedAt ?? Date.distantPast)
      case .title:
        return first.content.title < second.content.title
      case .fileSize:
        let firstSize = first.localFilePath.flatMap { FileManager.getFileSize(at: $0) } ?? 0
        let secondSize = second.localFilePath.flatMap { FileManager.getFileSize(at: $0) } ?? 0
        return firstSize > secondSize
      case .quality:
        let firstQuality = first.quality?.sortOrder ?? 0
        let secondQuality = second.quality?.sortOrder ?? 0
        return firstQuality > secondQuality
      }
    }
  }
  
  /// Empty state message based on current filter
  private var emptyStateMessage: String {
    if !searchText.isEmpty {
      return "No downloads match your search for '\(searchText)'"
    }
    
    switch selectedFilter {
    case .all:
      return "You haven't downloaded any content yet. Start downloading to watch offline!"
    case .movies:
      return "No downloaded movies found"
    case .tvShows:
      return "No downloaded TV shows found"
    case .anime:
      return "No downloaded anime found"
    case .hls:
      return "No HLS downloads found"
    case .mp4:
      return "No MP4 downloads found"
    }
  }
}

// MARK: - Supporting Types

/// Content filter options
enum ContentFilter: CaseIterable {
  case all
  case movies
  case tvShows
  case anime
  case hls
  case mp4
  
  var displayName: String {
    switch self {
    case .all: return "All"
    case .movies: return "Movies"
    case .tvShows: return "TV Shows"
    case .anime: return "Anime"
    case .hls: return "HLS"
    case .mp4: return "MP4"
    }
  }
}

/// Sort options
enum SortOption: CaseIterable {
  case dateAdded
  case title
  case fileSize
  case quality
  
  var displayName: String {
    switch self {
    case .dateAdded: return "Date Added"
    case .title: return "Title"
    case .fileSize: return "File Size"
    case .quality: return "Quality"
    }
  }
}

/// Download filter chip component
struct DownloadFilterChip: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(isSelected ? .white : .textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.primaryBlue : Color.cardBackground)
        .cornerRadius(16)
    }
  }
}

/// Filter sheet
struct FilterSheet: View {
  @Binding var selectedFilter: ContentFilter
  @Binding var selectedSort: SortOption
  @SwiftUI.Environment(\.dismiss) var dismiss
  
  var body: some View {
    NavigationStack {
      List {
        Section("Filter by Type") {
          ForEach(ContentFilter.allCases, id: \.self) { filter in
            HStack {
              Text(filter.displayName)
              Spacer()
              if selectedFilter == filter {
                Image(systemName: "checkmark")
                  .foregroundColor(.primaryBlue)
              }
            }
            .contentShape(Rectangle())
            .onTapGesture {
              selectedFilter = filter
            }
          }
        }
        
        Section("Sort by") {
          ForEach(SortOption.allCases, id: \.self) { sort in
            HStack {
              Text(sort.displayName)
              Spacer()
              if selectedSort == sort {
                Image(systemName: "checkmark")
                  .foregroundColor(.primaryBlue)
              }
            }
            .contentShape(Rectangle())
            .onTapGesture {
              selectedSort = sort
            }
          }
        }
      }
      .navigationTitle("Filter & Sort")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}