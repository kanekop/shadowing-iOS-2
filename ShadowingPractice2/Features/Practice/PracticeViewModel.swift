import Foundation
import Combine
import AVFoundation

@MainActor
class PracticeViewModel: ObservableObject {
    @Published var currentMaterial: Material?
    @Published var practiceSession: PracticeSession?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let materialService = MaterialService.shared
    private let speechRecognizer = SpeechRecognizer.shared
    private let textComparisonService = TextComparisonService()
    private let logger = Logger.shared
    
    init() {}
    
    func startPracticeSession(material: Material, mode: PracticeMode) {
        currentMaterial = material
        // Practice session will be created when recording starts
    }
    
    func analyzePracticeRecording(url: URL, mode: PracticeMode) async throws -> PracticeResult {
        guard let material = currentMaterial else {
            throw PracticeError.noActiveSession
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // 音声認識
        let recognizedText = try await speechRecognizer.recognizeFromFile(url: url)
        
        // テキスト比較
        guard let originalText = material.transcription else {
            throw PracticeError.noTranscription
        }
        
        let comparisonResult = textComparisonService.compareTexts(
            original: originalText,
            recognized: recognizedText
        )
        
        // 結果作成
        let result = PracticeResult(
            recognizedText: recognizedText,
            originalText: originalText,
            wordAnalysis: comparisonResult.wordAnalysis
        )
        
        // 保存
        savePracticeResult(result)
        
        // 教材の統計更新
        await updateMaterialStatistics(material: material, result: result)
        
        return result
    }
    
    func savePracticeResult(_ result: PracticeResult) {
        Task {
            do {
                try await savePracticeResultToFile(result)
            } catch {
                logger.error("Failed to save practice result: \(error)")
                errorMessage = "練習結果の保存に失敗しました"
            }
        }
    }
    
    private func savePracticeResultToFile(_ result: PracticeResult) async throws {
        // 結果をファイルに保存
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(result)
        
        let practicesDir = FileManager.practicesDirectory
        let resultFile = practicesDir.appendingPathComponent("\(result.id.uuidString).json")
        try data.write(to: resultFile)
        
        logger.info("Practice result saved: \(result.id)")
    }
    
    private func updateMaterialStatistics(material: Material, result: PracticeResult) async {
        var updatedMaterial = material
        updatedMaterial.practiceCount += 1
        updatedMaterial.lastPracticedAt = Date()
        
        // 平均スコアの更新
        if let currentAverage = material.averageScore {
            let totalScore = currentAverage * Double(material.practiceCount - 1) + result.overallScore
            updatedMaterial.averageScore = totalScore / Double(material.practiceCount)
        } else {
            updatedMaterial.averageScore = result.overallScore
        }
        
        await materialService.updateMaterialAsync(updatedMaterial)
    }
    
    private func calculateWPM(words: Int, duration: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }
        return Double(words) / (duration / 60.0)
    }
    
    private func getAudioDuration(from url: URL) async throws -> TimeInterval {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }
}

enum PracticeError: LocalizedError {
    case noActiveSession
    case noTranscription
    case recordingFailed
    case analysisFailed
    
    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "練習セッションが開始されていません"
        case .noTranscription:
            return "教材の文字起こしがありません"
        case .recordingFailed:
            return "録音に失敗しました"
        case .analysisFailed:
            return "音声の分析に失敗しました"
        }
    }
}