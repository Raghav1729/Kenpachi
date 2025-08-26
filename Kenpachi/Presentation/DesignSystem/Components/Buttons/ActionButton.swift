import SwiftUI

struct ActionButton: View {
    let title: String
    let style: ActionButtonStyle
    let action: () -> Void
    
    enum ActionButtonStyle {
        case primary
        case secondary
        case destructive
        case ghost
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.current.typography.labelLarge)
                .fontWeight(.semibold)
                .foregroundColor(textColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.current.cornerRadius.button)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .cornerRadius(AppTheme.current.cornerRadius.button)
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return AppTheme.current.colors.buttonPrimary
        case .secondary:
            return AppTheme.current.colors.buttonSecondary
        case .destructive:
            return AppTheme.current.colors.buttonDestructive
        case .ghost:
            return Color.clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .destructive:
            return AppTheme.current.colors.textPrimary
        case .secondary, .ghost:
            return AppTheme.current.colors.textSecondary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .ghost:
            return AppTheme.current.colors.border
        default:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .ghost:
            return 1
        default:
            return 0
        }
    }
}