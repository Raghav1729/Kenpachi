import SwiftUI

struct Shadows {
    // Elevation Shadows
    let elevation1 = Shadow(
        color: Color.black.opacity(0.12),
        radius: 2,
        x: 0,
        y: 1
    )
    
    let elevation2 = Shadow(
        color: Color.black.opacity(0.16),
        radius: 4,
        x: 0,
        y: 2
    )
    
    let elevation3 = Shadow(
        color: Color.black.opacity(0.20),
        radius: 8,
        x: 0,
        y: 4
    )
    
    let elevation4 = Shadow(
        color: Color.black.opacity(0.24),
        radius: 12,
        x: 0,
        y: 6
    )
    
    let elevation5 = Shadow(
        color: Color.black.opacity(0.28),
        radius: 16,
        x: 0,
        y: 8
    )
    
    // Component Shadows
    let card = Shadow(
        color: Color.black.opacity(0.16),
        radius: 4,
        x: 0,
        y: 2
    )
    
    let button = Shadow(
        color: Color.black.opacity(0.12),
        radius: 2,
        x: 0,
        y: 1
    )
    
    let modal = Shadow(
        color: Color.black.opacity(0.32),
        radius: 24,
        x: 0,
        y: 12
    )
    
    let dropdown = Shadow(
        color: Color.black.opacity(0.20),
        radius: 8,
        x: 0,
        y: 4
    )
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// SwiftUI View Extension for applying shadows
extension View {
    func applyShadow(_ shadow: Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}