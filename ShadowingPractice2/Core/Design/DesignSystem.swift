import SwiftUI

enum DesignSystem {
    enum Colors { }
    enum Typography { }
    enum Spacing { }
    enum Radius { }
    enum Animation { }
    enum Size { }
}

// MARK: - View Extensions for Design System
extension View {
    func designSystemBackground(_ style: DesignSystem.BackgroundStyle = .primary) -> some View {
        self.background(style.color)
    }
    
    func designSystemCard() -> some View {
        self
            .background(DesignSystem.Colors.backgroundSecondary)
            .cornerRadius(DesignSystem.Radius.large)
    }
}

// MARK: - Background Styles
extension DesignSystem {
    enum BackgroundStyle {
        case primary
        case secondary
        case tertiary
        
        var color: Color {
            switch self {
            case .primary:
                return Colors.background
            case .secondary:
                return Colors.backgroundSecondary
            case .tertiary:
                return Colors.backgroundTertiary
            }
        }
    }
}