import SwiftUI

struct RecordingControlView: View {
    @ObservedObject var recorder: AudioRecorder
    @Binding var isPracticing: Bool
    @Binding var showingCountdown: Bool
    @Binding var countdownValue: Int
    let onStart: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 録音時間表示
            if isPracticing {
                Text(formatTime(recorder.recordingTime))
                    .font(.system(size: 36, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            // 録音ボタン
            ZStack {
                // パルスアニメーション
                if isPracticing {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .scaleEffect(isPracticing ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                            value: isPracticing
                        )
                }
                
                // メインボタン
                Button {
                    if isPracticing {
                        onStop()
                    } else {
                        onStart()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isPracticing ? Color.red : Color.red.opacity(0.8))
                            .frame(width: 80, height: 80)
                        
                        if isPracticing {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 24, height: 24)
                        } else {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                .disabled(showingCountdown)
            }
            
            // ステータステキスト
            if isPracticing {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(isPracticing ? 1 : 0)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true),
                            value: isPracticing
                        )
                    
                    Text("録音中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if !showingCountdown {
                Text("タップして録音開始")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
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