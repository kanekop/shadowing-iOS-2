//
//  Material.swift
//  ShadowingPractice2
//
//  Created by Apple on 2025/07/04.
//

import Foundation

/// 教材を管理するモデル
/// 
/// 音声ファイルのメタデータ、文字起こし結果、練習統計などを保持する
struct Material: Identifiable, Codable {
    let id: UUID
    let url: URL
    let createdAt: Date
    var updatedAt: Date
    
    // メタデータ
    var title: String
    var memo: String?
    var duration: TimeInterval
    var transcription: String?
    var isTranscribing: Bool = false
    var transcriptionError: String?
    
    // 練習統計
    var practiceCount: Int = 0
    var lastPracticedAt: Date?
    var averageScore: Double?
    
    // ファイルタイプ
    enum SourceType: String, Codable {
        case imported = "imported"
        case recorded = "recorded"
    }
    var sourceType: SourceType
    
    /// 新しい教材を作成
    /// - Parameters:
    ///   - url: 音声ファイルのURL
    ///   - title: 教材のタイトル
    ///   - sourceType: インポートまたは録音
    ///   - duration: 音声の長さ（秒）
    init(
        id: UUID = UUID(),
        url: URL,
        title: String,
        sourceType: SourceType,
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.url = url
        self.createdAt = Date()
        self.updatedAt = Date()
        self.title = title
        self.sourceType = sourceType
        self.duration = duration
    }
}

// MARK: - Computed Properties
extension Material {
    /// フォーマット済みの時間表示
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }
    
    /// 練習していない教材かどうか
    var isUnpracticed: Bool {
        practiceCount == 0
    }
    
    /// 文字起こしが完了しているかどうか
    var hasTranscription: Bool {
        transcription != nil && !transcription!.isEmpty
    }
}

// MARK: - Sample Data
#if DEBUG
extension Material {
    static let sampleData: [Material] = [
        Material(
            url: URL(string: "file:///sample1.m4a")!,
            title: "Business English - Meeting",
            sourceType: .imported,
            duration: 120
        ),
        Material(
            url: URL(string: "file:///sample2.m4a")!,
            title: "My Recording",
            sourceType: .recorded,
            duration: 60
        )
    ]
}
#endif