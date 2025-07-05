import SwiftUI

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    
    init(title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(DesignSystem.Typography.bodyLarge)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Size.buttonHeightLarge)
            .background(isLoading ? DesignSystem.Colors.primary.opacity(0.6) : DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.Radius.large)
        }
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Size.buttonHeightMedium)
                .background(DesignSystem.Colors.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.standard)
                        .stroke(DesignSystem.Colors.separator, lineWidth: 1)
                )
                .cornerRadius(DesignSystem.Radius.standard)
        }
    }
}

// MARK: - Text Button
struct TextButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .frame(height: DesignSystem.Size.buttonHeightMedium)
        }
    }
}

// MARK: - Icon Button
struct IconButton: View {
    let systemName: String
    let action: () -> Void
    let size: CGFloat
    
    init(systemName: String, size: CGFloat = DesignSystem.Size.minTouchTarget, action: @escaping () -> Void) {
        self.systemName = systemName
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: DesignSystem.Size.iconMedium))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: size, height: size)
                .background(DesignSystem.Colors.backgroundSecondary)
                .clipShape(Circle())
        }
    }
}

// MARK: - Card View
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignSystem.Spacing.cardPadding)
            .background(DesignSystem.Colors.backgroundSecondary)
            .cornerRadius(DesignSystem.Radius.large)
    }
}

// MARK: - Design System Empty State View
struct DSEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.Size.iconXLarge))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            Text(title)
                .font(DesignSystem.Typography.h3)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(message)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(title: actionTitle, action: action)
                    .padding(.top, DesignSystem.Spacing.md)
                    .padding(.horizontal, DesignSystem.Spacing.xxxl)
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Progress Circle View
struct ProgressCircleView: View {
    let value: Double
    let total: Double
    let size: CGFloat
    let lineWidth: CGFloat
    var strokeColor: Color = DesignSystem.Colors.accent
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(max(value / total, 0), 1)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(DesignSystem.Colors.separator, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(strokeColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Standard Search Bar
struct StandardSearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.Colors.textTertiary)
                .font(.system(size: DesignSystem.Size.iconSmall))
            
            TextField(placeholder, text: $text)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .font(.system(size: DesignSystem.Size.iconSmall))
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .frame(height: DesignSystem.Size.searchBarHeight)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.Radius.standard)
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: DesignSystem.Size.fabIconSize))
                .foregroundColor(.white)
                .frame(width: DesignSystem.Size.fabSize, height: DesignSystem.Size.fabSize)
                .background(DesignSystem.Colors.accent)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ButtonPressStyle())
    }
}