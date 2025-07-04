//
//  SpeechRecognizer.swift
//  ShadowingPractice2
//
//  Created by Apple on 2025/07/04.
//

import Foundation
import Speech
import AVFoundation

/// 音声認識を管理するサービス
/// 
/// Apple Speech Recognitionを使用して音声ファイルから文字起こしを行う
class SpeechRecognizer: ObservableObject {
    // MARK: - Singleton
    static let shared = SpeechRecognizer()
    // MARK: - Published Properties
    @Published var isRecognizing = false
    @Published var progress: Double = 0
    @Published var error: RecognizerError?
    
    // MARK: - Private Properties
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // MARK: - Error Types
    enum RecognizerError: LocalizedError {
        case notAvailable
        case notAuthorized
        case audioFileError(String)
        case recognitionFailed(String)
        case languageNotSupported
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "音声認識サービスが利用できません"
            case .notAuthorized:
                return "音声認識の権限が許可されていません"
            case .audioFileError(let reason):
                return "音声ファイルエラー: \(reason)"
            case .recognitionFailed(let reason):
                return "音声認識に失敗しました: \(reason)"
            case .languageNotSupported:
                return "選択された言語はサポートされていません"
            }
        }
    }
    
    // MARK: - Recognition Options
    struct RecognitionOptions {
        var language: Locale = Locale(identifier: "en-US")
        var shouldReportPartialResults: Bool = true
        var addsPunctuation: Bool = true
        var taskHint: SFSpeechRecognitionTaskHint = .dictation
    }
    
    // MARK: - Recognition Result
    struct RecognitionResult {
        let text: String
        let confidence: Double
        let segments: [TranscriptionSegment]?
        let alternativeInterpretations: [String]?
    }
    
    struct TranscriptionSegment {
        let substring: String
        let timestamp: TimeInterval
        let duration: TimeInterval
        let confidence: Float
    }
    
    // MARK: - Initialization
    init(locale: Locale = Locale(identifier: "en-US")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }
    
    // MARK: - Public Methods
    
    /// 音声ファイルから文字起こしを実行（シンプル版）
    /// - Parameter url: 音声ファイルのURL
    /// - Returns: 認識されたテキスト
    /// - Throws: RecognizerError
    func recognizeFromFile(url: URL) async throws -> String {
        let result = try await recognizeFromFile(url: url, options: RecognitionOptions())
        return result.text
    }
    
    /// 音声ファイルから文字起こしを実行
    /// - Parameters:
    ///   - url: 音声ファイルのURL
    ///   - options: 認識オプション
    /// - Returns: 認識結果
    /// - Throws: RecognizerError
    func recognizeFromFile(
        url: URL,
        options: RecognitionOptions = RecognitionOptions()
    ) async throws -> RecognitionResult {
        // 権限確認
        guard await requestAuthorization() else {
            throw RecognizerError.notAuthorized
        }
        
        // 利用可能性確認
        guard let recognizer = speechRecognizer,
              recognizer.isAvailable else {
            throw RecognizerError.notAvailable
        }
        
        // 言語サポート確認
        if recognizer.locale != options.language {
            // 新しい言語で認識器を作成
            guard SFSpeechRecognizer(locale: options.language) != nil else {
                throw RecognizerError.languageNotSupported
            }
        }
        
        // 認識リクエスト作成
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = options.shouldReportPartialResults
        request.taskHint = options.taskHint
        
        if #available(iOS 16, *) {
            request.addsPunctuation = options.addsPunctuation
        }
        
        // 認識実行
        await MainActor.run {
            self.isRecognizing = true
            self.progress = 0
        }
        
        do {
            let result = try await performRecognition(request: request, recognizer: recognizer)
            
            await MainActor.run {
                self.isRecognizing = false
                self.progress = 1.0
            }
            
            return result
        } catch {
            await MainActor.run {
                self.isRecognizing = false
                self.error = RecognizerError.recognitionFailed(error.localizedDescription)
            }
            
            throw RecognizerError.recognitionFailed(error.localizedDescription)
        }
    }
    
    /// 認識をキャンセル
    func cancelRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        Task { @MainActor in
            self.isRecognizing = false
            self.progress = 0
        }
    }
    
    // MARK: - Private Methods
    
    private func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    private func performRecognition(
        request: SFSpeechURLRecognitionRequest,
        recognizer: SFSpeechRecognizer
    ) async throws -> RecognitionResult {
        try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                if let error = error {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: error)
                    }
                    return
                }
                
                guard let result = result else { return }
                
                // 進捗更新
                if result.isFinal {
                    Task { @MainActor in
                        self?.progress = 1.0
                    }
                } else {
                    // 部分的な結果の場合の進捗（推定）
                    let estimatedProgress = min(0.9, Double(result.bestTranscription.formattedString.count) / 1000.0)
                    Task { @MainActor in
                        self?.progress = estimatedProgress
                    }
                }
                
                // 最終結果の場合
                if result.isFinal && !hasResumed {
                    hasResumed = true
                    
                    let transcription = result.bestTranscription
                    
                    // セグメント情報を抽出
                    let segments = transcription.segments.map { segment in
                        TranscriptionSegment(
                            substring: segment.substring,
                            timestamp: segment.timestamp,
                            duration: segment.duration,
                            confidence: segment.confidence
                        )
                    }
                    
                    // 代替解釈を抽出
                    let alternatives = result.transcriptions.dropFirst().prefix(3).map { $0.formattedString }
                    
                    // 平均信頼度を計算
                    let avgConfidence = segments.isEmpty ? 0 : 
                        Double(segments.map { $0.confidence }.reduce(0, +)) / Double(segments.count)
                    
                    let recognitionResult = RecognitionResult(
                        text: transcription.formattedString,
                        confidence: avgConfidence,
                        segments: segments,
                        alternativeInterpretations: alternatives.isEmpty ? nil : alternatives
                    )
                    
                    continuation.resume(returning: recognitionResult)
                }
            }
        }
    }
    
    /// サポートされている言語のリストを取得
    static func supportedLanguages() -> [Locale] {
        return [
            Locale(identifier: "en-US"),
            Locale(identifier: "en-GB"),
            Locale(identifier: "ja-JP"),
            // 他の言語は必要に応じて追加
        ]
    }
    
    /// 音声ファイルを文字起こしする
    /// - Parameter url: 音声ファイルのURL
    /// - Returns: 文字起こし結果のテキスト
    func transcribeAudioFile(at url: URL) async throws -> String {
        let engine = AppleSpeechEngine()
        return try await engine.transcribeAudioFile(at: url)
    }
}

