import SwiftUI
import AVFoundation

struct ReadingPracticeView: View {
    let material: Material
    @ObservedObject var recorder: AudioRecorder
    @Binding var isPracticing: Bool
    let onComplete: (PracticeResult) -> Void
    
    @State private var fontSize: CGFloat = 18
    @State private var scrollPosition: CGFloat = 0
    @State private var showingTranscriptionError = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let transcription = material.transcription {
                // テキスト表示エリア
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("教材テキスト")
                            .font(.headline)
                        
                        Spacer()
                        
                        // フォントサイズ調整
                        HStack(spacing: 12) {
                            Button {
                                fontSize = max(12, fontSize - 2)
                            } label: {
                                Image(systemName: "textformat.size.smaller")
                                    .font(.caption)
                            }
                            
                            Text("\(Int(fontSize))pt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 40)
                            
                            Button {
                                fontSize = min(32, fontSize + 2)
                            } label: {
                                Image(systemName: "textformat.size.larger")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // テキスト本文
                    ScrollView {
                        Text(transcription)
                            .font(.system(size: fontSize))
                            .lineSpacing(8)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 300)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                // 録音状態表示
                if isPracticing {
                    RecordingStatusView(
                        recordingTime: recorder.recordingTime,
                        audioLevel: recorder.audioLevel
                    )
                }
                
                // ヒント
                if !isPracticing {
                    HintView(
                        text: "録音ボタンを押して、上のテキストを音読してください",
                        icon: "info.circle"
                    )
                }
                
            } else if material.isTranscribing {
                // 文字起こし中
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("文字起こし中...")
                        .font(.headline)
                    
                    Text("しばらくお待ちください")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
                .padding()
                
            } else {
                // 文字起こしエラー
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("文字起こしがありません")
                        .font(.headline)
                    
                    Text("この教材には文字起こしがないため、\n音読練習ができません")
                        .multilineTextAlignment(.center)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("文字起こしを開始") {
                        // TODO: 文字起こしを開始
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxHeight: .infinity)
                .padding()
            }
        }
    }
}

// 録音状態表示ビュー
struct RecordingStatusView: View {
    let recordingTime: TimeInterval
    let audioLevel: Float
    
    var body: some View {
        VStack(spacing: 12) {
            // 録音時間
            Text(formatTime(recordingTime))
                .font(.system(size: 32, weight: .medium, design: .monospaced))
            
            // 音声レベルメーター
            AudioLevelMeter(level: audioLevel)
                .frame(height: 8)
                .padding(.horizontal, 40)
            
            Text("録音中...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// ヒントビュー
struct HintView: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal)
    }
}

// Preview
struct ReadingPracticeView_Previews: PreviewProvider {
    static var previews: some View {
        ReadingPracticeView(
            material: Material.sampleData[0],
            recorder: AudioRecorder(),
            isPracticing: .constant(false),
            onComplete: { _ in }
        )
    }
}