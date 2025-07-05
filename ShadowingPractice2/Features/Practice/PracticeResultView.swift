import SwiftUI
import AVFoundation

struct PracticeResultView: View {
    let result: PracticeResult
    let onRetry: () -> Void
    
    @State private var selectedTab = 0
    @State private var isPlayingRecording = false
    @State private var audioPlayer: AVAudioPlayer?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // スコアヘッダー
                ScoreHeaderView(score: result.score)
                    .padding(DesignSystem.Spacing.md)
                
                // タブ選択
                Picker("結果表示", selection: $selectedTab) {
                    Text("詳細").tag(0)
                    Text("差分").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.xs)
                
                // コンテンツ
                TabView(selection: $selectedTab) {
                    // 詳細タブ (概要と詳細を統合)
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            // メトリクスグリッド
                            MetricsGridView(result: result)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // 認識されたテキスト
                            if !result.recognizedText.isEmpty {
                                CardView {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                        Text("認識されたテキスト")
                                            .font(DesignSystem.Typography.h4)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        
                                        Text(result.recognizedText)
                                            .font(DesignSystem.Typography.bodyMedium)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                    }
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                            }
                        }
                        .padding(.vertical, DesignSystem.Spacing.md)
                    }
                    .tag(0)
                    
                    // 差分タブ
                    DiffView(result: result)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // アクションボタン
                HStack(spacing: DesignSystem.Spacing.md) {
                    // 録音再生ボタン
                    SecondaryButton(title: isPlayingRecording ? "停止" : "録音を再生", action: togglePlayback)
                    
                    // もう一度ボタン
                    PrimaryButton(title: "もう一度", action: {
                        onRetry()
                        dismiss()
                    })
                }
                .padding(DesignSystem.Spacing.md)
            }
            .navigationTitle("練習結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    TextButton(title: "完了", action: { dismiss() })
                }
            }
        }
        .onDisappear {
            audioPlayer?.stop()
        }
    }
    
    private func togglePlayback() {
        if isPlayingRecording {
            audioPlayer?.stop()
            isPlayingRecording = false
        } else {
            playRecording()
        }
    }
    
    private func playRecording() {
        guard let recordingURL = result.recordingURL else {
            print("録音ファイルが見つかりません")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
            audioPlayer?.delegate = nil
            audioPlayer?.play()
            isPlayingRecording = true
            
            // 再生終了を監視
            DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 0)) {
                isPlayingRecording = false
            }
        } catch {
            print("録音再生エラー: \(error)")
        }
    }
}

// スコアヘッダー
struct ScoreHeaderView: View {
    let score: Double
    
    var scoreColor: Color {
        if score >= 90 {
            return DesignSystem.Colors.success
        } else if score >= 70 {
            return DesignSystem.Colors.warning
        } else {
            return DesignSystem.Colors.error
        }
    }
    
