import SwiftUI
import AVFoundation

struct MaterialDetailView: View {
    let material: Material
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0
    @State private var currentTime: TimeInterval = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showingEditTitle = false
    @State private var editedTitle = ""
    @State private var editedMemo = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 基本情報セクション
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("基本情報")
                                .font(.headline)
                            Spacer()
                            Button("編集") {
                                editedTitle = material.title
                                editedMemo = material.memo ?? ""
                                showingEditTitle = true
                            }
                            .font(.caption)
                        }
                        
                        InfoRow(label: "タイトル", value: material.title)
                        InfoRow(label: "作成日", value: formatDate(material.createdAt))
                        InfoRow(label: "長さ", value: formatDuration(material.duration))
                        InfoRow(label: "ソース", value: material.sourceType == .imported ? "インポート" : "録音")
                        
                        if let memo = material.memo, !memo.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("メモ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(memo)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 音声プレイヤー
                    VStack(spacing: 16) {
                        Text("音声プレビュー")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // プログレスバー
                        VStack(spacing: 8) {
                            ProgressView(value: playbackProgress)
                                .progressViewStyle(.linear)
                            
                            HStack {
                                Text(formatTime(currentTime))
                                    .font(.caption)
                                    .monospacedDigit()
                                Spacer()
                                Text(formatTime(material.duration))
                                    .font(.caption)
                                    .monospacedDigit()
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        // 再生コントロール
                        HStack(spacing: 30) {
                            Button {
                                seekBackward()
                            } label: {
                                Image(systemName: "gobackward.10")
                                    .font(.title2)
                            }
                            
                            Button {
                                if isPlaying {
                                    pauseAudio()
                                } else {
                                    playAudio()
                                }
                            } label: {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 50))
                            }
                            
                            Button {
                                seekForward()
                            } label: {
                                Image(systemName: "goforward.10")
                                    .font(.title2)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 文字起こしセクション
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("文字起こし")
                                .font(.headline)
                            Spacer()
                            if material.isTranscribing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        if let transcription = material.transcription {
                            Text(transcription)
                                .font(.body)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                        } else if material.isTranscribing {
                            Text("文字起こし中...")
                                .foregroundColor(.secondary)
                                .italic()
                        } else if let error = material.transcriptionError {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("文字起こしエラー", systemImage: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("文字起こしがありません")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 練習統計
                    if material.practiceCount > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("練習統計")
                                .font(.headline)
                            
                            HStack(spacing: 30) {
                                StatItem(
                                    title: "練習回数",
                                    value: "\(material.practiceCount)",
                                    icon: "checkmark.circle"
                                )
                                
                                if let averageScore = material.averageScore {
                                    StatItem(
                                        title: "平均スコア",
                                        value: String(format: "%.1f%%", averageScore),
                                        icon: "star.fill"
                                    )
                                }
                                
                                if let lastPracticed = material.lastPracticedAt {
                                    StatItem(
                                        title: "最終練習",
                                        value: formatRelativeDate(lastPracticed),
                                        icon: "calendar"
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("教材詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditTitle) {
                EditMaterialView(
                    title: $editedTitle,
                    memo: $editedMemo,
                    onSave: {
                        // TODO: 保存処理
                    }
                )
            }
        }
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            audioPlayer?.stop()
        }
    }
    
    private func setupAudioPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: material.url)
            audioPlayer?.prepareToPlay()
        } catch {
            print("音声ファイルの読み込みエラー: \(error)")
        }
    }
    
    private func playAudio() {
        audioPlayer?.play()
        isPlaying = true
        startPlaybackTimer()
    }
    
    private func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    private func seekBackward() {
        guard let player = audioPlayer else { return }
        let newTime = max(0, player.currentTime - 10)
        player.currentTime = newTime
        updatePlaybackProgress()
    }
    
    private func seekForward() {
        guard let player = audioPlayer else { return }
        let newTime = min(player.duration, player.currentTime + 10)
        player.currentTime = newTime
        updatePlaybackProgress()
    }
    
    private func startPlaybackTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard let player = audioPlayer else {
                timer.invalidate()
                return
            }
            
            if !player.isPlaying {
                timer.invalidate()
                isPlaying = false
            }
            
            updatePlaybackProgress()
        }
    }
    
    private func updatePlaybackProgress() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
        playbackProgress = player.currentTime / player.duration
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// 情報行
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
        }
    }
}

// 統計アイテム
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// 編集ビュー
struct EditMaterialView: View {
    @Binding var title: String
    @Binding var memo: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("タイトル") {
                    TextField("タイトル", text: $title)
                }
                
                Section("メモ") {
                    TextEditor(text: $memo)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("教材を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// Preview
struct MaterialDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MaterialDetailView(material: Material.sampleData[0])
    }
}