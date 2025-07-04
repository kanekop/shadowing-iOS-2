//
//  AppError+Usage.swift
//  ShadowingPractice2
//
//  Created by Apple on 2025/07/04.
//

import Foundation

// MARK: - AppError Usage Guidelines

/*
 AppErrorの使用ガイドライン:
 
 1. ViewModelでの使用例:
 ```swift
 @MainActor
 class ExampleViewModel: ObservableObject {
     @Published var error: AppError?
     
     func performAction() async {
         do {
             try await someService.doSomething()
         } catch let materialError as MaterialService.MaterialError {
             error = .material(materialError)
         } catch let recorderError as AudioRecorder.RecorderError {
             error = .recording(recorderError)
         } catch {
             error = .unknown(error)
         }
     }
 }
 ```
 
 2. Viewでのエラー表示:
 ```swift
 .alert(item: $viewModel.error) { error in
     Alert(
         title: Text("エラー"),
         message: Text(error.localizedDescription),
         dismissButton: .default(Text("OK"))
     )
 }
 ```
 
 3. サービス層での使用:
 - 各サービスは独自のエラー型を定義して使用
 - ViewModelレベルでAppErrorに変換
 - これによりサービスの独立性を保ちつつ、UI層で統一的なエラーハンドリングが可能
 */

// MARK: - Error Conversion Helpers

extension AppError {
    /// エラーをAppErrorに変換するヘルパー
    static func from(_ error: Error) -> AppError {
        switch error {
        case let materialError as MaterialService.MaterialError:
            return .material(materialError)
        case let recorderError as AudioRecorder.RecorderError:
            return .recording(recorderError)
        case let recognizerError as SpeechRecognizer.RecognizerError:
            return .recognition(recognizerError)
        case let practiceError as PracticeError:
            return .practice(practiceError)
        default:
            return .unknown(error)
        }
    }
    
    /// ユーザー向けのアクション可能なメッセージを生成
    var userActionMessage: String? {
        switch self {
        case .material(let error):
            switch error {
            case .accessDenied:
                return "設定 > プライバシーとセキュリティ > ファイルとフォルダでアクセスを許可してください"
            case .fileTooLarge:
                return "100MB以下のファイルを選択してください"
            case .unsupportedFormat:
                return "対応形式: MP3, M4A, WAV"
            default:
                return recoverySuggestion
            }
            
        case .recording(let error):
            switch error {
            case .permissionDenied:
                return "設定 > プライバシーとセキュリティ > マイクでアクセスを許可してください"
            default:
                return recoverySuggestion
            }
            
        case .recognition(let error):
            switch error {
            case .notAuthorized:
                return "設定 > プライバシーとセキュリティ > 音声認識でアクセスを許可してください"
            case .notAvailable:
                return "インターネット接続を確認するか、設定 > 一般 > キーボード > 音声入力を有効にしてください"
            default:
                return recoverySuggestion
            }
            
        default:
            return recoverySuggestion
        }
    }
    
    /// エラーの重要度を判定
    var severity: ErrorSeverity {
        switch self {
        case .material(let error):
            switch error {
            case .accessDenied, .fileNotFound:
                return .critical
            case .fileTooLarge, .unsupportedFormat:
                return .warning
            default:
                return .info
            }
            
        case .recording(let error):
            switch error {
            case .permissionDenied:
                return .critical
            default:
                return .warning
            }
            
        case .recognition(let error):
            switch error {
            case .notAuthorized, .notAvailable:
                return .critical
            default:
                return .warning
            }
            
        case .practice:
            return .warning
            
        case .unknown:
            return .error
        }
    }
}

// MARK: - Error Severity

enum ErrorSeverity {
    case info      // 情報レベル（ユーザーへの通知のみ）
    case warning   // 警告レベル（操作は継続可能）
    case error     // エラーレベル（操作の一部が失敗）
    case critical  // 致命的（操作全体が失敗）
    
    var iconName: String {
        switch self {
        case .info:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.circle"
        case .critical:
            return "exclamationmark.octagon"
        }
    }
    
    var color: String {
        switch self {
        case .info:
            return "blue"
        case .warning:
            return "orange"
        case .error:
            return "red"
        case .critical:
            return "red"
        }
    }
}