import SwiftUI
import ComposableArchitecture

@main
struct KenpachiApp: App {
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: store)
                .preferredColorScheme(.dark) // Disney Plus uses dark theme
        }
    }
}

struct AppFeature: Reducer {
    struct State: Equatable {
        var selectedTab: Tab = .home
        
        enum Tab: String, CaseIterable {
            case home = "Home"
            case search = "Search"
            case downloads = "Downloads"
            case profile = "Profile"
            
            var systemImage: String {
                switch self {
                case .home: return "house.fill"
                case .search: return "magnifyingglass"
                case .downloads: return "arrow.down.circle.fill"
                case .profile: return "person.fill"
                }
            }
        }
    }
    
    enum Action {
        case tabSelected(State.Tab)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none
            }
        }
    }
}

struct AppView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            MainTabView(store: store)
        }
    }
}