//
//  KenpachiApp.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

import SwiftUI
import ComposableArchitecture

@main
struct KenpachiApp: App {
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
            ._printChanges()
    }

    var body: some Scene {
        WindowGroup {
            WithViewStore(KenpachiApp.store, observe: { $0 }) { viewStore in
                ZStack {
                    if viewStore.hasShownSplash {
                        MainTabView(
                            store: KenpachiApp.store.scope(
                                state: \.mainTab!,
                                action: AppFeature.Action.mainTab
                            )
                        )
                    } else {
                        // Changed background color
                        Constants.Theme.backgroundColor.edgesIgnoringSafeArea(.all)
                    }

                    if !viewStore.hasShownSplash {
                        SplashView(
                            store: KenpachiApp.store.scope(
                                state: \.splash,
                                action: AppFeature.Action.splash
                            )
                        )
                        .transition(.opacity)
                    }
                }
                .onAppear {
                    viewStore.send(.appDidFinishLaunching)
                }
            }
        }
    }
}
