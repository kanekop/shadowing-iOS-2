//
//  AudioRecorder.swift
//  ShadowingPractice2
//
//  Created by Apple on 2025/07/04.
//

import Foundation
import AVFoundation
import Combine

/// 音声録音を管理するサービス
/// 
/// 練習用音声と教材音声の録音機能を提供する
class AudioRecorder: NSObject, ObservableObject {
    // MARK: - Singleton
    static let shared = AudioRecorder()
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var currentRecordingURL: URL?
    @Published var audioLevel: Float = 0
    @Published var error: RecorderError?
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var timer: Timer?
    private var levelTimer: Timer?
    private var stopRecordingCompletion: ((Result<URL, RecorderError>) -> Void)?
    
    // MARK: - Recording Settings
    private let practiceRecordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 2,  // ステレオ（評価精度向上）
        AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
        AVEncoderBitRateKey: 256000  // 256kbps（高品質）
    ]
    
    private let materialRecordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,  // モノラル（ファイルサイズ節約）
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        AVEncoderBitRateKey: 128000  // 128kbps
    ]
    
    // MARK: - Error Types
    enum RecorderError: LocalizedError {
        case permissionDenied
        case sessionConfigurationFailed
        case recordingFailed(String)
        case fileNotFound
        case saveFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "マイクへのアクセスが許可されていません"
            case .sessionConfigurationFailed:
                return "録音セッションの設定に失敗しました"
            case .recordingFailed(let reason):
                return "録音に失敗しました: \(reason)"
            case .fileNotFound:
                return "録音ファイルが見つかりません"
            case .saveFailed(let reason):
                return "ファイルの保存に失敗しました: \(reason)"
            }
        }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupNotifications()
    }
    
    deinit {
        stopRecording()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// 録音を開始
    /// - Parameters:
    ///   - isMaterial: 教材録音の場合true、練習録音の場合false
    ///   - maxDuration: 最大録音時間（秒）
    /// - Throws: RecorderError
    func startRecording(isMaterial: Bool = false, maxDuration: TimeInterval = 120) async throws {
        // 権限確認
        guard await requestPermission() else {
            throw RecorderError.permissionDenied
        }
        
        // セッション設定
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            throw RecorderError.sessionConfigurationFailed
        }
        
        // 録音URL生成
        let fileName = "\(UUID().uuidString).m4a"
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        // レコーダー作成
        let settings = isMaterial ? materialRecordingSettings : practiceRecordingSettings
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            // 録音開始
            if audioRecorder?.record() == true {
                await MainActor.run {
                    self.isRecording = true
                    self.currentRecordingURL = fileURL
                    self.recordingTime = 0
                    self.startTimers(maxDuration: maxDuration)
                }
            } else {
                throw RecorderError.recordingFailed("録音の開始に失敗しました")
            }
        } catch {
            throw RecorderError.recordingFailed(error.localizedDescription)
        }
    }
    
    /// 録音を停止
    /// - Parameter completion: 完了ハンドラー
    func stopRecording(completion: ((Result<URL, RecorderError>) -> Void)? = nil) {
        stopRecordingCompletion = completion
        
        audioRecorder?.stop()
        
        stopTimers()
        
        Task { @MainActor in
            self.isRecording = false
        }
        
        // セッションを非アクティブ化
        try? recordingSession.setActive(false)
    }
    
    /// 録音をキャンセル
    func cancelRecording() {
        audioRecorder?.stop()
        audioRecorder?.deleteRecording()
        
        stopTimers()
        
        Task { @MainActor in
            self.isRecording = false
            self.currentRecordingURL = nil
            self.recordingTime = 0
        }
        
        try? recordingSession.setActive(false)
    }
    
    // MARK: - Private Methods
    
    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            // Using the method that works in iOS 17+ without deprecation warning
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    private func startTimers(maxDuration: TimeInterval) {
        // 録音時間タイマー
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingTime += 1
                
                // 最大時間チェック
                if let time = self?.recordingTime, time >= maxDuration {
                    self?.stopRecording { result in
                        // 最大時間到達を通知
                        Logger.shared.info("録音が最大時間(\(maxDuration)秒)に達しました")
                    }
                }
            }
        }
        
        // 音声レベルタイマー
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.audioRecorder?.updateMeters()
            let level = self?.audioRecorder?.averagePower(forChannel: 0) ?? -160
            Task { @MainActor in
                self?.audioLevel = max(0, (level + 160) / 160)
            }
        }
    }
    
    private func stopTimers() {
        timer?.invalidate()
        timer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }
    
    private func setupNotifications() {
        // 割り込み処理
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began && isRecording {
            // 割り込み開始（電話など）
            stopRecording { [weak self] result in
                self?.error = RecorderError.recordingFailed("録音が中断されました")
            }
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            if let url = currentRecordingURL {
                stopRecordingCompletion?(.success(url))
            } else {
                stopRecordingCompletion?(.failure(.fileNotFound))
            }
        } else {
            stopRecordingCompletion?(.failure(.recordingFailed("録音が正常に完了しませんでした")))
        }
        
        stopRecordingCompletion = nil
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "不明なエラー"
        stopRecordingCompletion?(.failure(.recordingFailed(errorMessage)))
        stopRecordingCompletion = nil
        
        Task { @MainActor in
            self.error = RecorderError.recordingFailed(errorMessage)
        }
    }
}