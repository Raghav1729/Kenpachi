//
//  KenpachiApp.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

import SwiftUI
import ComposableArchitecture // Import TCA

@main
struct KenpachiApp: App {
    var body: some Scene {
        WindowGroup {
            // Placeholder content for now.
            // In the next step, this will be replaced by our root TCA store,
            // starting with the SplashFeature.
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all) // Simulate a dark background
                Text("Hello, Kenpachi!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}
