import SwiftUI

struct Typography {
    // Display Styles
    let displayLarge = Font.system(size: 57, weight: .regular)
    let displayMedium = Font.system(size: 45, weight: .regular)
    let displaySmall = Font.system(size: 36, weight: .regular)
    
    // Headline Styles
    let headlineLarge = Font.system(size: 32, weight: .regular)
    let headlineMedium = Font.system(size: 28, weight: .regular)
    let headlineSmall = Font.system(size: 24, weight: .regular)
    
    // Title Styles
    let titleLarge = Font.system(size: 22, weight: .regular)
    let titleMedium = Font.system(size: 16, weight: .medium)
    let titleSmall = Font.system(size: 14, weight: .medium)
    
    // Label Styles
    let labelLarge = Font.system(size: 14, weight: .medium)
    let labelMedium = Font.system(size: 12, weight: .medium)
    let labelSmall = Font.system(size: 11, weight: .medium)
    
    // Body Styles
    let bodyLarge = Font.system(size: 16, weight: .regular)
    let bodyMedium = Font.system(size: 14, weight: .regular)
    let bodySmall = Font.system(size: 12, weight: .regular)
    
    // Custom App Styles
    let heroTitle = Font.system(size: 34, weight: .bold)
    let cardTitle = Font.system(size: 16, weight: .semibold)
    let cardSubtitle = Font.system(size: 14, weight: .regular)
    let caption = Font.system(size: 12, weight: .regular)
    let captionSmall = Font.system(size: 10, weight: .regular)
    let overline = Font.system(size: 10, weight: .medium)
}