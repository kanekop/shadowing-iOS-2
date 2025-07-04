//
//  PracticeSession.swift
//  ShadowingPractice2
//
//  Created by Apple on 2025/07/04.
//

import Foundation

/// 練習セッションのデータモデル
/// 
/// 各練習セッションの詳細情報を保持する
struct PracticeSession: Identifiable, Codable {
    let id: UUID
    let materialId: UUID
    let createdAt: Date
    
    // 練習タイプ
    enum PracticeType: String, Codable {
        case reading = "reading"        // 音読練習
        case shadowing = "shadowing"    // シャドウィング練習
        
        var displayName: String {
            switch self {
            case .reading: return "音読練習"
            case .shadowing: return "シャドウィング練習"
            }
        }
    }
    var practiceType: PracticeType
    
    // 録音情報
    let recordingURL: URL
    var recordingDuration: TimeInterval
    
    // 評価結果
    var result: PracticeResult?
    
    /// 新しい練習セッションを作成
    /// - Parameters:
    ///   - materialId: 教材のID
    ///   - practiceType: 練習タイプ
    ///   - recordingURL: 録音ファイルのURL
    init(
        id: UUID = UUID(),
        materialId: UUID,
        practiceType: PracticeType,
        recordingURL: URL,
        recordingDuration: TimeInterval = 0
    ) {
        self.id = id
        self.materialId = materialId
        self.createdAt = Date()
        self.practiceType = practiceType
        self.recordingURL = recordingURL
        self.recordingDuration = recordingDuration
    }
}

// MARK: - Computed Properties
extension PracticeSession {
    /// 練習が完了しているかどうか
    var isCompleted: Bool {
        result != nil
    }
    
    /// 練習日時のフォーマット済み表示
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: createdAt)
    }
    
    /// スコアの取得（結果がない場合は0）
    var score: Double {
        result?.overallScore ?? 0
    }
}

// MARK: - Sample Data
#if DEBUG
extension PracticeSession {
    static let sampleData = PracticeSession(
        materialId: UUID(),
        practiceType: .reading,
        recordingURL: URL(string: "file:///sample_recording.m4a")!,
        recordingDuration: 60
    )
}
#endif