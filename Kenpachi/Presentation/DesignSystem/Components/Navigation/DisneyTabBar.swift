import SwiftUI

struct DisneyTabBar: View {
    @Binding var selectedTab: AppFeature.State.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppFeature.State.Tab.allCases, id: \.self) { tab in
                DisneyTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            ZStack {
                // Background blur effect
                Color.black.opacity(0.9)
                
                // Subtle gradient
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct DisneyTabItem: View {
    let tab: AppFeature.State.Tab
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    // Selection indicator
                    if isSelected {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)
                    }
                    
                    Image(systemName: isSelected ? tab.selectedIcon : tab.systemImage)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                
                Text(tab.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

extension AppFeature.State.Tab {
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .downloads: return "arrow.down.circle.fill"
        case .profile: return "person.fill"
        }
    }
}

#Preview {
    VStack {
        Spacer()
        
        DisneyTabBar(selectedTab: .constant(.home))
    }
    .background(Color.black)
}