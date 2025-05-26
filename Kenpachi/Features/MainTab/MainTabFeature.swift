//
//  MainTabFeature.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

import ComposableArchitecture
import SwiftUI

// MARK: - Placeholder Child Features (to be implemented later)

// Define basic reducer structure for each tab
struct HomeFeature: Reducer {
    struct State: Equatable {
        var text: String = "Home Content" // Placeholder
    }
    enum Action: Equatable {
        case onAppear
    }
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                @Dependency(\.loggingService) var loggingService
                //loggingService.logPageOpened("Home Tab")
                return .none
            }
        }
    }
}

struct SearchFeature: Reducer {
    struct State: Equatable {
        var text: String = "Search Content" // Placeholder
    }
    enum Action: Equatable {
        case onAppear
    }
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                @Dependency(\.loggingService) var loggingService
                //loggingService.logPageOpened("Search Tab")
                return .none
            }
        }
    }
}

struct MySpaceFeature: Reducer {
    struct State: Equatable {
        var text: String = "MySpace Content" // Placeholder
    }
    enum Action: Equatable {
        case onAppear
    }
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                @Dependency(\.loggingService) var loggingService
                //loggingService.logPageOpened("MySpace Tab")
                return .none
            }
        }
    }
}

struct DownloadsFeature: Reducer {
    struct State: Equatable {
        var text: String = "Downloads Content" // Placeholder
    }
    enum Action: Equatable {
        case onAppear
    }
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                @Dependency(\.loggingService) var loggingService
                //loggingService.logPageOpened("Downloads Tab")
                return .none
            }
        }
    }
}


// MARK: - MainTabFeature Reducer

struct MainTabFeature: Reducer {
    enum Tab: String, CaseIterable, Identifiable {
        case home = "Home"
        case search = "Search"
        case mySpace = "MySpace" // Renamed from "Myspace" to match Swift naming conventions
        case downloads = "Downloads"

        var id: String { self.rawValue }
        var iconName: String {
            switch self {
            case .home: return "house.fill"
            case .search: return "magnifyingglass"
            case .mySpace: return "person.fill"
            case .downloads: return "arrow.down.circle.fill"
            }
        }
    }

    struct State: Equatable {
        var selectedTab: Tab = .home
        var home: HomeFeature.State = HomeFeature.State()
        var search: SearchFeature.State = SearchFeature.State()
        var mySpace: MySpaceFeature.State = MySpaceFeature.State()
        var downloads: DownloadsFeature.State = DownloadsFeature.State()
    }

    enum Action: Equatable {
        case selectTab(Tab)
        case home(HomeFeature.Action)
        case search(SearchFeature.Action)
        case mySpace(MySpaceFeature.Action)
        case downloads(DownloadsFeature.Action)
        case onAppear
    }

    @Dependency(\.loggingService) var loggingService // Inject logging

