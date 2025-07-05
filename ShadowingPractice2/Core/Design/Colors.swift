import SwiftUI

extension DesignSystem.Colors {
    // MARK: - Primary Colors
    static let primary = Color(.systemBlue)
    static let primaryLight = Color(red: 0.302, green: 0.635, blue: 1.0)
    static let primaryDark = Color(red: 0.0, green: 0.318, blue: 0.835)
    
    // MARK: - Accent Colors
    static let accent = Color(red: 1.0, green: 0.42, blue: 0.208) // #FF6B35
    static let accentLight = Color(red: 1.0, green: 0.541, blue: 0.357)
    static let accentDark = Color(red: 0.91, green: 0.29, blue: 0.122)
    
    // MARK: - Status Colors
    static let success = Color(.systemGreen)
    static let warning = Color(.systemOrange)
    static let error = Color(.systemRed)
    static let info = Color(.systemPurple)
    
    // MARK: - Text Colors
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    static let textPlaceholder = Color(.placeholderText)
    
    // MARK: - Background Colors
    static let background = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    static let backgroundGrouped = Color(.systemGroupedBackground)
    
    // MARK: - UI Element Colors
    static let separator = Color(.separator)
    static let opaqueSeparator = Color(.opaqueSeparator)
    static let link = Color(.link)
    
    // MARK: - Fill Colors
    static let fillPrimary = Color(.systemFill)
    static let fillSecondary = Color(.secondarySystemFill)
    static let fillTertiary = Color(.tertiarySystemFill)
    static let fillQuaternary = Color(.quaternarySystemFill)
}