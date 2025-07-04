//
//  WordAnalysis.swift
//  ShadowingPractice2
//
//  Created by Apple on 2025/07/04.
//

import Foundation

/// 単語レベルの分析結果
/// 
/// Diff表示のための各単語の状態を表現する
struct WordAnalysis: Codable, Identifiable {
    let id: UUID
    let word: String
    let type: DiffType
    let position: Int
    
    /// 差分タイプ
    enum DiffType: String, Codable {
        case correct = "correct"      // 正しい
        case incorrect = "incorrect"  // 間違い
        case missing = "missing"      // 欠落
        case extra = "extra"          // 余分
        
        var color: String {
            switch self {
            case .correct: return "systemGreen"
            case .incorrect: return "systemOrange"
            case .missing: return "systemRed"
            case .extra: return "systemPurple"
            }
        }
        
        var symbolName: String {
            switch self {
            case .correct: return "checkmark.circle.fill"
            case .incorrect: return "exclamationmark.triangle.fill"
            case .missing: return "minus.circle.fill"
            case .extra: return "plus.circle.fill"
            }
        }
    }
    
    /// 新しい単語分析を作成
    init(
        id: UUID = UUID(),
        word: String,
        type: DiffType,
        position: Int
    ) {
        self.id = id
        self.word = word
        self.type = type
        self.position = position
    }
}

// MARK: - Computed Properties
extension WordAnalysis {
    /// 正しい単語かどうか
    var isCorrect: Bool {
        type == .correct
    }
    
    /// エラーかどうか
    var isError: Bool {
        type != .correct
    }
}

// MARK: - Word Analysis Result Container
/// 単語分析結果のコンテナ
struct WordAnalysisResult {
    let originalWords: [String]
    let recognizedWords: [String]
    let analysis: [WordAnalysis]
    
    /// 編集距離（レーベンシュタイン距離）を計算
    static func calculateEditDistance(from: [String], to: [String]) -> Int {
        let m = from.count
        let n = to.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            matrix[i][0] = i
        }
        
        for j in 0...n {
            matrix[0][j] = j
        }
        
        for i in 1...m {
            for j in 1...n {
                if from[i-1].lowercased() == to[j-1].lowercased() {
                    matrix[i][j] = matrix[i-1][j-1]
                } else {
                    matrix[i][j] = min(
                        matrix[i-1][j] + 1,    // 削除
                        matrix[i][j-1] + 1,    // 挿入
                        matrix[i-1][j-1] + 1   // 置換
                    )
                }
            }
        }
        
        return matrix[m][n]
    }
}

// MARK: - Sample Data
#if DEBUG
extension WordAnalysis {
    static let sampleData: [WordAnalysis] = [
        WordAnalysis(word: "Hello", type: .correct, position: 0),
        WordAnalysis(word: "world", type: .incorrect, position: 1),
        WordAnalysis(word: "this", type: .missing, position: 2),
        WordAnalysis(word: "extra", type: .extra, position: 3)
    ]
}
#endif