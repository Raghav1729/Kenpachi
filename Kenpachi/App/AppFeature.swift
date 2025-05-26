//
//  AppFeature.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

import ComposableArchitecture
import SwiftUI

struct AppFeature: Reducer {

    // MARK: - State
    struct State: Equatable {
        var splash: SplashFeature.State = SplashFeature.State()
        var mainTab: MainTabFeature.State? // nil initially, will be non-nil after splash
        var hasShownSplash: Bool = false // Controls visibility of the splash view
    }

    // MARK: - Action
    enum Action: Equatable {
        case appDidFinishLaunching // Action sent when the app launches
        case splash(SplashFeature.Action) // Actions from the SplashFeature
        case mainTab(MainTabFeature.Action) // Actions from the MainTabFeature
    }

    // MARK: - Dependencies
    @Dependency(\.mainQueue) var mainQueue // Use mainQueue for UI-related delays
    @Dependency(\.loggingService) var loggingService

    // MARK: - Reducer Body
    var body: some Reducer<State, Action> {
        Scope(state: \.splash, action: /Action.splash) {
            SplashFeature()
        }
        // Use `ifLet` for the MainTabFeature because it's optional initially
        .ifLet(\.mainTab, action: /Action.mainTab) {
            MainTabFeature()
        }

        Reduce { state, action in
            switch action {
            case .appDidFinishLaunching:
                //loggingService.logInfo("Application did finish launching.")
                // Send the onAppear action to the splash feature
                return .send(.splash(.onAppear))

            case .splash(.splashTimerDone):
                // Once the splash timer is done, initialize the main tab state
                state.mainTab = MainTabFeature.State()
                state.hasShownSplash = true // Indicate splash is complete
                //loggingService.logInfo("Transitioning from Splash to Main Tab.")
                return .none // No further effects needed immediately

            case .splash:
                // Handle any other splash-related actions if necessary
                return .none

            case .mainTab:
                // Main tab actions are handled by the scoped MainTabFeature reducer
                return .none
            }
        }
    }
}
