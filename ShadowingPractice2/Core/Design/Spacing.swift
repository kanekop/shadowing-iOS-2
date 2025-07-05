import SwiftUI

extension DesignSystem.Spacing {
    // MARK: - Base Unit (4pt grid)
    static let unit: CGFloat = 4
    
    // MARK: - Spacing Scale
    static let xxs: CGFloat = 4   // 1 unit
    static let xs: CGFloat = 8    // 2 units
    static let sm: CGFloat = 12   // 3 units
    static let md: CGFloat = 16   // 4 units - Standard padding
    static let lg: CGFloat = 20   // 5 units
    static let xl: CGFloat = 24   // 6 units - Section spacing
    static let xxl: CGFloat = 32  // 8 units
    static let xxxl: CGFloat = 40 // 10 units - Screen margins
    
    // MARK: - Component Specific
    static let screenEdge: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let listItemPadding: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let buttonPadding: CGFloat = 24
}

// MARK: - Corner Radius
extension DesignSystem.Radius {
    static let small: CGFloat = 4
    static let medium: CGFloat = 8
    static let standard: CGFloat = 10
    static let large: CGFloat = 12
    static let xLarge: CGFloat = 16
    static let xxLarge: CGFloat = 20
    static let round: CGFloat = .infinity
}

// MARK: - Component Sizes
extension DesignSystem.Size {
    // MARK: - Touch Targets
    static let minTouchTarget: CGFloat = 44
    
    // MARK: - Buttons
    static let buttonHeightLarge: CGFloat = 50
    static let buttonHeightMedium: CGFloat = 44
    static let buttonHeightSmall: CGFloat = 36
    
    // MARK: - Icons
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 24
    static let iconLarge: CGFloat = 32
    static let iconXLarge: CGFloat = 48
    
    // MARK: - Recording Button
    static let recordingButton: CGFloat = 72
    static let recordingButtonIcon: CGFloat = 32
    
    // MARK: - Progress Indicators
    static let progressCircleLarge: CGFloat = 140
    static let progressCircleMedium: CGFloat = 120
    static let progressCircleSmall: CGFloat = 60
    
    // MARK: - Cards
    static let materialCardMinWidth: CGFloat = 160
    static let materialCardAspectRatio: CGFloat = 0.75 // 3:4
    
    // MARK: - FAB
    static let fabSize: CGFloat = 56
    static let fabIconSize: CGFloat = 24
    
    // MARK: - List Items
    static let listItemHeight: CGFloat = 64
    
    // MARK: - Search Bar
    static let searchBarHeight: CGFloat = 36
}