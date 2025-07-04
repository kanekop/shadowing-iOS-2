//
//  TextComparisonService.swift
//  ShadowingPractice2
//
//  Created by Apple on 2025/07/04.
//

import Foundation

/// テキスト比較サービス
/// 
/// 原文と認識結果を比較し、差分分析と評価を行う
class TextComparisonService {
    
    // MARK: - Types
    
    /// 比較結果
    struct ComparisonResult {
        let originalWords: [String]
        let recognizedWords: [String]
        let wordAnalysis: [WordAnalysis]
        let overallScore: Double
        let accuracyScore: Double
        let fluencyScore: Double
        let editDistance: Int
    }
    
    /// 単語の正規化オプション
    struct NormalizationOptions {
        var caseSensitive: Bool = false
        var ignorePunctuation: Bool = true
        var trimWhitespace: Bool = true
        var expandContractions: Bool = true
    }
    
    // MARK: - Public Methods
    
    /// 2つのテキストを比較して分析結果を返す
    /// - Parameters:
    ///   - original: 原文
    ///   - recognized: 認識されたテキスト
    ///   - options: 正規化オプション
    /// - Returns: 比較結果
    func compareTexts(
        original: String,
        recognized: String,
        options: NormalizationOptions = NormalizationOptions()
    ) -> ComparisonResult {
        // テキストを単語に分割
        let originalWords = tokenizeText(original, options: options)
        let recognizedWords = tokenizeText(recognized, options: options)
        
        // 差分分析を実行
        let wordAnalysis = performDiffAnalysis(
            original: originalWords,
            recognized: recognizedWords
        )
        
        // スコア計算
        let scores = calculateScores(
            wordAnalysis: wordAnalysis,
            originalCount: originalWords.count,
            recognizedCount: recognizedWords.count
        )
        
        // 編集距離計算
        let editDistance = calculateEditDistance(
            from: originalWords,
            to: recognizedWords
        )
        
        return ComparisonResult(
            originalWords: originalWords,
            recognizedWords: recognizedWords,
            wordAnalysis: wordAnalysis,
            overallScore: scores.overall,
            accuracyScore: scores.accuracy,
            fluencyScore: scores.fluency,
            editDistance: editDistance
        )
    }
    
    // MARK: - Private Methods
    
    /// テキストを単語に分割
    private func tokenizeText(_ text: String, options: NormalizationOptions) -> [String] {
        var processedText = text
        
        // 空白の正規化
        if options.trimWhitespace {
            processedText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)
            processedText = processedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        }
        
        // 短縮形の展開
        if options.expandContractions {
            processedText = expandContractions(processedText)
        }
        
