import Foundation

enum AppError: LocalizedError {
    case material(MaterialService.MaterialError)
    case recording(AudioRecorder.RecorderError)
    case recognition(SpeechRecognizer.RecognizerError)
    case practice(PracticeError)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .material(let error):
            return error.errorDescription
        case .recording(let error):
            return error.errorDescription
        case .recognition(let error):
            return error.errorDescription
        case .practice(let error):
            return error.errorDescription
        case .unknown(let error):
            return "予期しないエラー: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .material(let error):
            switch error {
            case .accessDenied:
                return "設定からファイルアクセスを許可してください"
            case .fileTooLarge:
                return "より小さいファイルを選択してください"
            default:
                return nil
            }
        case .recording(let error):
            switch error {
            case .permissionDenied:
                return "設定からマイクへのアクセスを許可してください"
            default:
                return "もう一度お試しください"
            }
        case .recognition(let error):
            switch error {
            case .notAuthorized:
                return "設定から音声認識を許可してください"
            case .notAvailable:
                return "オフライン音声認識を試すか、ネットワーク接続を確認してください"
            default:
                return nil
            }
        default:
            return nil
        }
    }
}