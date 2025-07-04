//
//  MaterialService.swift
//  ShadowingPractice2
//
//  Created by Apple on 2025/07/04.
//

import Foundation
import AVFoundation
import UniformTypeIdentifiers

/// 教材を管理するサービスクラス
/// 
/// 音声ファイルのインポート、録音、削除などの操作を提供する
class MaterialService: ObservableObject {
    // MARK: - Singleton
    static let shared = MaterialService()
    // MARK: - Published Properties
    @Published var materials: [Material] = []
    @Published var isLoading = false
    @Published var error: MaterialError?
    
    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let logger = Logger.shared
    
    // MARK: - Constants
    private let maxFileSize: Int64 = 100_000_000 // 100MB
    private let maxDuration: TimeInterval = 600 // 10分
    private let minDuration: TimeInterval = 1 // 1秒
    
    // MARK: - Supported File Types
    static let supportedTypes: [UTType] = [
        .mp3,
        .wav,
        .mpeg4Audio,
        .aiff,
        UTType(filenameExtension: "caf") ?? .audio,
        UTType(filenameExtension: "m4a") ?? .audio
    ]
    
    // MARK: - Error Types
    enum MaterialError: LocalizedError {
        case accessDenied
        case fileTooLarge
        case durationTooLong
        case durationTooShort
        case unsupportedFormat
        case importFailed(String)
        case deleteFailed(String)
        case loadFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "ファイルへのアクセスが拒否されました"
            case .fileTooLarge:
                return "ファイルサイズが100MBを超えています"
            case .durationTooLong:
                return "音声の長さが10分を超えています"
            case .durationTooShort:
                return "音声の長さが1秒未満です"
            case .unsupportedFormat:
                return "サポートされていないファイル形式です"
            case .importFailed(let reason):
                return "インポートに失敗しました: \(reason)"
            case .deleteFailed(let reason):
                return "削除に失敗しました: \(reason)"
            case .loadFailed(let reason):
                return "読み込みに失敗しました: \(reason)"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        loadMaterials()
    }
    
    // MARK: - Public Methods
    