    var body: some View {
        CardView {
            VStack(spacing: DesignSystem.Spacing.md) {
                // スコアサークル
                ZStack {
                    ProgressCircleView(
                        value: score,
                        total: 100,
                        size: DesignSystem.Size.progressCircleLarge,
                        lineWidth: 12,
                        strokeColor: scoreColor
                    )
                    
                    VStack(spacing: DesignSystem.Spacing.xxs) {
                        Text(String(format: "%.1f", score))
                            .font(DesignSystem.Typography.displayMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("点")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                // 評価メッセージ
                Text(getEvaluationMessage(score: score))
                    .font(DesignSystem.Typography.bodyLarge)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func getEvaluationMessage(score: Double) -> String {
        if score >= 95 {
            return "素晴らしい！ほぼ完璧です！"
        } else if score >= 90 {
            return "とても良いです！"
        } else if score >= 80 {
            return "良くできました！"
        } else if score >= 70 {
            return "もう少しで上達します！"
        } else if score >= 60 {
            return "練習を続けましょう！"
        } else {
            return "がんばりましょう！"
        }
    }
}

// 概要ビュー (古いコード - 使用されていない)
struct SummaryView: View {
    let result: PracticeResult
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 基本情報
                VStack(spacing: 16) {
                    HStack(spacing: 30) {
                        MetricItem(
                            title: "正解率",
                            value: String(format: "%.1f%%", result.accuracy),
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        MetricItem(
                            title: "WPM",
                            value: "\(Int(result.wordsPerMinute))",
                            icon: "speedometer",
                            color: .blue
                        )
                        
                        MetricItem(
                            title: "時間",
                            value: formatDuration(result.duration),
                            icon: "clock.fill",
                            color: .orange
                        )
                    }
                    
                    if result.fluencyScore > 0 || result.pronunciationScore > 0 {
                        HStack(spacing: 30) {
                            MetricItem(
                                title: "流暢さ",
                                value: String(format: "%.0f%%", result.fluencyScore),
                                icon: "waveform",
                                color: .purple
                            )
                            
                            MetricItem(
                                title: "発音",
                                value: String(format: "%.0f%%", result.pronunciationScore),
                                icon: "mic.fill",
                                color: .pink
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // フィードバック
                FeedbackSection(result: result)
            }
            .padding()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// メトリックグリッドビュー
struct MetricsGridView: View {
    let result: PracticeResult
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.md) {
            MetricItem(
                title: "認識精度",
                value: String(format: "%.1f%%", result.accuracy),
                icon: "checkmark.circle.fill",
                color: DesignSystem.Colors.success
            )
            
            MetricItem(
                title: "単語数",
                value: "\(result.totalWords)",
                icon: "text.word.spacing",
                color: DesignSystem.Colors.info
            )
            
            MetricItem(
                title: "所要時間",
                value: formatDuration(result.duration),
                icon: "clock.fill",
                color: DesignSystem.Colors.warning
            )
            
            MetricItem(
                title: "WPM",
                value: "\(Int(result.wordsPerMinute))",
                icon: "speedometer",
                color: DesignSystem.Colors.accent
            )
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// メトリックアイテム
struct MetricItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        CardView {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.Size.iconMedium))
                    .foregroundColor(color)
                
                Text(value)
                    .font(DesignSystem.Typography.h4)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// フィードバックセクション
struct FeedbackSection: View {
    let result: PracticeResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("フィードバック")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                // 良かった点
                if result.accuracy >= 80 {
                    FeedbackItem(
                        type: .positive,
                        message: "単語の認識率が高く、正確に発音できています"
                    )
                }
                
                if result.wordsPerMinute >= 100 {
                    FeedbackItem(
                        type: .positive,
                        message: "適切なスピードで話せています"
                    )
                }
                
                // 改善点
                if result.accuracy < 70 {
                    FeedbackItem(
                        type: .improvement,
                        message: "もう少しゆっくり、はっきりと発音してみましょう"
                    )
                }
                
                if result.wordErrorRate > 0.3 {
                    FeedbackItem(
                        type: .improvement,
                        message: "間違えやすい単語を重点的に練習しましょう"
                    )
                }
                
                if result.wordsPerMinute < 80 {
                    FeedbackItem(
                        type: .improvement,
                        message: "もう少しスムーズに話せるよう練習しましょう"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// フィードバックアイテム
struct FeedbackItem: View {
    enum FeedbackType {
        case positive, improvement
        
        var icon: String {
            switch self {
            case .positive: return "checkmark.circle.fill"
            case .improvement: return "lightbulb.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .improvement: return .orange
            }
        }
    }
    
    let type: FeedbackType
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.body)
            
            Text(message)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// 詳細ビュー
struct DetailView: View {
    let result: PracticeResult
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 認識されたテキスト
                VStack(alignment: .leading, spacing: 8) {
                    Text("認識されたテキスト")
                        .font(.headline)
                    
                    Text(result.recognizedText)
                        .font(.body)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
                // 詳細統計
                VStack(alignment: .leading, spacing: 12) {
                    Text("詳細統計")
                        .font(.headline)
                    
                    DetailRow(label: "単語エラー率", value: String(format: "%.1f%%", result.wordErrorRate * 100))
                    DetailRow(label: "認識単語数", value: "\(result.recognizedText.split(separator: " ").count)語")
                    DetailRow(label: "練習時間", value: formatDetailDuration(result.duration))
                    DetailRow(label: "練習タイプ", value: result.practiceType == PracticeMode.reading ? "音読" : "シャドウィング")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    private func formatDetailDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%d分%02d.%02d秒", minutes, seconds, milliseconds)
    }
}

// 詳細行
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// Preview
struct PracticeResultView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeResultView(
            result: PracticeResult.sample,
            onRetry: {}
        )
    }
}