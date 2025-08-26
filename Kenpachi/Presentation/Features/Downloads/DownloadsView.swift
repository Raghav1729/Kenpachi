import SwiftUI

struct DownloadsView: View {
    @State private var downloads: [DownloadItem] = [
        DownloadItem.sample,
        DownloadItem(
            id: "download_2",
            contentId: "2",
            contentType: .movie,
            title: "Black Panther: Wakanda Forever",
            posterURL: "https://image.tmdb.org/t/p/w500/sv1xJUazXeYqALzczSZ3O6nkH75.jpg",
            episodeId: nil,
            seasonNumber: nil,
            episodeNumber: nil,
            quality: .hd720,
            fileSize: 3221225472, // 3GB
            downloadedSize: 3221225472, // Completed
            status: .completed,
            progress: DownloadProgress.completed,
            createdAt: Date().addingTimeInterval(-86400), // 1 day ago
            startedAt: Date().addingTimeInterval(-86400),
            completedAt: Date().addingTimeInterval(-82800), // 1 hour to download
            expiresAt: Date().addingTimeInterval(86400 * 29), // 29 days from now
            localPath: "/downloads/black_panther_2.mp4",
            streamingSource: nil,
            subtitles: [],
            error: nil
        )
    ]
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segment Control
                Picker("Downloads", selection: $selectedSegment) {
                    Text("Downloaded").tag(0)
                    Text("Downloading").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                if filteredDownloads.isEmpty {
                    EmptyDownloadsView(isDownloading: selectedSegment == 1)
                } else {
                    // Downloads List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredDownloads) { download in
                                DownloadCard(download: download) {
                                    // Handle download action (play, pause, resume, etc.)
                                    handleDownloadAction(download)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 16)
                    }
                }
                
                Spacer()
            }
            .background(Color.black)
            .navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        // Handle settings
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var filteredDownloads: [DownloadItem] {
        switch selectedSegment {
        case 0: // Downloaded
            return downloads.filter { $0.status == .completed }
        case 1: // Downloading
            return downloads.filter { $0.status == .downloading || $0.status == .queued || $0.status == .paused }
        default:
            return downloads
        }
    }
    
    private func handleDownloadAction(_ download: DownloadItem) {
        switch download.status {
        case .completed:
            // Play the downloaded content
            print("Playing: \(download.title)")
        case .downloading:
            // Pause download
            pauseDownload(download)
        case .paused, .failed:
            // Resume download
            resumeDownload(download)
        case .queued:
            // Cancel download
            cancelDownload(download)
        default:
            break
        }
    }
    
    private func pauseDownload(_ download: DownloadItem) {
        if let index = downloads.firstIndex(where: { $0.id == download.id }) {
            downloads[index] = DownloadItem(
                id: download.id,
                contentId: download.contentId,
                contentType: download.contentType,
                title: download.title,
                posterURL: download.posterURL,
                episodeId: download.episodeId,
                seasonNumber: download.seasonNumber,
                episodeNumber: download.episodeNumber,
                quality: download.quality,
                fileSize: download.fileSize,
                downloadedSize: download.downloadedSize,
                status: .paused,
                progress: download.progress,
                createdAt: download.createdAt,
                startedAt: download.startedAt,
                completedAt: download.completedAt,
                expiresAt: download.expiresAt,
                localPath: download.localPath,
                streamingSource: download.streamingSource,
                subtitles: download.subtitles,
                error: download.error
            )
        }
    }
    
    private func resumeDownload(_ download: DownloadItem) {
        if let index = downloads.firstIndex(where: { $0.id == download.id }) {
            downloads[index] = DownloadItem(
                id: download.id,
                contentId: download.contentId,
                contentType: download.contentType,
                title: download.title,
                posterURL: download.posterURL,
                episodeId: download.episodeId,
                seasonNumber: download.seasonNumber,
                episodeNumber: download.episodeNumber,
                quality: download.quality,
                fileSize: download.fileSize,
                downloadedSize: download.downloadedSize,
                status: .downloading,
                progress: download.progress,
                createdAt: download.createdAt,
                startedAt: download.startedAt,
                completedAt: download.completedAt,
                expiresAt: download.expiresAt,
                localPath: download.localPath,
                streamingSource: download.streamingSource,
                subtitles: download.subtitles,
                error: download.error
            )
        }
    }
    
    private func cancelDownload(_ download: DownloadItem) {
        downloads.removeAll { $0.id == download.id }
    }
}

struct DownloadCard: View {
    let download: DownloadItem
    let onAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Poster
            AsyncImage(url: URL(string: download.posterURL ?? "")) { image in
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
                Text(download.displayTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(download.quality.displayName)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if download.status == .completed {
                    HStack {
                        Text(download.formattedFileSize)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let days = download.daysUntilExpiry {
                            Text("• Expires in \(days) days")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                } else {
                    // Progress Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(download.progress.progressText)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let speed = download.progress.formattedDownloadSpeed {
                            Text(speed)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        // Progress Bar
                        ProgressView(value: download.progressPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(height: 4)
                    }
                }
                
                Spacer()
            }
            
            Spacer()
            
            // Action Button
            Button(action: onAction) {
                Image(systemName: actionButtonIcon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionButtonIcon: String {
        switch download.status {
        case .completed:
            return "play.fill"
        case .downloading:
            return "pause.fill"
        case .paused, .failed:
            return "play.fill"
        case .queued:
            return "xmark"
        case .cancelled, .expired:
            return "arrow.clockwise"
        }
    }
}

struct EmptyDownloadsView: View {
    let isDownloading: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: isDownloading ? "arrow.down.circle" : "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(isDownloading ? "No active downloads" : "No downloads")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(isDownloading ? 
                 "Downloads will appear here when you start downloading content" :
                 "Download movies and shows to watch offline")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

#Preview {
    DownloadsView()
        .preferredColorScheme(.dark)
}