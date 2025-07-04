import SwiftUI

struct DiffView: View {
    let result: PracticeResult
    @State private var showLegend = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 凡例
                if showLegend {
                    LegendView()
                        .padding(.horizontal)
                }
                
                // Diff表示
                if !result.wordAnalysis.isEmpty {
                    DiffContentView(wordAnalysis: result.wordAnalysis)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                } else {
                    // 教材テキストがない場合
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("差分表示できません")
                            .font(.headline)
                        
                        Text("教材に文字起こしがないため\n差分を表示できません")
                            .multilineTextAlignment(.center)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
                
                // 統計情報
                if !result.wordAnalysis.isEmpty {
                    DiffStatisticsView(wordAnalysis: result.wordAnalysis)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// 凡例ビュー
struct LegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("凡例")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                LegendItem(color: .primary, text: "正解")
                LegendItem(color: .red, text: "削除", strikethrough: true)
                LegendItem(color: .green, text: "挿入", background: true)
                LegendItem(color: .orange, text: "置換", underline: true)
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// 凡例アイテム
struct LegendItem: View {
    let color: Color
    let text: String
    var strikethrough: Bool = false
    var background: Bool = false
    var underline: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color.opacity(background ? 0.2 : 1.0))
                .frame(width: 8, height: 8)
            
            Text(text)
                .foregroundColor(color)
                .strikethrough(strikethrough)
                .underline(underline)
                .background(background ? color.opacity(0.2) : Color.clear)
                .padding(.horizontal, background ? 4 : 0)
        }
    }
}

// Diff内容表示
struct DiffContentView: View {
    let wordAnalysis: [WordAnalysis]
    @State private var visibleWords: Set<Int> = []
    
    var body: some View {
        WrappingHStack(alignment: .leading, spacing: 6) {
            ForEach(Array(wordAnalysis.enumerated()), id: \.offset) { index, analysis in
                DiffWordView(analysis: analysis)
                    .opacity(visibleWords.contains(index) ? 1 : 0)
                    .scaleEffect(visibleWords.contains(index) ? 1 : 0.8)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.8)
                        .delay(Double(index) * 0.02),
                        value: visibleWords.contains(index)
                    )
            }
        }
        .onAppear {
            // 順番にアニメーション表示
            for i in 0..<wordAnalysis.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                    visibleWords.insert(i)
                }
            }
        }
    }
}

// Diff単語ビュー
struct DiffWordView: View {
    let analysis: WordAnalysis
    
    var body: some View {
        Group {
            switch analysis.type {
            case .correct:
                Text(analysis.word + " ")
                    .foregroundColor(.primary)
                
            case .incorrect:
                Text(analysis.word + " ")
                    .padding(.horizontal, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
                
            case .missing:
                Text(analysis.word + " ")
                    .strikethrough()
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
                
            case .extra:
                Text("[" + analysis.word + "] ")
                    .padding(.horizontal, 4)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .cornerRadius(4)
            }
        }
        .font(.body)
    }
}

// ラッピングHStack（単語の折り返し用）
struct WrappingHStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    let content: Content
    
    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            content
                .fixedSize()
                .alignmentGuide(.leading) { dimensions in
                    if abs(width - dimensions.width) > geometry.size.width {
                        width = 0
                        height -= dimensions.height
                    }
                    let result = width
                    if dimensions.width < geometry.size.width {
                        width -= dimensions.width + spacing
                    } else {
                        width = 0
                    }
                    return result
                }
                .alignmentGuide(.top) { _ in
                    let result = height
                    if width == 0 {
                        height -= spacing
                    }
                    return result
                }
        }
    }
}

// Diff統計ビュー
struct DiffStatisticsView: View {
    let wordAnalysis: [WordAnalysis]
    
    var statistics: (correct: Int, incorrect: Int, missing: Int, extra: Int) {
        var correct = 0
        var incorrect = 0
        var missing = 0
        var extra = 0
        
        for analysis in wordAnalysis {
            switch analysis.type {
            case .correct:
                correct += 1
            case .incorrect:
                incorrect += 1
            case .missing:
                missing += 1
            case .extra:
                extra += 1
            }
        }
        
        return (correct, incorrect, missing, extra)
    }
    
    var totalWords: Int {
        wordAnalysis.filter { $0.type != .extra }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("差分統計")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatisticItem(
                    label: "正解",
                    count: statistics.correct,
                    total: totalWords,
                    color: .green
                )
                
                StatisticItem(
                    label: "間違い",
                    count: statistics.incorrect,
                    total: totalWords,
                    color: .orange
                )
                
                StatisticItem(
                    label: "欠落",
                    count: statistics.missing,
                    total: totalWords,
                    color: .red
                )
                
                StatisticItem(
                    label: "余分",
                    count: statistics.extra,
                    total: nil,
                    color: .purple
                )
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// 統計アイテム
struct StatisticItem: View {
    let label: String
    let count: Int
    let total: Int?
    let color: Color
    
    var percentage: String? {
        guard let total = total, total > 0 else { return nil }
        return String(format: "%.0f%%", Double(count) / Double(total) * 100)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            if let percentage = percentage {
                Text(percentage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Preview
struct DiffView_Previews: PreviewProvider {
    static var previews: some View {
        DiffView(result: PracticeResult.sampleData)
    }
}