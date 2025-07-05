import SwiftUI

extension DesignSystem.Animation {
    // MARK: - Durations
    static let instant: Double = 0.1
    static let fast: Double = 0.2
    static let medium: Double = 0.3
    static let slow: Double = 0.5
    
    // MARK: - Spring Animations
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let springSmooth = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let springStiff = Animation.spring(response: 0.3, dampingFraction: 0.9)
    
    // MARK: - Easing Animations
    static let easeInOutFast = Animation.easeInOut(duration: fast)
    static let easeInOutMedium = Animation.easeInOut(duration: medium)
    static let easeInOutSlow = Animation.easeInOut(duration: slow)
    
    static let easeOutFast = Animation.easeOut(duration: fast)
    static let easeOutMedium = Animation.easeOut(duration: medium)
    
    // MARK: - Recording Animation
    static let recordingPulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
}

// MARK: - View Modifiers for Common Animations
extension View {
    func buttonPressAnimation() -> some View {
        self.scaleEffect(1.0)
            .onTapGesture { }
            .scaleEffect(1.0)
            .animation(DesignSystem.Animation.springBouncy, value: 1.0)
    }
    
    func standardTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    func fadeTransition() -> some View {
        self.transition(.opacity.animation(DesignSystem.Animation.easeInOutMedium))
    }
}

// MARK: - Button Press Style
struct ButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animation.easeOutFast, value: configuration.isPressed)
    }
}

// MARK: - Recording Button Animation
struct RecordingPulseModifier: ViewModifier {
    @State private var isPulsing = false
    let isRecording: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isRecording && isPulsing ? 1.1 : 1.0)
            .opacity(isRecording && isPulsing ? 0.8 : 1.0)
            .animation(isRecording ? DesignSystem.Animation.recordingPulse : .default, value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func recordingPulse(isRecording: Bool) -> some View {
        self.modifier(RecordingPulseModifier(isRecording: isRecording))
    }
}