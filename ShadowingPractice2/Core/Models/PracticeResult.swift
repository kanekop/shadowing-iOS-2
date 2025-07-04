//
//  PracticeResult.swift
//  ShadowingPractice2
//
//  Created by Apple on 2025/07/04.
//

import Foundation

/// 練習結果の評価データモデル
/// 
/// 音声認識結果と評価スコアを保持する
struct PracticeResult: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let materialId: UUID  // 教材との関連付け
    
    // 認識結果
    let recognizedText: String
    let originalText: String
    
    // 練習情報
    let recordingURL: URL?
    let duration: TimeInterval
    var practiceType: PracticeMode
    
    // 評価スコア
    let overallScore: Double        // 0.0 - 100.0
    let accuracyScore: Double       // 正確性スコア
    let fluencyScore: Double        // 流暢性スコア
    let pronunciationScore: Double  // 発音スコア（将来実装）
    
    // 詳細分析
    let wordAnalysis: [WordAnalysis]
    let totalWords: Int
    let correctWords: Int
    let incorrectWords: Int
    let missingWords: Int
    let extraWords: Int
    
    /// 新しい練習結果を作成
    init(
        id: UUID = UUID(),
        materialId: UUID,
        recognizedText: String,
        originalText: String,
        wordAnalysis: [WordAnalysis],
        recordingURL: URL? = nil,
        duration: TimeInterval = 0,
        practiceType: PracticeMode = .reading
    ) {
        self.id = id
        self.createdAt = Date()
        self.materialId = materialId
        self.recognizedText = recognizedText
        self.originalText = originalText
        self.wordAnalysis = wordAnalysis
        self.recordingURL = recordingURL
        self.duration = duration
        self.practiceType = practiceType
        
        // スコア計算
        let (accuracy, fluency, overall) = Self.calculateScores(
            wordAnalysis: wordAnalysis,
            originalText: originalText,
            recognizedText: recognizedText
        )
        
        self.accuracyScore = accuracy
        self.fluencyScore = fluency
        self.overallScore = overall
        self.pronunciationScore = 0 // 将来実装
        
        // 統計計算
        self.totalWords = wordAnalysis.count
        self.correctWords = wordAnalysis.filter { $0.isCorrect }.count
        self.incorrectWords = wordAnalysis.filter { $0.type == .incorrect }.count
        self.missingWords = wordAnalysis.filter { $0.type == .missing }.count
        self.extraWords = wordAnalysis.filter { $0.type == .extra }.count
    }
    
    /// スコアを計算
    private static func calculateScores(
        wordAnalysis: [WordAnalysis],
        originalText: String,
        recognizedText: String
    ) -> (accuracy: Double, fluency: Double, overall: Double) {
        guard !wordAnalysis.isEmpty else {
            return (0, 0, 0)
        }
        
        // 正確性スコア：正しい単語の割合
        let correctCount = Double(wordAnalysis.filter { $0.isCorrect }.count)
        let totalCount = Double(wordAnalysis.count)
        let accuracy = (correctCount / totalCount) * 100
        
        // 流暢性スコア：連続して正しい単語の割合を考慮
        var consecutiveCorrect = 0
        var maxConsecutive = 0
        var fluencyBonus = 0.0
        
        for word in wordAnalysis {
            if word.isCorrect {
                consecutiveCorrect += 1
                maxConsecutive = max(maxConsecutive, consecutiveCorrect)
            } else {
                consecutiveCorrect = 0
            }
        }
        
        // 連続正解ボーナス
        if totalCount > 0 {
            fluencyBonus = Double(maxConsecutive) / totalCount * 20
        }
        
        let fluency = min(accuracy + fluencyBonus, 100)
        
        // 総合スコア
        let overall = accuracy * 0.7 + fluency * 0.3
        
        return (accuracy, fluency, overall)
    }
}

// MARK: - Computed Properties
extension PracticeResult {
    /// スコアのグレード表示
    var grade: String {
        switch overallScore {
        case 90...100: return "S"
        case 80..<90: return "A"
        case 70..<80: return "B"
        case 60..<70: return "C"
        default: return "D"
        }
    }
    
    /// スコアの色
    var gradeColor: String {
        switch overallScore {
        case 90...100: return "systemGreen"
        case 80..<90: return "systemBlue"
        case 70..<80: return "systemYellow"
        case 60..<70: return "systemOrange"
        default: return "systemRed"
        }
    }
    
    /// 正答率
    var accuracyRate: Double {
        guard totalWords > 0 else { return 0 }
        return Double(correctWords) / Double(totalWords) * 100
    }
    
    /// スコア（overallScoreのエイリアス）
    var score: Double {
        return overallScore
    }
    
    /// 正確性（accuracyScoreのエイリアス）
    var accuracy: Double {
        return accuracyScore
    }
    
    /// 単語エラー率
    var wordErrorRate: Double {
        guard totalWords > 0 else { return 0 }
        return Double(incorrectWords + missingWords) / Double(totalWords)
    }
    
    /// 1分あたりの単語数（WPM）
    var wordsPerMinute: Double {
        guard duration > 0 else { return 0 }
        let recognizedWordCount = recognizedText.split(separator: " ").count
        return Double(recognizedWordCount) / (duration / 60.0)
    }
    
    /// createdAtのエイリアス（互換性のため）
    var recordedAt: Date { createdAt }
}

// MARK: - Sample Data
#if DEBUG
extension PracticeResult {
    static let sampleData = PracticeResult(
        materialId: UUID(),
        recognizedText: "This is a sample text",
        originalText: "This is a sample text for testing",
        wordAnalysis: [
            WordAnalysis(word: "This", type: .correct, position: 0),
            WordAnalysis(word: "is", type: .correct, position: 1),
            WordAnalysis(word: "a", type: .correct, position: 2),
            WordAnalysis(word: "sample", type: .correct, position: 3),
            WordAnalysis(word: "text", type: .correct, position: 4),
            WordAnalysis(word: "for", type: .missing, position: 5),
            WordAnalysis(word: "testing", type: .missing, position: 6)
        ],
        recordingURL: nil,
        duration: 15.5,
        practiceType: .reading
    )
    
    static let sample = sampleData // エイリアス
}
#endif
