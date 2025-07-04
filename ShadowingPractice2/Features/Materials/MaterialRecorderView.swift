import SwiftUI
import AVFoundation

struct MaterialRecorderView: View {
    @StateObject private var recorder = AudioRecorder()
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingPreview = false
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @Environment(\.dismiss) private var dismiss
    
    let completion: (URL) -> Void
    let maxRecordingTime: TimeInterval = 120 // 2分
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // 録音時間表示
                VStack(spacing: 8) {
                    Text(formatTime(recordingTime))
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                    
                    if recorder.isRecording {
                        Text("最大 \(Int(maxRecordingTime/60))分")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 録音レベルメーター
                if recorder.isRecording {
                    AudioLevelMeter(level: recorder.audioLevel)
                        .frame(height: 20)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // 録音ボタン
                ZStack {
                    if recorder.isRecording {
                        // パルスアニメーション
                        Circle()
                            .fill(Color.red.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .scaleEffect(recorder.isRecording ? 1.3 : 1.0)
                            .animation(
                                .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                                value: recorder.isRecording
                            )
                    }
                    
                    Button {
                        if recorder.isRecording {
                            stopRecording()
                        } else if showingPreview {
                            // プレビューモードでは何もしない
                        } else {
                            startRecording()
                        }
                    } label: {
                        Circle()
                            .fill(recorder.isRecording ? Color.red : Color.red.opacity(0.8))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            )
                    }
                    .disabled(showingPreview)
                }
                
                // プレビューコントロール
                if showingPreview, let url = recorder.currentRecordingURL {
                    VStack(spacing: 20) {
                        // 再生ボタン
                        Button {
                            if isPlaying {
                                stopPlaying()
                            } else {
                                playRecording(url: url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                Text(isPlaying ? "停止" : "再生")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                        }
                        
                        // アクションボタン
                        HStack(spacing: 20) {
                            Button("録り直す") {
                                resetRecording()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("保存") {
                                saveRecording(url: url)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("教材を録音")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            stopRecording()
            timer?.invalidate()
        }
    }
    
    private func startRecording() {
        do {
            try recorder.startRecording()
            startTimer()
        } catch {
            // エラー処理
            print("録音開始エラー: \(error)")
        }
    }
    
    private func stopRecording() {
        recorder.stopRecording { url in
            if url != nil {
                showingPreview = true
            }
        }
        timer?.invalidate()
        timer = nil
    }
    
    private func startTimer() {
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingTime += 0.1
            
            // 最大録音時間に達したら自動停止
            if recordingTime >= maxRecordingTime {
                stopRecording()
            }
        }
    }
    
    private func playRecording(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = nil
            audioPlayer?.play()
            isPlaying = true
            
            // 再生終了を監視
            DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 0)) {
                isPlaying = false
            }
        } catch {
            print("再生エラー: \(error)")
        }
    }
    
    private func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    private func resetRecording() {
        stopPlaying()
        showingPreview = false
        recordingTime = 0
        recorder.currentRecordingURL = nil
    }
    
    private func saveRecording(url: URL) {
        stopPlaying()
        completion(url)
        dismiss()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

// 音声レベルメーター
struct AudioLevelMeter: View {
    let level: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                
                // レベル表示
                RoundedRectangle(cornerRadius: 10)
                    .fill(levelColor)
                    .frame(width: geometry.size.width * CGFloat(level))
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
    }
    
    private var levelColor: Color {
        if level > 0.8 {
            return .red
        } else if level > 0.6 {
            return .orange
        } else {
            return .green
        }
    }
}

// Preview
struct MaterialRecorderView_Previews: PreviewProvider {
    static var previews: some View {
        MaterialRecorderView { _ in }
    }
}