        // 単語に分割
        let words = processedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // 各単語を処理
        return words.map { word in
            var processedWord = word
            
            // 句読点の削除
            if options.ignorePunctuation {
                processedWord = removePunctuation(from: processedWord)
            }
            
            // 大文字小文字の処理
            if !options.caseSensitive {
                processedWord = processedWord.lowercased()
            }
            
            return processedWord
        }.filter { !$0.isEmpty }
    }
    
    /// 短縮形を展開
    private func expandContractions(_ text: String) -> String {
        let contractions = [
            "don't": "do not",
            "won't": "will not",
            "can't": "cannot",
            "isn't": "is not",
            "aren't": "are not",
            "wasn't": "was not",
            "weren't": "were not",
            "hasn't": "has not",
            "haven't": "have not",
            "hadn't": "had not",
            "doesn't": "does not",
            "didn't": "did not",
            "wouldn't": "would not",
            "couldn't": "could not",
            "shouldn't": "should not",
            "mightn't": "might not",
            "mustn't": "must not",
            "I'm": "I am",
            "you're": "you are",
            "he's": "he is",
            "she's": "she is",
            "it's": "it is",
            "we're": "we are",
            "they're": "they are",
            "I've": "I have",
            "you've": "you have",
            "we've": "we have",
            "they've": "they have",
            "I'd": "I would",
            "you'd": "you would",
            "he'd": "he would",
            "she'd": "she would",
            "we'd": "we would",
            "they'd": "they would",
            "I'll": "I will",
            "you'll": "you will",
            "he'll": "he will",
            "she'll": "she will",
            "we'll": "we will",
            "they'll": "they will"
        ]
        
        var result = text
        for (contraction, expanded) in contractions {
            result = result.replacingOccurrences(
                of: "\\b\(contraction)\\b",
                with: expanded,
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        return result
    }
    
    /// 句読点を削除
    private func removePunctuation(from word: String) -> String {
        let punctuation = CharacterSet.punctuationCharacters.union(.symbols)
        return word.trimmingCharacters(in: punctuation)
    }
    
    /// 差分分析を実行（動的計画法によるLCS）
    private func performDiffAnalysis(
        original: [String],
        recognized: [String]
    ) -> [WordAnalysis] {
        // LCS（最長共通部分列）アルゴリズムを使用
        let m = original.count
        let n = recognized.count
        
        // DPテーブル
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        // LCSの長さを計算
        for i in 1...m {
            for j in 1...n {
                if original[i-1] == recognized[j-1] {
                    dp[i][j] = dp[i-1][j-1] + 1
                } else {
                    dp[i][j] = max(dp[i-1][j], dp[i][j-1])
                }
            }
        }
        
        // バックトラックして差分を生成
        var result: [WordAnalysis] = []
        var i = m
        var j = n
        _ = 0
        
        _ = m - 1
        _ = n - 1
        
        // 逆順で解析してから反転
        var tempResult: [(word: String, type: WordAnalysis.DiffType)] = []
        
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && original[i-1] == recognized[j-1] {
                // 一致
                tempResult.append((word: original[i-1], type: .correct))
                i -= 1
                j -= 1
            } else if j > 0 && (i == 0 || dp[i][j-1] >= dp[i-1][j]) {
                // 余分な単語
                tempResult.append((word: recognized[j-1], type: .extra))
                j -= 1
            } else if i > 0 {
                // 欠落した単語
                tempResult.append((word: original[i-1], type: .missing))
                i -= 1
            }
        }
        
        // 結果を反転して正しい順序にする
        tempResult.reverse()
        
        // WordAnalysisオブジェクトを作成
        for (index, item) in tempResult.enumerated() {
            result.append(WordAnalysis(
                word: item.word,
                type: item.type,
                position: index
            ))
        }
        
        return result
    }
    
    /// 編集距離（レーベンシュタイン距離）を計算
    private func calculateEditDistance(from: [String], to: [String]) -> Int {
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
                if from[i-1] == to[j-1] {
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
    
    /// スコアを計算
    private func calculateScores(
        wordAnalysis: [WordAnalysis],
        originalCount: Int,
        recognizedCount: Int
    ) -> (accuracy: Double, fluency: Double, overall: Double) {
        guard originalCount > 0 else {
            return (0, 0, 0)
        }
        
        // 正確性スコア：正しい単語の割合
        let correctCount = wordAnalysis.filter { $0.type == .correct }.count
        let accuracy = Double(correctCount) / Double(originalCount) * 100
        
        // 流暢性スコア：連続性と余分な単語を考慮
        var consecutiveCorrect = 0
        var maxConsecutive = 0
        var fluencyPenalty = 0.0
        
        for word in wordAnalysis {
            if word.type == .correct {
                consecutiveCorrect += 1
                maxConsecutive = max(maxConsecutive, consecutiveCorrect)
            } else {
                consecutiveCorrect = 0
                if word.type == .extra {
                    fluencyPenalty += 5.0 // 余分な単語のペナルティ
                }
            }
        }
        
        // 連続正解ボーナス
        let consecutiveBonus = Double(maxConsecutive) / Double(originalCount) * 20
        
        // 流暢性スコア計算
        let fluency = max(0, min(100, accuracy + consecutiveBonus - fluencyPenalty))
        
        // 総合スコア（正確性70%、流暢性30%）
        let overall = accuracy * 0.7 + fluency * 0.3
        
        return (accuracy, fluency, overall)
    }
}

// MARK: - Convenience Extensions
extension TextComparisonService {
    /// シンプルな比較（デフォルトオプション使用）
    static func compare(_ original: String, with recognized: String) -> PracticeResult {
        let service = TextComparisonService()
        let comparison = service.compareTexts(original: original, recognized: recognized)
        
        return PracticeResult(
            recognizedText: recognized,
            originalText: original,
            wordAnalysis: comparison.wordAnalysis
        )
    }
}
