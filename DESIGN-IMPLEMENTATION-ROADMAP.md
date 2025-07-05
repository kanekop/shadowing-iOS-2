# Design System Implementation Roadmap

## Overview

This document provides a step-by-step guide to implementing the new design system without breaking existing functionality. The implementation is divided into phases to ensure a smooth transition.

## Pre-Implementation Setup (Day 1)

### 1. Create Design System Foundation Files

Create these new files in the project:

```
ShadowingPractice2/
├── Core/
│   └── Design/
│       ├── DesignSystem.swift      # Central design tokens
│       ├── Colors.swift            # Color definitions
│       ├── Typography.swift        # Font styles
│       ├── Spacing.swift           # Layout constants
│       ├── Components.swift        # Reusable view modifiers
│       └── Animations.swift        # Animation constants
```

### 2. Design System Core Implementation

**DesignSystem.swift**
```swift
import SwiftUI

enum DesignSystem {
    enum Colors { }
    enum Typography { }
    enum Spacing { }
    enum Radius { }
    enum Animation { }
}
```

**Colors.swift**
```swift
extension DesignSystem.Colors {
    // Semantic colors that adapt to dark mode
    static let primary = Color(.systemBlue)
    static let accent = Color(hex: "FF6B35")
    static let success = Color(.systemGreen)
    static let error = Color(.systemRed)
    static let warning = Color(.systemOrange)
    
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    
    static let background = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    
    static let separator = Color(.separator)
}
```

**Typography.swift**
```swift
extension DesignSystem.Typography {
    // Display
    static let displayLarge = Font.system(size: 56, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 48, weight: .bold, design: .rounded)
    
    // Headlines
    static let h1 = Font.system(size: 34, weight: .bold)
    static let h2 = Font.system(size: 28, weight: .bold)
    static let h3 = Font.system(size: 22, weight: .semibold)
    static let h4 = Font.system(size: 20, weight: .semibold)
    
    // Body
    static let bodyLarge = Font.system(size: 17)
    static let bodyMedium = Font.system(size: 15)
    static let bodySmall = Font.system(size: 13)
    
    // Supporting
    static let caption = Font.system(size: 12)
    static let label = Font.system(size: 11, weight: .medium)
    
    // Special
    static let monospace = Font.system(size: 28, weight: .medium, design: .monospaced)
}
```

## Phase 1: Critical UI Fixes (Days 2-3)

### Priority 1: Recording Screen

**File**: `Features/Practice/Views/RecordingControlView.swift`

Key changes:
1. Reduce timer font from 36pt to 28pt monospace
2. Fix recording button to 72x72pt
3. Remove or reduce countdown overlay from 120pt to 48pt
4. Apply consistent spacing

### Priority 2: Practice Result Screen

**File**: `Features/Practice/Views/PracticeResultView.swift`

Key changes:
1. Reduce score circle from 180pt to 140pt
2. Keep score font at 48pt but improve proportions
3. Fix tab layout for 差分統計 visibility
4. Create proper metrics grid with consistent sizing

### Priority 3: Component Library

Create reusable components:

**Components/PrimaryButton.swift**
```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(DesignSystem.Colors.primary)
                .cornerRadius(12)
        }
    }
}
```

## Phase 2: Screen-by-Screen Updates (Days 4-7)

### Update Order (by impact):

1. **Practice Flow** (Highest user interaction)
   - PracticeView
   - RecordingControlView
   - PracticeResultView
   - ComparisonView

2. **Material Management**
   - MaterialsListView
   - MaterialDetailView
   - MaterialCardView

3. **History & Analytics**
   - HistoryView
   - HistoryListItemView

4. **Settings & Navigation**
   - SettingsView
   - MainTabView

### Implementation Pattern

For each screen:

1. **Audit Current State**
   ```swift
   // Before
   .font(.system(size: 36, weight: .medium))
   .padding(20)
   
   // After
   .font(DesignSystem.Typography.h2)
   .padding(DesignSystem.Spacing.md)
   ```

2. **Update Colors**
   ```swift
   // Before
   .foregroundColor(.secondary)
   
   // After
   .foregroundColor(DesignSystem.Colors.textSecondary)
   ```

3. **Fix Touch Targets**
   ```swift
   // Ensure minimum 44pt
   .frame(minWidth: 44, minHeight: 44)
   ```

## Phase 3: Polish & Consistency (Days 8-9)

### 1. Animation Standardization

Create consistent animations:
```swift
extension View {
    func standardTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    func buttonPressStyle() -> some View {
        self.scaleEffect(1.0)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    // Scale animation
                }
            }
    }
}
```

### 2. Empty States

Create consistent empty state component:
```swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            Text(title)
                .font(DesignSystem.Typography.h3)
            
            Text(message)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if let action = action {
                PrimaryButton(title: "教材を追加", action: action)
                    .padding(.top, DesignSystem.Spacing.md)
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
}
```

## Phase 4: Testing & Refinement (Day 10)

### Testing Checklist

1. **Visual Consistency**
   - [ ] All screens use design system tokens
   - [ ] No hardcoded colors or sizes
   - [ ] Consistent spacing throughout

2. **Accessibility**
   - [ ] Test with Dynamic Type (xSmall to xxxLarge)
   - [ ] Verify color contrast ratios
   - [ ] Check VoiceOver labels

3. **Dark Mode**
   - [ ] All screens look good in dark mode
   - [ ] Proper color adaptation
   - [ ] No hardcoded light-only colors

4. **Device Testing**
   - [ ] iPhone SE (smallest)
   - [ ] iPhone 15 Pro (standard)
   - [ ] iPhone 15 Pro Max (largest)
   - [ ] iPad (if supported)

### Performance Considerations

1. **Avoid Over-Animation**
   - Use animations sparingly
   - Respect "Reduce Motion" setting
   - Keep durations under 0.5s

2. **Image Optimization**
   - Use SF Symbols where possible
   - Lazy load heavy content
   - Cache computed values

## Migration Tips

### Do's
✅ Test each change thoroughly
✅ Keep Git commits small and focused
✅ Document any deviations from the design system
✅ Get user feedback early
✅ Maintain backwards compatibility

### Don'ts
❌ Don't change functionality while updating UI
❌ Don't skip the testing phase
❌ Don't hardcode values - use the design system
❌ Don't forget accessibility
❌ Don't rush the implementation

## Code Review Checklist

Before merging any UI updates:

- [ ] Uses design system tokens (no magic numbers)
- [ ] Maintains 44pt minimum touch targets
- [ ] Works with Dynamic Type
- [ ] Looks good in light and dark mode
- [ ] No memory leaks or performance issues
- [ ] Follows SwiftUI best practices
- [ ] Animations respect user preferences

## Success Metrics

After implementation, verify:

1. **User Satisfaction**: Improved app store ratings
2. **Usability**: Reduced user errors, faster task completion
3. **Accessibility**: Works for all users
4. **Performance**: No degradation in app performance
5. **Consistency**: Unified visual language across all screens

## Long-term Maintenance

1. **Design System Updates**: Review quarterly
2. **Component Library**: Expand as needed
3. **Documentation**: Keep design specs updated
4. **Training**: Ensure all developers understand the system
5. **Tooling**: Consider design tokens sync tools

This roadmap ensures a systematic, safe transition to the new design system while maintaining app stability and improving user experience.