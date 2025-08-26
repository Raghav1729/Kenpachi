import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: AppFeature.State.Tab
    let tabs = AppFeature.State.Tab.allCases
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal, AppTheme.current.spacing.md)
        .padding(.vertical, AppTheme.current.spacing.sm)
        .background(
            Rectangle()
                .fill(AppTheme.current.colors.surface)
                .shadow(
                    color: AppTheme.current.colors.overlay,
                    radius: 8,
                    y: -2
                )
        )
    }
}

struct TabBarItem: View {
    let tab: AppFeature.State.Tab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppTheme.current.colors.accent : AppTheme.current.colors.textSecondary)
                
                Text(tab.rawValue)
                    .font(AppTheme.current.typography.labelSmall)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? AppTheme.current.colors.accent : AppTheme.current.colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.current.spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(.home))
        .preferredColorScheme(.dark)
}