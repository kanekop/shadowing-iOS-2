//
//  Logger.swift
//  ShadowingPractice2
//
//  Created by Apple on 2025/07/04.
//

import Foundation
import os.log

/// アプリケーション全体で使用するロガー
/// 
/// 統一されたログ出力とデバッグ支援を提供する
struct Logger {
    
    /// 共有インスタンス
    static let shared = Logger()
    
    // MARK: - Instance Methods (for shared instance)
    
    func info(_ message: String, category: LogCategory = .general) {
        Logger.info(message, category: category)
    }
    
    func warning(_ message: String, category: LogCategory = .general) {
        Logger.warning(message, category: category)
    }
    
    func error(_ message: String, category: LogCategory = .general, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        Logger.error(message, category: category, error: error, file: file, function: function, line: line)
    }
    
    func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        Logger.debug(message, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Log Categories
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.shadowingpractice"
    
    private static let general = OSLog(subsystem: subsystem, category: "General")
    private static let audio = OSLog(subsystem: subsystem, category: "Audio")
    private static let recognition = OSLog(subsystem: subsystem, category: "Recognition")
    private static let fileIO = OSLog(subsystem: subsystem, category: "FileIO")
    private static let ui = OSLog(subsystem: subsystem, category: "UI")
    private static let network = OSLog(subsystem: subsystem, category: "Network")
    
    // MARK: - Log Levels
    
    /// デバッグログ
    /// - Parameters:
    ///   - message: ログメッセージ
    ///   - category: ログカテゴリ
    ///   - file: ファイル名
    ///   - function: 関数名
    ///   - line: 行番号
    static func debug(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        os_log(
            "[DEBUG] %{public}@ - %{public}@:%{public}ld - %{public}@",
            log: getLog(for: category),
            type: .debug,
            fileName,
            function,
            line,
            message
        )
        #endif
    }
    
    /// 情報ログ
    static func info(
        _ message: String,
        category: LogCategory = .general
    ) {
        os_log(
            "[INFO] %{public}@",
            log: getLog(for: category),
            type: .info,
            message
        )
    }
    
    /// 警告ログ
    static func warning(
        _ message: String,
        category: LogCategory = .general
    ) {
        os_log(
            "[WARNING] %{public}@",
            log: getLog(for: category),
            type: .default,
            message
        )
    }
    
    /// エラーログ
    static func error(
        _ message: String,
        category: LogCategory = .general,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        
        var fullMessage = message
        if let error = error {
            fullMessage += " - Error: \(error.localizedDescription)"
        }
        
        os_log(
            "[ERROR] %{public}@ - %{public}@:%{public}ld - %{public}@",
            log: getLog(for: category),
            type: .error,
            fileName,
            function,
            line,
            fullMessage
        )
    }
    
    /// 致命的エラーログ
    static func fatal(
        _ message: String,
        category: LogCategory = .general,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        
        var fullMessage = message
        if let error = error {
            fullMessage += " - Error: \(error.localizedDescription)"
        }
        
        os_log(
            "[FATAL] %{public}@ - %{public}@:%{public}ld - %{public}@",
            log: getLog(for: category),
            type: .fault,
            fileName,
            function,
            line,
            fullMessage
        )
        
        #if DEBUG
        // デバッグビルドではクラッシュさせる
        fatalError(fullMessage)
        #endif
    }
    
    // MARK: - Performance Logging
    
    /// パフォーマンス計測開始
    /// - Parameter label: 計測ラベル
    /// - Returns: 計測開始時刻
    static func startMeasuring(_ label: String) -> Date {
        let startTime = Date()
        debug("Performance measurement started: \(label)")
        return startTime
    }
    
    /// パフォーマンス計測終了
    /// - Parameters:
    ///   - label: 計測ラベル
    ///   - startTime: 開始時刻
    static func endMeasuring(_ label: String, startTime: Date) {
        let elapsed = Date().timeIntervalSince(startTime)
        info("Performance measurement '\(label)': \(String(format: "%.3f", elapsed))秒")
    }
    
    // MARK: - Specialized Logging
    
    /// 音声関連のログ
    static func audio(_ message: String, level: LogLevel = .info) {
        log(message, category: .audio, level: level)
    }
    
    /// 音声認識関連のログ
    static func recognition(_ message: String, level: LogLevel = .info) {
        log(message, category: .recognition, level: level)
    }
    
    /// ファイルI/O関連のログ
    static func fileIO(_ message: String, level: LogLevel = .info) {
        log(message, category: .fileIO, level: level)
    }
    
    /// UI関連のログ
    static func ui(_ message: String, level: LogLevel = .info) {
        log(message, category: .ui, level: level)
    }
    
    /// ネットワーク関連のログ
    static func network(_ message: String, level: LogLevel = .info) {
        log(message, category: .network, level: level)
    }
    
    // MARK: - Private Methods
    
    private static func getLog(for category: LogCategory) -> OSLog {
        switch category {
        case .general: return general
        case .audio: return audio
        case .recognition: return recognition
        case .fileIO: return fileIO
        case .ui: return ui
        case .network: return network
        }
    }
    
    private static func log(_ message: String, category: LogCategory, level: LogLevel) {
        switch level {
        case .debug:
            debug(message, category: category)
        case .info:
            info(message, category: category)
        case .warning:
            warning(message, category: category)
        case .error:
            error(message, category: category)
        }
    }
}

// MARK: - Supporting Types

extension Logger {
    /// ログカテゴリ
    enum LogCategory {
        case general
        case audio
        case recognition
        case fileIO
        case ui
        case network
    }
    
    /// ログレベル
    enum LogLevel {
        case debug
        case info
        case warning
        case error
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension Logger {
    /// デバッグ用のオブジェクトダンプ
    static func dump<T>(_ object: T, label: String = "") {
        debug("=== Object Dump: \(label) ===")
        Swift.dump(object)
        debug("=== End Dump ===")
    }
    
    /// メモリアドレスを出力
    static func printMemoryAddress(of object: AnyObject, label: String = "") {
        let address = Unmanaged.passUnretained(object).toOpaque()
        debug("Memory address of \(label): \(address)")
    }
    
    /// 現在のスレッド情報を出力
    static func printThreadInfo() {
        let current = Thread.current
        let isMain = current.isMainThread
        let name = current.name ?? "Unnamed"
        let priority = current.threadPriority
        
        debug("Thread Info - Main: \(isMain), Name: \(name), Priority: \(priority)")
    }
}
#endif

// MARK: - Convenience Methods

extension Logger {
    /// 関数の開始と終了をログ
    static func trace(
        _ function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        #if DEBUG
        debug(">>> \(function)", file: file, function: function, line: line)
        #endif
    }
    
    /// アサーション付きログ
    static func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        if !condition() {
            error("Assertion Failed: \(message)", file: file, function: function, line: line)
            assertionFailure(message)
        }
        #endif
    }
}