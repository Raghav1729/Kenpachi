import SwiftUI

struct Spacing {
    // Base spacing unit (4pt)
    let unit: CGFloat = 4
    
    // Spacing Scale
    let xs: CGFloat = 4      // 1 unit
    let sm: CGFloat = 8      // 2 units
    let md: CGFloat = 16     // 4 units
    let lg: CGFloat = 24     // 6 units
    let xl: CGFloat = 32     // 8 units
    let xxl: CGFloat = 48    // 12 units
    let xxxl: CGFloat = 64   // 16 units
    
    // Semantic Spacing
    let cardPadding: CGFloat = 16
    let sectionSpacing: CGFloat = 24
    let itemSpacing: CGFloat = 12
    let buttonPadding: CGFloat = 16
    let screenPadding: CGFloat = 20
    
    // Layout Spacing
    let headerHeight: CGFloat = 60
    let tabBarHeight: CGFloat = 80
    let navigationBarHeight: CGFloat = 44
    
    // Component Spacing
    let iconSize: CGFloat = 24
    let smallIconSize: CGFloat = 16
    let largeIconSize: CGFloat = 32
    let buttonHeight: CGFloat = 48
    let textFieldHeight: CGFloat = 44
}