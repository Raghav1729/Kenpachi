import SwiftUI

struct PlayButton: View {
    let action: () -> Void
    let isLoading: Bool
    
    init(isLoading: Bool = false, action: @escaping () -> Void) {
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text("Play")
                    .font(AppTheme.current.typography.labelLarge)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(AppTheme.current.cornerRadius.button)
        }
        .disabled(isLoading)
    }
}