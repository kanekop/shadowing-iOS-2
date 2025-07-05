import SwiftUI

extension DesignSystem.Typography {
    // MARK: - Display (for large numbers/scores only)
    static let displayLarge = Font.system(size: 56, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 48, weight: .bold, design: .rounded)
    
    // MARK: - Headlines
    static let h1 = Font.system(size: 34, weight: .bold)
    static let h2 = Font.system(size: 28, weight: .bold)
    static let h3 = Font.system(size: 22, weight: .semibold)
    static let h4 = Font.system(size: 20, weight: .semibold)
    
    // MARK: - Body Text
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)
    
    // MARK: - Supporting Text
    static let caption = Font.system(size: 12, weight: .regular)
    static let label = Font.system(size: 11, weight: .medium)
    
    // MARK: - Special
    static let monospace = Font.system(size: 28, weight: .medium, design: .monospaced)
    static let monospaceSmall = Font.system(size: 17, weight: .medium, design: .monospaced)
}

// MARK: - Text Style Modifier
struct DesignSystemTextStyle: ViewModifier {
    let font: Font
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
    }
}

extension View {
    func textStyle(_ font: Font, color: Color = DesignSystem.Colors.textPrimary) -> some View {
        self.modifier(DesignSystemTextStyle(font: font, color: color))
    }
}