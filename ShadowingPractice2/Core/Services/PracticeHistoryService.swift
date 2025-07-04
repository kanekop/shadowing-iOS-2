//
//  PracticeHistoryService.swift
//  ShadowingPractice2
//
//  Created by Apple on 2025/07/04.
//

import Foundation
import Combine

/// 練習履歴を管理するサービス
class PracticeHistoryService: ObservableObject {
    // MARK: - Singleton
    static let shared = PracticeHistoryService()
    
    // MARK: - Published Properties
    @Published var practiceResults: [PracticeResult] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    private let logger = Logger.shared
    private let fileManager = FileManager.default
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    private init() {
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Public Methods
    
    /// すべての練習結果を読み込む
    func loadAllPracticeResults() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let results = try await loadPracticeResultsFromDisk()
            await MainActor.run {
                self.practiceResults = results.sorted { $0.createdAt > $1.createdAt }
                self.isLoading = false
            }
            logger.info("Loaded \(results.count) practice results")
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            logger.error("Failed to load practice results: \(error)")
        }
    }
    
    /// 特定の教材の練習結果を取得
    func getPracticeResults(for materialId: UUID) -> [PracticeResult] {
        return practiceResults.filter { $0.materialId == materialId }
    }
    
    /// 練習結果を削除
    func deletePracticeResult(_ result: PracticeResult) async throws {
        let practicesDir = FileManager.practicesDirectory
        let resultFile = practicesDir.appendingPathComponent("\(result.id.uuidString).json")
        
        try fileManager.removeItem(at: resultFile)
        
        await MainActor.run {
            practiceResults.removeAll { $0.id == result.id }
        }
        
        logger.info("Deleted practice result: \(result.id)")
    }
    
    /// 練習統計を計算
    func calculateStatistics() -> PracticeStatistics {
        let totalSessions = practiceResults.count
        let totalDuration = practiceResults.reduce(0) { $0 + $1.duration }
        let averageScore = practiceResults.isEmpty ? 0 : 
            practiceResults.reduce(0) { $0 + $1.overallScore } / Double(totalSessions)
        
        // 今日の練習
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayResults = practiceResults.filter { 
            calendar.isDate($0.createdAt, inSameDayAs: today) 
        }
        
        // 週間統計
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        let weekResults = practiceResults.filter { $0.createdAt >= weekAgo }
        
        return PracticeStatistics(
            totalSessions: totalSessions,
            totalDuration: totalDuration,
            averageScore: averageScore,
            todaySessions: todayResults.count,
            todayDuration: todayResults.reduce(0) { $0 + $1.duration },
            weekSessions: weekResults.count,
            weekDuration: weekResults.reduce(0) { $0 + $1.duration },
            recentResults: Array(practiceResults.prefix(10))
        )
    }
    
    // MARK: - Private Methods
    
    private func loadPracticeResultsFromDisk() async throws -> [PracticeResult] {
        let practicesDir = FileManager.practicesDirectory
        
        // FileManager.practicesDirectoryは既に必要に応じてディレクトリを作成するので、
        // 追加のチェックは不要
        
        // すべてのJSONファイルを取得
        let contents = try fileManager.contentsOfDirectory(
            at: practicesDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )
        
        let jsonFiles = contents.filter { $0.pathExtension == "json" }
        
        // 並列で読み込み
        let results = await withTaskGroup(of: PracticeResult?.self) { group in
            for fileURL in jsonFiles {
                group.addTask {
                    do {
                        let data = try Data(contentsOf: fileURL)
                        return try self.decoder.decode(PracticeResult.self, from: data)
                    } catch {
                        self.logger.error("Failed to decode practice result from \(fileURL): \(error)")
                        return nil
                    }
                }
            }
            
            var results: [PracticeResult] = []
            for await result in group {
                if let result = result {
                    results.append(result)
                }
            }
            return results
        }
        
        return results
    }
}

// MARK: - Practice Statistics
struct PracticeStatistics {
    let totalSessions: Int
    let totalDuration: TimeInterval
    let averageScore: Double
    let todaySessions: Int
    let todayDuration: TimeInterval
    let weekSessions: Int
    let weekDuration: TimeInterval
    let recentResults: [PracticeResult]
    
    var formattedTotalDuration: String {
        formatDuration(totalDuration)
    }
    
    var formattedTodayDuration: String {
        formatDuration(todayDuration)
    }
    
    var formattedWeekDuration: String {
        formatDuration(weekDuration)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d時間%d分", hours, minutes)
        } else {
            return String(format: "%d分", minutes)
        }
    }
}