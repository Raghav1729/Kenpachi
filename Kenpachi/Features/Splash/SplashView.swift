//
//  SplashView.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

import ComposableArchitecture
import SwiftUI

// MARK: - SplashView
struct SplashView: View {
    let store: StoreOf<SplashFeature>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                // Changed background color
                Constants.Theme.backgroundColor.edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()
                    Image(systemName: "sparkles.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        // Changed accent color
                        .foregroundColor(Constants.Theme.accentColor)
                        .shadow(radius: 10)

                    Text(Constants.appName)
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        // Changed text color
                        .foregroundColor(Constants.Theme.primaryTextColor)
                        .padding(.top, 10)
                    Spacer()
                    ProgressView()
                        // Changed tint color
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Theme.accentColor))
                        .scaleEffect(1.5)
                        .padding(.bottom, 50)
                }
            }
            .opacity(viewStore.isLoading ? 1 : 0)
            .animation(.easeOut(duration: 0.5), value: viewStore.isLoading)
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}


// MARK: - Previews
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(
            store: Store(initialState: SplashFeature.State()) {
                SplashFeature()
                    ._printChanges() // Helpful for debugging TCA states in previews
            }
        )
    }
}
