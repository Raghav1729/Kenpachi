import SwiftUI

struct QualitySelectorView: View {
    let sources: [VideoSource]
    let selectedSource: VideoSource?
    let onSourceSelected: (VideoSource) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Quality selector panel
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Video Quality")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.9))
                
                // Quality options
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sources, id: \.id) { source in
                            QualityOptionRow(
                                source: source,
                                isSelected: source.id == selectedSource?.id,
                                onTap: {
                                    onSourceSelected(source)
                                }
                            )
                        }
                    }
                }
                .background(Color.black.opacity(0.8))
            }
            .frame(maxWidth: 300)
            .cornerRadius(12)
            .shadow(radius: 20)
        }
    }
}

struct QualityOptionRow: View {
    let source: VideoSource
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.quality.displayName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.white)
                    
                    Text(source.server)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                
                // Quality badge
                QualityBadge(quality: source.quality)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isSelected ? Color.blue.opacity(0.2) : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QualityBadge: View {
    let quality: StreamingQuality
    
    var badgeColor: Color {
        switch quality {
        case .uhd4k, .uhd8k:
            return .purple
        case .hd1080:
            return .blue
        case .hd720:
            return .green
        case .sd480, .sd360:
            return .orange
        case .auto:
            return .gray
        }
    }
    
    var body: some View {
        Text(quality.shortName)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor)
            .cornerRadius(4)
    }
}

extension StreamingQuality {
    var shortName: String {
        switch self {
        case .uhd4k:
            return "4K"
        case .uhd8k:
            return "8K"
        case .hd1080:
            return "HD"
        case .hd720:
            return "720p"
        case .sd480:
            return "480p"
        case .sd360:
            return "360p"
        case .auto:
            return "AUTO"
        }
    }
}

#Preview {
    QualitySelectorView(
        sources: [
            VideoSource(id: "1", url: "test1.mp4", quality: .uhd4k, type: .mp4, server: "Primary", isM3U8: false, headers: nil),
            VideoSource(id: "2", url: "test2.mp4", quality: .hd1080, type: .mp4, server: "Primary", isM3U8: false, headers: nil),
            VideoSource(id: "3", url: "test3.mp4", quality: .hd720, type: .mp4, server: "Backup", isM3U8: false, headers: nil),
            VideoSource(id: "4", url: "test4.mp4", quality: .sd480, type: .mp4, server: "Mobile", isM3U8: false, headers: nil)
        ],
        selectedSource: VideoSource(id: "2", url: "test2.mp4", quality: .hd1080, type: .mp4, server: "Primary", isM3U8: false, headers: nil),
        onSourceSelected: { _ in },
        onDismiss: { }
    )
}