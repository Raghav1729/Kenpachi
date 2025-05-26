//
//  SplashFeature.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

import ComposableArchitecture
import SwiftUI

// MARK: - SplashFeature Reducer

struct SplashFeature: Reducer {

    struct State: Equatable {
        var isLoading: Bool = true // Indicates if the splash animation is running
    }

    enum Action: Equatable {
        case onAppear
        case splashTimerDone
    }

    @Dependency(\.continuousClock) var clock // For timing the splash screen

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                LogPageOpened("Splash Screen")
                // Start a timer for the splash screen duration
                return .run { send in
                    try await self.clock.sleep(for: .seconds(Constants.splashScreenDuration))
                    await send(.splashTimerDone)
                }
            case .splashTimerDone:
                state.isLoading = false // Mark splash as complete
                LogInfo("Splash screen timer completed.")
                return .none
            }
        }
    }
}

