import SwiftUI

struct ContentSection: View {
    let title: String
    let content: [Content]
    let onContentTap: (Content) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text(title)
                    .font(AppTheme.current.typography.titleLarge)
                    .foregroundColor(AppTheme.current.colors.textPrimary)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to see all
                }
                .font(AppTheme.current.typography.labelMedium)
                .foregroundColor(AppTheme.current.colors.accent)
            }
            .padding(.horizontal, AppTheme.current.spacing.screenPadding)
            
            // Content Row
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(content.enumerated()), id: \.offset) { index, item in
                        ContentCard(content: item) {
                            onContentTap(item)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.current.spacing.screenPadding)
            }
        }
    }
}