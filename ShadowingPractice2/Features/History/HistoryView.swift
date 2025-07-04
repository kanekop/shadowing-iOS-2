import SwiftUI

enum TimePeriod: String, CaseIterable {
    case today = "今日"
    case week = "今週"
    case month = "今月"
    case all = "すべて"
}

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var selectedPeriod: TimePeriod = .week
    @State private var selectedResult: PracticeResult?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 統計サマリー
                StatisticsSummaryView(
                    statistics: viewModel.statistics,
                    period: selectedPeriod
                )
                .padding()
                
                // 期間選択
                Picker("期間", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: selectedPeriod) { _ in
                    viewModel.loadHistory(for: selectedPeriod)
                }
                
                // 履歴リスト
                if viewModel.isLoading {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.practiceResults.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(groupedResults(), id: \.key) { date, results in
                            Section(header: Text(formatSectionDate(date))) {
                                ForEach(results) { result in
                                    HistoryRow(result: result) {
                                        selectedResult = result
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("練習履歴")
            .sheet(item: $selectedResult) { result in
                PracticeResultView(result: result) {
                    // もう一度練習
                }
            }
        }
        .onAppear {
            viewModel.loadHistory(for: selectedPeriod)
        }
    }
    
    private func groupedResults() -> [(key: Date, value: [PracticeResult])] {
        let grouped = Dictionary(grouping: viewModel.practiceResults) { result in
            Calendar.current.startOfDay(for: result.recordedAt)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        if Calendar.current.isDateInToday(date) {
            return "今日"
        } else if Calendar.current.isDateInYesterday(date) {
            return "昨日"
        } else {
            formatter.dateFormat = "M月d日(E)"
            return formatter.string(from: date)
        }
    }
}

// 統計サマリービュー
struct StatisticsSummaryView: View {
    let statistics: HistoryStatistics
    let period: TimePeriod
    
    var body: some View {
        VStack(spacing: 16) {
            Text("\(period.rawValue)の統計")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatisticCard(
                    title: "練習回数",
                    value: "\(statistics.totalPractices)",
                    unit: "回",
                    icon: "checkmark.circle.fill",
                    color: .blue
                )
                
                StatisticCard(
                    title: "練習時間",
                    value: formatTotalTime(statistics.totalDuration),
                    unit: "",
                    icon: "clock.fill",
                    color: .orange
                )
                
                StatisticCard(
                    title: "平均スコア",
                    value: String(format: "%.1f", statistics.averageScore),
                    unit: "点",
                    icon: "star.fill",
                    color: .yellow
                )
            }
            
            // 進捗グラフ（将来実装）
            if statistics.totalPractices > 0 {
                ProgressGraphView(data: statistics.dailyPractices)
                    .frame(height: 100)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func formatTotalTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        
        if hours > 0 {
            return String(format: "%d時間%d分", hours, minutes)
        } else {
            return String(format: "%d分", minutes)
        }
    }
}

// 統計カード
struct StatisticCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            HStack(spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// 進捗グラフビュー（簡易版）
struct ProgressGraphView: View {
    let data: [DailyPractice]
    
    var maxCount: Int {
        data.map { $0.count }.max() ?? 1
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(data.suffix(7), id: \.date) { daily in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: 30, height: barHeight(for: daily.count))
                    
                    Text(formatDayLabel(daily.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func barHeight(for count: Int) -> CGFloat {
        guard maxCount > 0 else { return 0 }
        return CGFloat(count) / CGFloat(maxCount) * 60 + 10
    }
    
    private func formatDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// 空の履歴ビュー
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("練習履歴がありません")
                .font(.headline)
            
            Text("練習を始めると\nここに履歴が表示されます")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 履歴行
struct HistoryRow: View {
    let result: PracticeResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // アイコン
                ZStack {
                    Circle()
                        .fill(scoreColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(String(format: "%.0f", result.score))
                        .font(.headline)
                        .foregroundColor(scoreColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.practiceType == .reading ? "音読練習" : "シャドウィング練習")
                        .font(.headline)
                    
                    HStack {
                        Label(formatTime(result.recordedAt), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(formatDuration(result.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var scoreColor: Color {
        if result.score >= 90 {
            return .green
        } else if result.score >= 70 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// ViewModel
@MainActor
class HistoryViewModel: ObservableObject {
    @Published var practiceResults: [PracticeResult] = []
    @Published var statistics = HistoryStatistics()
    @Published var isLoading = false
    
    private let historyService = PracticeHistoryService.shared
    
    func loadHistory(for period: TimePeriod) {
        isLoading = true
        
        Task {
            // 実際のデータを読み込む
            await historyService.loadAllPracticeResults()
            
            // 期間でフィルタリング
            let filteredResults = filterResultsByPeriod(
                historyService.practiceResults,
                period: period
            )
            
            practiceResults = filteredResults
            statistics = calculateStatistics(from: filteredResults)
            
            isLoading = false
        }
    }
    
    private func filterResultsByPeriod(_ results: [PracticeResult], period: TimePeriod) -> [PracticeResult] {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .today:
            let startOfToday = calendar.startOfDay(for: now)
            return results.filter { $0.createdAt >= startOfToday }
            
        case .week:
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return results }
            return results.filter { $0.createdAt >= weekAgo }
            
        case .month:
            guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return results }
            return results.filter { $0.createdAt >= monthAgo }
            
        case .all:
            return results
        }
    }
    
    
    private func calculateStatistics(from results: [PracticeResult]) -> HistoryStatistics {
        var stats = HistoryStatistics()
        
        stats.totalPractices = results.count
        stats.totalDuration = results.reduce(0) { $0 + $1.duration }
        
        if !results.isEmpty {
            stats.averageScore = results.reduce(0) { $0 + $1.score } / Double(results.count)
        }
        
        // 日別練習回数
        let grouped = Dictionary(grouping: results) { result in
            Calendar.current.startOfDay(for: result.recordedAt)
        }
        
        stats.dailyPractices = grouped.map { date, practices in
            DailyPractice(date: date, count: practices.count)
        }.sorted { $0.date < $1.date }
        
        return stats
    }
}

// 統計データ
struct HistoryStatistics {
    var totalPractices: Int = 0
    var totalDuration: TimeInterval = 0
    var averageScore: Double = 0
    var dailyPractices: [DailyPractice] = []
}

struct DailyPractice {
    let date: Date
    let count: Int
}

// Preview
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
