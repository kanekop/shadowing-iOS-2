# ShadowingPractice2 Design System Specification

## Design Philosophy

This design system creates a modern, clean, and accessible interface for the ShadowingPractice2 app. Our goals are:

1. **Clarity**: Information hierarchy that guides users naturally
2. **Consistency**: Unified visual language across all screens
3. **Accessibility**: Meeting WCAG 2.1 AA standards
4. **Delight**: Subtle animations and thoughtful micro-interactions
5. **Focus**: Minimalist approach that emphasizes content

## Color Palette

### Semantic Colors

```swift
// Primary Colors
primary: #007AFF (iOS Blue)
primaryLight: #4DA2FF
primaryDark: #0051D5

// Accent Colors  
accent: #FF6B35 (Vibrant Orange)
accentLight: #FF8A5B
accentDark: #E84A1F

// Status Colors
success: #34C759
warning: #FF9500
error: #FF3B30
info: #5856D6

// Neutral Colors
text: #000000 (dark mode: #FFFFFF)
textSecondary: #3C3C43 (dark mode: #EBEBF5)
textTertiary: #C7C7CC (dark mode: #545456)
background: #FFFFFF (dark mode: #000000)
backgroundSecondary: #F2F2F7 (dark mode: #1C1C1E)
backgroundTertiary: #FFFFFF (dark mode: #2C2C2E)
separator: #C6C6C8 (dark mode: #38383A)
```

## Typography

### Type Scale

Based on iOS Dynamic Type with custom adjustments:

```swift
// Display (for large numbers/scores only)
displayLarge: 56pt, weight: .bold, design: .rounded
displayMedium: 48pt, weight: .bold, design: .rounded

// Headlines
h1: 34pt, weight: .bold (largeTitle)
h2: 28pt, weight: .bold (title)
h3: 22pt, weight: .semibold (title2)
h4: 20pt, weight: .semibold (title3)

// Body Text
bodyLarge: 17pt, weight: .regular (body)
bodyMedium: 15pt, weight: .regular (callout)
bodySmall: 13pt, weight: .regular (footnote)

// Supporting Text
caption: 12pt, weight: .regular (caption)
label: 11pt, weight: .medium (caption2)

// Special
monospace: 17pt, weight: .medium, design: .monospaced (for timers)
```

### Usage Guidelines

- **Headings**: Use sparingly, maximum 2 heading levels per screen
- **Body**: Primary content and descriptions
- **Caption**: Metadata, timestamps, secondary information
- **Monospace**: Timers, codes, technical values only

## Spacing System

Using an 4pt grid system:

```swift
spacing2: 8pt   // Compact spacing
spacing3: 12pt  // Default internal spacing
spacing4: 16pt  // Standard padding
spacing5: 20pt  // Section spacing
spacing6: 24pt  // Large spacing
spacing8: 32pt  // Extra large spacing
spacing10: 40pt // Screen margins
```

### Layout Rules

- Screen edge padding: 16pt (iPhone), 20pt (iPad)
- Section spacing: 24pt between major sections
- Component internal padding: 12-16pt
- List item padding: 16pt vertical, 16pt horizontal
- Minimum touch target: 44x44pt

## Component Library

### Buttons

**Primary Button**
```swift
height: 50pt
cornerRadius: 12pt
font: bodyLarge, weight: .semibold
background: primary/accent
padding: horizontal 24pt
```

**Secondary Button**
```swift
height: 44pt
cornerRadius: 10pt
font: bodyMedium, weight: .medium
background: backgroundSecondary
border: 1pt, separator
padding: horizontal 20pt
```

**Text Button**
```swift
height: 44pt
font: bodyMedium, weight: .medium
color: primary
padding: horizontal 16pt
```

**Icon Button**
```swift
size: 44x44pt
cornerRadius: 22pt (circular)
icon: 24pt
background: backgroundSecondary (normal), primary (active)
```

### Recording Button

**Large Recording Button**
```swift
size: 72x72pt
cornerRadius: 36pt
icon: 32pt (SF Symbol "mic.fill")
background: error (recording), backgroundSecondary (idle)
pulseAnimation: scale 1.0 to 1.15, duration: 1.5s
```

### Cards

**Material Card**
```swift
cornerRadius: 16pt
padding: 16pt
background: backgroundSecondary
shadow: color: black, opacity: 0.04, radius: 8, y: 2
minHeight: 120pt
```

**Result Card**
```swift
cornerRadius: 20pt
padding: 20pt
background: backgroundTertiary
border: 1pt, separator (optional)
```

### Progress Indicators

**Circular Progress**
```swift
size: 200x200pt (large), 120x120pt (medium), 60x60pt (small)
lineWidth: 12pt (large), 8pt (medium), 4pt (small)
font: displayMedium (large), h3 (medium), bodyLarge (small)
```