    var body: some Reducer<State, Action> {
        Scope(state: \.home, action: /Action.home) {
            HomeFeature()
        }
        Scope(state: \.search, action: /Action.search) {
            SearchFeature()
        }
        Scope(state: \.mySpace, action: /Action.mySpace) {
            MySpaceFeature()
        }
        Scope(state: \.downloads, action: /Action.downloads) {
            DownloadsFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                //loggingService.logInfo("Main Tab Bar appeared.")
                return .none
            case .selectTab(let tab):
                state.selectedTab = tab
                //loggingService.logInfo("Selected tab: \(tab.rawValue)")
                return .none
            case .home, .search, .mySpace, .downloads:
                // Child actions handled by their respective reducers via `Scope`
                return .none
            }
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    let store: StoreOf<MainTabFeature>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            TabView(selection: viewStore.binding(
                get: \.selectedTab,
                send: MainTabFeature.Action.selectTab
            )) {
                // Home Tab
                HomeView(store: store.scope(state: \.home, action: MainTabFeature.Action.home))
                    .tabItem {
                        Label(MainTabFeature.Tab.home.rawValue, systemImage: MainTabFeature.Tab.home.iconName)
                    }
                    .tag(MainTabFeature.Tab.home)

                // Search Tab
                SearchView(store: store.scope(state: \.search, action: MainTabFeature.Action.search))
                    .tabItem {
                        Label(MainTabFeature.Tab.search.rawValue, systemImage: MainTabFeature.Tab.search.iconName)
                    }
                    .tag(MainTabFeature.Tab.search)

                // MySpace Tab
                MySpaceView(store: store.scope(state: \.mySpace, action: MainTabFeature.Action.mySpace))
                    .tabItem {
                        Label(MainTabFeature.Tab.mySpace.rawValue, systemImage: MainTabFeature.Tab.mySpace.iconName)
                    }
                    .tag(MainTabFeature.Tab.mySpace)

                // Downloads Tab
                DownloadsView(store: store.scope(state: \.downloads, action: MainTabFeature.Action.downloads))
                    .tabItem {
                        Label(MainTabFeature.Tab.downloads.rawValue, systemImage: MainTabFeature.Tab.downloads.iconName)
                    }
                    .tag(MainTabFeature.Tab.downloads)
            }
            // Apply a consistent tint color to the TabView itself if needed
            .tint(Constants.Theme.accentColor) // Changes selected tab icon color
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

// MARK: - Placeholder Views for Tabs

struct HomeView: View {
    let store: StoreOf<HomeFeature>
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    // Changed background color
                    Constants.Theme.backgroundColor.edgesIgnoringSafeArea(.all)
                    Text(viewStore.text)
                        // Changed text color
                        .foregroundColor(Constants.Theme.primaryTextColor)
                        .font(.title)
                }
                .navigationTitle(MainTabFeature.Tab.home.rawValue)
                .navigationBarTitleDisplayMode(.inline) // Keep title compact
                .toolbarBackground(Constants.Theme.backgroundColor, for: .navigationBar) // Set toolbar background
                .toolbarBackground(.visible, for: .navigationBar) // Make it visible
                .toolbarColorScheme(.dark, for: .navigationBar) // Ensure text is light on dark background
                .onAppear { viewStore.send(.onAppear) }
            }
        }
    }
}

struct SearchView: View {
    let store: StoreOf<SearchFeature>
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    Constants.Theme.backgroundColor.edgesIgnoringSafeArea(.all)
                    Text(viewStore.text)
                        .foregroundColor(Constants.Theme.primaryTextColor)
                        .font(.title)
                }
                .navigationTitle(MainTabFeature.Tab.search.rawValue)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Constants.Theme.backgroundColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .onAppear { viewStore.send(.onAppear) }
            }
        }
    }
}

struct MySpaceView: View {
    let store: StoreOf<MySpaceFeature>
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    Constants.Theme.backgroundColor.edgesIgnoringSafeArea(.all)
                    Text(viewStore.text)
                        .foregroundColor(Constants.Theme.primaryTextColor)
                        .font(.title)
                }
                .navigationTitle(MainTabFeature.Tab.mySpace.rawValue)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Constants.Theme.backgroundColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .onAppear { viewStore.send(.onAppear) }
            }
        }
    }
}

struct DownloadsView: View {
    let store: StoreOf<DownloadsFeature>
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    Constants.Theme.backgroundColor.edgesIgnoringSafeArea(.all)
                    Text(viewStore.text)
                        .foregroundColor(Constants.Theme.primaryTextColor)
                        .font(.title)
                }
                .navigationTitle(MainTabFeature.Tab.downloads.rawValue)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Constants.Theme.backgroundColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .onAppear { viewStore.send(.onAppear) }
            }
        }
    }
}


// MARK: - Previews for MainTabView
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(
            store: Store(initialState: MainTabFeature.State()) {
                MainTabFeature()
                    ._printChanges()
            }
        )
    }
}
