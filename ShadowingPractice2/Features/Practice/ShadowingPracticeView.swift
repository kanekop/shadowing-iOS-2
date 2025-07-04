import SwiftUI
import AVFoundation

struct ShadowingPracticeView: View {
    let material: Material
    @ObservedObject var recorder: AudioRecorder
    @Binding var isPracticing: Bool
    let onComplete: (PracticeResult) -> Void
    
    @StateObject private var audioPlayer = AudioPlayerManager()
    @State private var playbackRate: Float = 1.0
    @State private var isLooping = false
    @State private var showingTranscription = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 音声プレイヤー
            VStack(spacing: 16) {
                // 波形表示（将来実装）
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 120)
                    
                    if audioPlayer.isPlaying {
                        // 再生中アニメーション
                        HStack(spacing: 4) {
                            ForEach(0..<20) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.accentColor)
                                    .frame(width: 3, height: CGFloat.random(in: 20...80))
                                    .animation(
                                        .easeInOut(duration: 0.5)
                                        .repeatForever()
                                        .delay(Double(i) * 0.05),
                                        value: audioPlayer.isPlaying
                                    )
                            }
                        }
                    } else {
                        Text("音声波形")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // プログレスバー
                VStack(spacing: 8) {
                    ProgressView(value: audioPlayer.playbackProgress)
                        .progressViewStyle(.linear)
                    
                    HStack {
                        Text(formatTime(audioPlayer.currentTime))
                            .font(.caption)
                            .monospacedDigit()
                        Spacer()
                        Text(formatTime(audioPlayer.duration))
                            .font(.caption)
                            .monospacedDigit()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // 再生コントロール
                HStack(spacing: 30) {
                    // 10秒戻る
                    Button {
                        audioPlayer.seekBackward(seconds: 10)
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.title2)
                    }
                    .disabled(!audioPlayer.isReady)
                    
                    // 再生/一時停止
                    Button {
                        if audioPlayer.isPlaying {
                            audioPlayer.pause()
                        } else {
                            startShadowing()
                        }
                    } label: {
                        Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                    }
                    .disabled(!audioPlayer.isReady)
                    
                    // 10秒進む
                    Button {
                        audioPlayer.seekForward(seconds: 10)
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.title2)
                    }
                    .disabled(!audioPlayer.isReady)
                }
                
                // 再生速度とループ設定
                HStack(spacing: 20) {
                    // 再生速度
                    Menu {
                        ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
                            Button(String(format: "%.1fx", rate)) {
                                playbackRate = Float(rate)
                                audioPlayer.setPlaybackRate(Float(rate))
                            }
                        }
                    } label: {
                        Label(String(format: "%.1fx", playbackRate), systemImage: "speedometer")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .cornerRadius(15)
                    }
                    
                    // ループ設定
                    Button {
                        isLooping.toggle()
                        audioPlayer.setLooping(isLooping)
                    } label: {
                        Label("リピート", systemImage: isLooping ? "repeat.circle.fill" : "repeat")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isLooping ? Color.accentColor : Color(.systemGray5))
                            .foregroundColor(isLooping ? .white : .primary)
                            .cornerRadius(15)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // 録音状態表示
            if isPracticing {
                RecordingStatusView(
                    recordingTime: recorder.recordingTime,
                    audioLevel: recorder.audioLevel
                )
            }
            
            // テキスト表示トグル
            Button {
                showingTranscription.toggle()
            } label: {
                Label(
                    showingTranscription ? "テキストを隠す" : "テキストを表示",
                    systemImage: showingTranscription ? "eye.slash" : "eye"
                )
                .font(.caption)
            }
            
            // テキスト表示
            if showingTranscription, let transcription = material.transcription {
                ScrollView {
                    Text(transcription)
                        .font(.body)
                        .lineSpacing(6)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .padding(.horizontal)
            }
            
            // ヒント
            if !isPracticing && !audioPlayer.isPlaying {
                HintView(
                    text: "再生ボタンを押すと、音声再生と録音が同時に始まります",
                    icon: "info.circle"
                )
            }
        }
        .onAppear {
            audioPlayer.loadAudio(from: material.url)
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }
    
    private func startShadowing() {
        // 音声再生開始
        audioPlayer.play()
        
        // 少し遅延させて録音開始（ユーザーが準備できるように）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                do {
                    try await recorder.startRecording(isMaterial: false)
                    isPracticing = true
                } catch {
                    print("録音開始エラー: \(error)")
                }
            }
        }
        
        // 音声終了時の処理
        audioPlayer.onPlaybackFinished = { [weak recorder, weak audioPlayer] in
            recorder?.stopRecording { result in
                Task { @MainActor in
                    isPracticing = false
                    // 結果処理
                    switch result {
                    case .success(let url):
                        // TODO: 評価処理
                        print("録音完了: \(url)")
                    case .failure(let error):
                        print("録音エラー: \(error)")
                    }
                    audioPlayer?.onPlaybackFinished = nil  // クロージャを解放
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// 音声プレイヤーマネージャー
class AudioPlayerManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var isReady = false
    @Published var playbackProgress: Double = 0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    var onPlaybackFinished: (() -> Void)?
    
    func loadAudio(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            isReady = true
        } catch {
            print("音声ファイルの読み込みエラー: \(error)")
            isReady = false
        }
    }
    
    func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        timer?.invalidate()
        updateProgress()
    }
    
    func setPlaybackRate(_ rate: Float) {
        audioPlayer?.rate = rate
    }
    
    func setLooping(_ loop: Bool) {
        audioPlayer?.numberOfLoops = loop ? -1 : 0
    }
    
    func seekForward(seconds: TimeInterval) {
        guard let player = audioPlayer else { return }
        let newTime = min(player.duration, player.currentTime + seconds)
        player.currentTime = newTime
        updateProgress()
    }
    
    func seekBackward(seconds: TimeInterval) {
        guard let player = audioPlayer else { return }
        let newTime = max(0, player.currentTime - seconds)
        player.currentTime = newTime
        updateProgress()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
        playbackProgress = player.duration > 0 ? player.currentTime / player.duration : 0
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        timer?.invalidate()
        if flag {
            onPlaybackFinished?()
        }
    }
}

// Preview
struct ShadowingPracticeView_Previews: PreviewProvider {
    static var previews: some View {
        ShadowingPracticeView(
            material: Material.sampleData[0],
            recorder: AudioRecorder(),
            isPracticing: .constant(false),
            onComplete: { _ in }
        )
    }
}