// MARK: - Speech Recognition Engine Protocol
/// 音声認識エンジンのプロトコル（将来の拡張用）
protocol SpeechRecognitionEngine {
    var engineName: String { get }
    var requiresAPIKey: Bool { get }
    var supportsOffline: Bool { get }
    var supportedLanguages: [Locale] { get }
    
    func recognizeFromFile(
        url: URL,
        language: Locale,
        options: SpeechRecognizer.RecognitionOptions?
    ) async throws -> SpeechRecognizer.RecognitionResult
}

// MARK: - Apple Speech Engine Implementation
class AppleSpeechEngine: SpeechRecognitionEngine {
    let engineName = "Apple Speech"
    let requiresAPIKey = false
    let supportsOffline = true
    let supportedLanguages = SpeechRecognizer.supportedLanguages()
    
    private let recognizer = SpeechRecognizer()
    
    func recognizeFromFile(
        url: URL,
        language: Locale,
        options: SpeechRecognizer.RecognitionOptions?
    ) async throws -> SpeechRecognizer.RecognitionResult {
        var recognitionOptions = options ?? SpeechRecognizer.RecognitionOptions()
        recognitionOptions.language = language
        
        return try await recognizer.recognizeFromFile(url: url, options: recognitionOptions)
    }
    
    /// 音声ファイルを文字起こしする
    /// - Parameter url: 音声ファイルのURL
    /// - Returns: 文字起こし結果のテキスト
    func transcribeAudioFile(at url: URL) async throws -> String {
        let options = SpeechRecognizer.RecognitionOptions()
        let language = Locale(identifier: "en-US") // デフォルトで英語
        let result = try await recognizeFromFile(url: url, language: language, options: options)
        return result.text
    }
}
