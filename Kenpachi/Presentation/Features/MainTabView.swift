import SwiftUI
import ComposableArchitecture

struct MainTabView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack(alignment: .bottom) {
                // Content based on selected tab
                Group {
                    switch viewStore.selectedTab {
                    case .home:
                        HomeView()
                    case .search:
                        SearchView()
                    case .downloads:
                        DownloadsView()
                    case .profile:
                        ProfileView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom Disney Tab Bar
                DisneyTabBar(
                    selectedTab: viewStore.binding(
                        get: \.selectedTab,
                        send: AppFeature.Action.tabSelected
                    )
                )
            }
            .background(Color.black)
            .preferredColorScheme(.dark)
        }
    }
}