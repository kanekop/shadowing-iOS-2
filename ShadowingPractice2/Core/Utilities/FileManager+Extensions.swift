//
//  FileManager+Extensions.swift
//  ShadowingPractice2
//
//  Created by Apple on 2025/07/04.
//

import Foundation

extension FileManager {
    
    // MARK: - Directory Management
    
    /// アプリのDocumentsディレクトリを取得
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // Removed static temporaryDirectory - use FileManager.default.temporaryDirectory directly
    
    /// 指定されたサブディレクトリを作成（存在しない場合）
    /// - Parameter name: サブディレクトリ名
    /// - Returns: 作成されたディレクトリのURL
    @discardableResult
    func createSubdirectoryIfNeeded(named name: String, in directory: URL? = nil) throws -> URL {
        let baseDirectory = directory ?? FileManager.documentsDirectory
        let subdirectoryURL = baseDirectory.appendingPathComponent(name)
        
        if !fileExists(atPath: subdirectoryURL.path) {
            try createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return subdirectoryURL
    }
    
    // MARK: - File Operations
    
    /// ファイルサイズを取得
    /// - Parameter url: ファイルのURL
    /// - Returns: ファイルサイズ（バイト）
    func fileSize(at url: URL) -> Int64? {
        do {
            let attributes = try attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            Logger.shared.error("ファイルサイズの取得に失敗: \(error)")
            return nil
        }
    }
    
    /// ファイルの作成日時を取得
    /// - Parameter url: ファイルのURL
    /// - Returns: 作成日時
    func creationDate(at url: URL) -> Date? {
        do {
            let attributes = try attributesOfItem(atPath: url.path)
            return attributes[.creationDate] as? Date
        } catch {
            Logger.shared.error("作成日時の取得に失敗: \(error)")
            return nil
        }
    }
    
    /// ディレクトリ内のファイルを列挙
    /// - Parameters:
    ///   - directory: ディレクトリURL
    ///   - extension: ファイル拡張子（オプション）
    /// - Returns: ファイルURLの配列
    func files(in directory: URL, withExtension ext: String? = nil) -> [URL] {
        do {
            let contents = try contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            if let ext = ext {
                return contents.filter { $0.pathExtension == ext }
            }
            
            return contents
        } catch {
            Logger.shared.error("ディレクトリ内容の取得に失敗: \(error)")
            return []
        }
    }
    
    // MARK: - Storage Management
    
    /// 利用可能なディスク容量を取得
    /// - Returns: 利用可能な容量（バイト）
    var availableDiskSpace: Int64? {
        do {
            let systemAttributes = try attributesOfFileSystem(forPath: NSHomeDirectory())
            return systemAttributes[.systemFreeSize] as? Int64
        } catch {
            Logger.shared.error("ディスク容量の取得に失敗: \(error)")
            return nil
        }
    }
    
    /// ディレクトリのサイズを計算
    /// - Parameter directory: ディレクトリURL
    /// - Returns: ディレクトリサイズ（バイト）
    func directorySize(at directory: URL) -> Int64 {
        var size: Int64 = 0
        
        if let enumerator = enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                if let fileSize = fileSize(at: fileURL) {
                    size += fileSize
                }
            }
        }
        
        return size
    }
    
    /// 古いファイルを削除
    /// - Parameters:
    ///   - directory: ディレクトリURL
    ///   - days: 日数（この日数より古いファイルを削除）
    func deleteOldFiles(in directory: URL, olderThan days: Int) {
        let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        
        let files = self.files(in: directory)
        for file in files {
            if let creationDate = creationDate(at: file),
               creationDate < cutoffDate {
                try? removeItem(at: file)
                Logger.shared.info("古いファイルを削除: \(file.lastPathComponent)")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// ユニークなファイル名を生成
    /// - Parameters:
    ///   - prefix: ファイル名のプレフィックス
    ///   - extension: ファイル拡張子
    /// - Returns: ユニークなファイル名
    static func uniqueFileName(prefix: String = "", extension ext: String) -> String {
        let uuid = UUID().uuidString
        if prefix.isEmpty {
            return "\(uuid).\(ext)"
        } else {
            return "\(prefix)_\(uuid).\(ext)"
        }
    }
    
    /// ファイルを安全にコピー
    /// - Parameters:
    ///   - source: コピー元URL
    ///   - destination: コピー先URL
    ///   - overwrite: 上書きするかどうか
    /// - Throws: エラー
    func safeCopy(from source: URL, to destination: URL, overwrite: Bool = false) throws {
        if fileExists(atPath: destination.path) {
            if overwrite {
                try removeItem(at: destination)
            } else {
                throw CocoaError(.fileWriteFileExists)
            }
        }
        
        try copyItem(at: source, to: destination)
    }
    
    /// ファイルを安全に移動
    /// - Parameters:
    ///   - source: 移動元URL
    ///   - destination: 移動先URL
    ///   - overwrite: 上書きするかどうか
    /// - Throws: エラー
    func safeMove(from source: URL, to destination: URL, overwrite: Bool = false) throws {
        if fileExists(atPath: destination.path) {
            if overwrite {
                try removeItem(at: destination)
            } else {
                throw CocoaError(.fileWriteFileExists)
            }
        }
        
        try moveItem(at: source, to: destination)
    }
}

// MARK: - Format Helpers
extension FileManager {
    
    /// バイト数を人間が読みやすい形式に変換
    /// - Parameter bytes: バイト数
    /// - Returns: フォーマット済みの文字列
    static func formattedFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
    
    /// ファイル拡張子から音声ファイルかどうか判定
    /// - Parameter url: ファイルURL
    /// - Returns: 音声ファイルかどうか
    static func isAudioFile(_ url: URL) -> Bool {
        let audioExtensions = ["mp3", "m4a", "wav", "aiff", "caf", "mp4", "aac"]
        return audioExtensions.contains(url.pathExtension.lowercased())
    }
}

// MARK: - App Specific Directories
extension FileManager {
    
    /// 教材ディレクトリ
    static var materialsDirectory: URL {
        let directory = documentsDirectory.appendingPathComponent("materials")
        try? FileManager.default.createSubdirectoryIfNeeded(named: "materials")
        return directory
    }
    
    /// 練習録音ディレクトリ
    static var practicesDirectory: URL {
        let directory = documentsDirectory.appendingPathComponent("practices")
        try? FileManager.default.createSubdirectoryIfNeeded(named: "practices")
        return directory
    }
    
    /// メタデータディレクトリ
    static var metadataDirectory: URL {
        let directory = documentsDirectory.appendingPathComponent("metadata")
        try? FileManager.default.createSubdirectoryIfNeeded(named: "metadata")
        return directory
    }
    
    /// キャッシュディレクトリ
    static var cacheDirectory: URL {
        let directory = documentsDirectory.appendingPathComponent("cache")
        try? FileManager.default.createSubdirectoryIfNeeded(named: "cache")
        return directory
    }
}