    /// 音声ファイルをインポートする
    /// - Parameter url: インポート元のファイルURL
    /// - Returns: インポートされた教材
    /// - Throws: MaterialError
    func importAudioFile(from url: URL) async throws -> Material {
        // ファイル検証
        guard url.startAccessingSecurityScopedResource() else {
            throw MaterialError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // サイズチェック
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        guard fileSize <= maxFileSize else {
            throw MaterialError.fileTooLarge
        }
        
        // 音声長さチェック
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let durationSeconds = duration.seconds
        
        guard durationSeconds >= minDuration else {
            throw MaterialError.durationTooShort
        }
        
        guard durationSeconds <= maxDuration else {
            throw MaterialError.durationTooLong
        }
        
        // ファイルコピー
        let destinationURL = FileManager.materialsDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(url.pathExtension)
        
        do {
            try fileManager.copyItem(at: url, to: destinationURL)
        } catch {
            throw MaterialError.importFailed(error.localizedDescription)
        }
        
        // 教材作成
        let material = Material(
            url: destinationURL,
            title: url.deletingPathExtension().lastPathComponent,
            sourceType: .imported,
            duration: durationSeconds
        )
        
        // リストに追加して保存
        await MainActor.run {
            self.materials.append(material)
        }
        
        saveMaterials()
        
        return material
    }
    
    /// 録音した音声を教材として保存
    /// - Parameters:
    ///   - temporaryURL: 一時ファイルのURL
    ///   - title: 教材のタイトル
    /// - Returns: 作成された教材
    /// - Throws: MaterialError
    func saveMaterialFromRecording(temporaryURL: URL, title: String) async throws -> Material {
        // 音声長さ取得
        let asset = AVURLAsset(url: temporaryURL)
        let duration = try await asset.load(.duration)
        let durationSeconds = duration.seconds
        
        // ファイルを教材ディレクトリに移動
        let destinationURL = FileManager.materialsDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        do {
            try fileManager.moveItem(at: temporaryURL, to: destinationURL)
        } catch {
            throw MaterialError.importFailed(error.localizedDescription)
        }
        
        // 教材作成
        let material = Material(
            url: destinationURL,
            title: title,
            sourceType: .recorded,
            duration: durationSeconds
        )
        
        // リストに追加して保存
        await MainActor.run {
            self.materials.append(material)
        }
        
        saveMaterials()
        
        return material
    }
    
    /// 教材を削除
    /// - Parameter material: 削除する教材
    /// - Throws: MaterialError
    func deleteMaterial(_ material: Material) throws {
        // ファイル削除
        do {
            try fileManager.removeItem(at: material.url)
        } catch {
            throw MaterialError.deleteFailed(error.localizedDescription)
        }
        
        // リストから削除
        materials.removeAll { $0.id == material.id }
        
        // メタデータ更新
        saveMaterials()
    }
    
    /// 教材を更新
    /// - Parameter material: 更新する教材
    func updateMaterial(_ material: Material) {
        if let index = materials.firstIndex(where: { $0.id == material.id }) {
            var updatedMaterial = material
            updatedMaterial.updatedAt = Date()
            materials[index] = updatedMaterial
            saveMaterials()
        }
    }
    
    /// 教材リストをリロード (public)
    func reloadMaterials() {
        loadMaterials()
    }
    
    // MARK: - Private Methods
    
    private func loadMaterials() {
        Task { @MainActor in
            isLoading = true
        }
        
        // メタデータファイルから読み込み
        guard fileManager.fileExists(atPath: metadataFile.path) else {
            Task { @MainActor in
                isLoading = false
            }
            return
        }
        
        do {
            let data = try Data(contentsOf: metadataFile)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let loadedMaterials = try decoder.decode([Material].self, from: data)
            
            // ファイルの存在確認
            let validMaterials = loadedMaterials.filter { material in
                fileManager.fileExists(atPath: material.url.path)
            }
            
            Task { @MainActor in
                self.materials = validMaterials
                self.isLoading = false
            }
        } catch {
            Task { @MainActor in
                self.error = MaterialError.loadFailed(error.localizedDescription)
                self.isLoading = false
            }
        }
    }
    
    private func saveMaterials() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(materials)
            try data.write(to: metadataFile)
        } catch {
            Logger.shared.error("教材メタデータの保存に失敗: \(error)")
        }
    }
    
    /// 古い練習録音を自動削除（30日以上前）
    func cleanupOldPracticeRecordings() {
        let practicesDirectory = FileManager.practicesDirectory
        guard let files = try? fileManager.contentsOfDirectory(
            at: practicesDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return }
        
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        
        for file in files {
            if let attributes = try? file.resourceValues(forKeys: [.creationDateKey]),
               let creationDate = attributes.creationDate,
               creationDate < thirtyDaysAgo {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    // MARK: - Additional Methods for ViewModels
    
    /// 教材を取得する
    func getMaterial(by id: UUID) -> Material? {
        return materials.first { $0.id == id }
    }
    
    
    /// 教材を文字起こしする（プレースホルダー）
    func transcribeMaterial(_ material: Material) async throws {
        Logger.shared.info("Starting transcription for material: \(material.title)")
        
        // 既に文字起こし済み、または文字起こし中の場合はスキップ
        if material.transcription != nil || material.isTranscribing {
            return
        }
        
        // 文字起こし中フラグを立てる
        var updatedMaterial = material
        updatedMaterial.isTranscribing = true
        updateMaterial(updatedMaterial)
        
        do {
            // SpeechRecognizerを使用して文字起こし
            let speechRecognizer = SpeechRecognizer.shared
            let transcription = try await speechRecognizer.transcribeAudioFile(at: material.url)
            
            // 文字起こし結果を保存
            updatedMaterial.transcription = transcription
            updatedMaterial.isTranscribing = false
            updatedMaterial.transcriptionError = nil
            updateMaterial(updatedMaterial)
            
            Logger.shared.info("Transcription completed for material: \(material.title)")
        } catch {
            // エラーを記録
            updatedMaterial.isTranscribing = false
            updatedMaterial.transcriptionError = error.localizedDescription
            updateMaterial(updatedMaterial)
            
            Logger.shared.error("Transcription failed for material: \(material.title), error: \(error)")
            throw error
        }
    }
    
    /// 録音したファイルをインポート（saveMaterialFromRecordingのエイリアス）
    func importRecordedFile(from url: URL, title: String) async throws -> Material {
        return try await saveMaterialFromRecording(temporaryURL: url, title: title)
    }
    
    /// 教材を非同期で更新
    func updateMaterialAsync(_ material: Material) async {
        await MainActor.run {
            updateMaterial(material)
        }
    }
    
    /// 教材を非同期で削除
    func deleteMaterialAsync(_ material: Material) async throws {
        try await MainActor.run {
            try deleteMaterial(material)
        }
    }
}

// MARK: - Material Service Protocol
protocol MaterialServiceProtocol {
    func importAudioFile(from url: URL) async throws -> Material
    func saveMaterialFromRecording(temporaryURL: URL, title: String) async throws -> Material
    func deleteMaterial(_ material: Material) throws
    func updateMaterial(_ material: Material)
    func reloadMaterials()
}