import SwiftUI

struct AppTheme {
    static let current = AppTheme()
    
    // Colors
    let colors = Colors()
    
    // Typography
    let typography = Typography()
    
    // Spacing
    let spacing = Spacing()
    
    // Shadows
    let shadows = Shadows()
    
    // Corner Radius
    let cornerRadius = CornerRadius()
}

struct CornerRadius {
    let small: CGFloat = 6
    let medium: CGFloat = 10
    let large: CGFloat = 16
    let extraLarge: CGFloat = 24
    let card: CGFloat = 12
    let button: CGFloat = 25 // Rounded buttons like Disney Plus
    let hero: CGFloat = 20
    let modal: CGFloat = 16
}