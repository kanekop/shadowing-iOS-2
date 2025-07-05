import SwiftUI

struct RecordingControlView: View {
    @ObservedObject var recorder: AudioRecorder
    @Binding var isPracticing: Bool
    @Binding var showingCountdown: Bool
    @Binding var countdownValue: Int
    let onStart: () -> Void
    let onStop: () -> Void
    
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Timer Container
            if isPracticing {
                CardView {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text(formatTime(recorder.recordingTime))
                            .font(DesignSystem.Typography.monospace)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(DesignSystem.Colors.separator)
                                    .frame(height: 6)
                                    .cornerRadius(3)
                                
                                Rectangle()
                                    .fill(DesignSystem.Colors.accent)
                                    .frame(width: min(geometry.size.width * CGFloat(recorder.recordingTime / 120.0), geometry.size.width), height: 6)
                                    .cornerRadius(3)
                                    .animation(DesignSystem.Animation.easeOutFast, value: recorder.recordingTime)
                            }
                        }
                        .frame(height: 6)
                        
                        Text("最大 2分")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
            
            // Recording Button
            ZStack {
                // Pulse animation background
                if isPracticing {
                    Circle()
                        .fill(DesignSystem.Colors.error.opacity(0.2))
                        .frame(width: DesignSystem.Size.recordingButton * 1.1, height: DesignSystem.Size.recordingButton * 1.1)
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                        .opacity(isPulsing ? 0.8 : 1.0)
                        .onAppear {
                            withAnimation(DesignSystem.Animation.recordingPulse) {
                                isPulsing = true
                            }
                        }
                        .onDisappear {
                            isPulsing = false
                        }
                }
                
                // Main button
                Button {
                    if isPracticing {
                        onStop()
                    } else {
                        onStart()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isPracticing ? DesignSystem.Colors.error : DesignSystem.Colors.backgroundSecondary)
                            .frame(width: DesignSystem.Size.recordingButton, height: DesignSystem.Size.recordingButton)
                            .overlay(
                                Circle()
                                    .stroke(isPracticing ? DesignSystem.Colors.error : DesignSystem.Colors.separator, lineWidth: 2)
                            )
                        
                        Image(systemName: isPracticing ? "stop.fill" : "mic.fill")
                            .font(.system(size: DesignSystem.Size.recordingButtonIcon))
                            .foregroundColor(isPracticing ? .white : DesignSystem.Colors.error)
                    }
                }
                .buttonStyle(ButtonPressStyle())
                .disabled(showingCountdown)
            }
            
            // Status Label
            if isPracticing {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Circle()
                        .fill(DesignSystem.Colors.error)
                        .frame(width: 8, height: 8)
                        .opacity(isPulsing ? 0.5 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                    
                    Text("録音中")
                        .font(DesignSystem.Typography.label)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            } else if !showingCountdown {
                Text("録音を開始")
                    .font(DesignSystem.Typography.label)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.bottom, DesignSystem.Spacing.xl)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

// Preview
struct RecordingControlView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RecordingControlView(
                recorder: AudioRecorder(),
                isPracticing: .constant(false),
                showingCountdown: .constant(false),
                countdownValue: .constant(3),
                onStart: {},
                onStop: {}
            )
            
            RecordingControlView(
                recorder: AudioRecorder(),
                isPracticing: .constant(true),
                showingCountdown: .constant(false),
                countdownValue: .constant(3),
                onStart: {},
                onStop: {}
            )
        }
    }
}