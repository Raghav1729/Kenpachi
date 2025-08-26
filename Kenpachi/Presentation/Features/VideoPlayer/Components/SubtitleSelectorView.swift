import SwiftUI

struct SubtitleSelectorView: View {
    let subtitles: [SubtitleTrack]
    let selectedSubtitle: SubtitleTrack?
    let onSubtitleSelected: (SubtitleTrack?) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Subtitle selector panel
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Subtitles & Audio")
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
                
                // Subtitle options
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(subtitles, id: \.id) { subtitle in
                            SubtitleOptionRow(
                                subtitle: subtitle,
                                isSelected: subtitle.id == selectedSubtitle?.id,
                                onTap: {
                                    let selectedTrack = subtitle.id == "off" ? nil : subtitle
                                    onSubtitleSelected(selectedTrack)
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

struct SubtitleOptionRow: View {
    let subtitle: SubtitleTrack
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subtitle.label)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.white)
                    
                    if subtitle.id != "off" {
                        Text(subtitle.language)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                
                // Language flag or icon
                SubtitleIcon(subtitle: subtitle)
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

struct SubtitleIcon: View {
    let subtitle: SubtitleTrack
    
    var body: some View {
        if subtitle.id == "off" {
            Image(systemName: "textformat.alt")
                .font(.body)
                .foregroundColor(.gray)
        } else {
            Text(subtitle.language.prefix(2).uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 16)
                .background(Color.blue.opacity(0.7))
                .cornerRadius(3)
        }
    }
}

#Preview {
    SubtitleSelectorView(
        subtitles: SubtitleTrack.sampleTracks,
        selectedSubtitle: SubtitleTrack.sampleTracks.first,
        onSubtitleSelected: { _ in },
        onDismiss: { }
    )
}