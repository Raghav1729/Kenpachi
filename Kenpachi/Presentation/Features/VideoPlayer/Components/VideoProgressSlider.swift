import SwiftUI

struct VideoProgressSlider: View {
    @Binding var currentTime: Double
    @Binding var duration: Double
    let onSeek: (Double) -> Void
    
    @State private var isDragging = false
    @State private var dragValue: Double = 0
    @State private var previewTime: Double = 0
    @State private var showPreview = false
    
    private var progress: Double {
        guard duration > 0 else { return 0 }
        return isDragging ? dragValue : currentTime / duration
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress Bar with Preview
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    // Buffered progress (simulated)
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: geometry.size.width * min(progress + 0.1, 1.0), height: 4)
                    
                    // Watched progress
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 4)
                    
                    // Scrubber thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: isDragging ? 16 : 12, height: isDragging ? 16 : 12)
                        .offset(x: geometry.size.width * progress - (isDragging ? 8 : 6))
                        .animation(.easeInOut(duration: 0.1), value: isDragging)
                    
                    // Preview thumbnail (placeholder)
                    if showPreview && isDragging {
                        PreviewThumbnail(
                            time: previewTime,
                            position: geometry.size.width * dragValue
                        )
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                showPreview = true
                            }
                            
                            let newProgress = min(max(0, value.location.x / geometry.size.width), 1)
                            dragValue = newProgress
                            previewTime = newProgress * duration
                        }
                        .onEnded { value in
                            isDragging = false
                            showPreview = false
                            
                            let seekTime = dragValue * duration
                            onSeek(seekTime)
                        }
                )
            }
            .frame(height: 20)
            
            // Time labels
            HStack {
                Text(formatTime(isDragging ? dragValue * duration : currentTime))
                    .font(.caption)
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                Spacer()
                
                Text("-\(formatTime(duration - (isDragging ? dragValue * duration : currentTime)))")
                    .font(.caption)
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        guard !time.isNaN && !time.isInfinite && time >= 0 else { return "0:00" }
        
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

struct PreviewThumbnail: View {
    let time: Double
    let position: CGFloat
    
    var body: some View {
        VStack(spacing: 4) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.8))
                .frame(width: 120, height: 68)
                .overlay(
                    VStack {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text(formatPreviewTime(time))
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                )
            
            // Time indicator
            Text(formatPreviewTime(time))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.8))
                .cornerRadius(4)
        }
        .offset(x: position - 60, y: -90) // Center the preview above the scrubber
    }
    
    private func formatPreviewTime(_ time: Double) -> String {
        guard !time.isNaN && !time.isInfinite && time >= 0 else { return "0:00" }
        
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        VideoProgressSlider(
            currentTime: .constant(1800), // 30 minutes
            duration: .constant(5400),    // 90 minutes
            onSeek: { time in
                print("Seeking to: \(time)")
            }
        )
        .padding()
    }
}