**Linear Progress**
```swift
height: 8pt
cornerRadius: 4pt
background: separator
fill: accent/success
```

### Lists

**List Item**
```swift
minHeight: 60pt
padding: 16pt vertical, 16pt horizontal
separator: inset 16pt
accessories: chevron 12pt, badges, toggles
```

### Navigation

**Tab Bar**
```swift
height: 49pt + safe area
icon: 24pt
label: label font
spacing: 2pt between icon and label
```

**Navigation Bar**
```swift
height: 44pt (compact), 96pt (large)
title: h4 (compact), h1 (large)
buttons: 44x44pt touch targets
```

### Input Fields

**Text Field**
```swift
height: 44pt
cornerRadius: 10pt
padding: horizontal 16pt
font: bodyLarge
background: backgroundSecondary
placeholder: textTertiary
```

**Search Bar**
```swift
height: 36pt
cornerRadius: 10pt
padding: horizontal 12pt
icon: 16pt
font: bodyMedium
```

## Animation Guidelines

### Durations

```swift
instant: 0.1s    // Immediate feedback
fast: 0.2s       // Quick transitions
medium: 0.3s     // Standard animations
slow: 0.5s       // Deliberate movements
```

### Easing Curves

- **Spring**: `spring(response: 0.4, dampingFraction: 0.8)`
- **EaseInOut**: For view transitions
- **EaseOut**: For appearing elements
- **Linear**: For continuous animations only

### Common Animations

1. **Button Press**: Scale 0.95, duration: instant
2. **View Transition**: Slide + fade, duration: medium
3. **Loading**: Continuous rotation or pulse
4. **Success/Error**: Spring bounce, duration: slow

## Screen-Specific Guidelines

### Practice Screen

1. **Mode Selector**: Prominent segmented control at top
2. **Timer**: Large monospace font, centered
3. **Recording Button**: 72pt, bottom center with 32pt margin
4. **Progress Bar**: Linear, below timer
5. **Controls**: Grouped horizontally, 44pt targets

### Results Screen

1. **Score Circle**: 180pt diameter, centered
2. **Metrics Grid**: 2 columns, equal spacing
3. **Comparison Text**: Clear diff highlighting
4. **Action Buttons**: Full width, stacked vertically

### Materials List

1. **Grid Layout**: 2 columns (iPhone), 3-4 columns (iPad)
2. **Card Size**: Minimum 150pt width, 4:3 aspect ratio
3. **FAB**: 56pt, bottom right, 16pt margin
4. **Empty State**: Centered illustration + text + action

### Settings Screen

1. **Grouped Lists**: System-style with proper insets
2. **Toggle Switches**: Right-aligned, standard iOS
3. **Disclosure Indicators**: For navigation items
4. **Section Headers**: Uppercase, small, gray

## Accessibility

### Requirements

1. **Contrast Ratios**: 
   - Normal text: 4.5:1 minimum
   - Large text: 3:1 minimum
   - UI elements: 3:1 minimum

2. **Touch Targets**: 44x44pt minimum

3. **Dynamic Type**: Support from .xSmall to .xxxLarge

4. **VoiceOver**: Proper labels and hints

5. **Reduce Motion**: Respect user preference

### Implementation Notes

- Use semantic colors that adapt to dark mode
- Test with Dynamic Type at all sizes
- Ensure all interactive elements have labels
- Provide haptic feedback for important actions
- Support keyboard navigation where applicable

## Implementation Priority

### Phase 1: Foundation (Week 1)
1. Create DesignSystem.swift with color definitions
2. Create Typography.swift with text styles
3. Create Spacing.swift with layout constants
4. Update existing buttons to new system

### Phase 2: Core Components (Week 2)
1. Redesign recording interface
2. Update result screens
3. Implement new card designs
4. Fix navigation consistency

### Phase 3: Polish (Week 3)
1. Add animations
2. Implement empty states
3. Dark mode testing
4. Accessibility audit

## Migration Strategy

1. **Don't break existing functionality**
2. **Update one screen at a time**
3. **Test thoroughly after each change**
4. **Document any deviations from the system**
5. **Get user feedback early and often**

## Design Tokens

For future implementation, all values should be tokenized:

```swift
enum DesignTokens {
    enum Colors {
        static let primary = Color("primary")
        static let accent = Color("accent")
        // etc...
    }
    
    enum Typography {
        static let h1 = Font.system(size: 34, weight: .bold)
        static let body = Font.system(size: 17)
        // etc...
    }
    
    enum Spacing {
        static let xs = 4.0
        static let sm = 8.0
        static let md = 16.0
        // etc...
    }
}
```

This design system provides a solid foundation for creating a professional, consistent, and accessible user interface. Follow these guidelines to transform the app from "ダサい" to delightful!