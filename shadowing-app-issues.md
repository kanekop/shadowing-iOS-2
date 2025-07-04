# ShadowingPractice2 - 実装上の問題点と修正指示書

## 概要
本ドキュメントは、ShadowingPractice2プロジェクトの現在の実装における問題点と、それらの修正方法を記載したものです。コーダーは以下の指示に従って修正を行ってください。

## 1. 重大な問題：PracticeResult初期化エラー

### 問題箇所
`Features/Practice/PracticeViewModel.swift`の`analyzePracticeRecording`メソッド

### 現在のコード（エラー）
```swift
let result = PracticeResult(
    recognizedText: recognizedText,
    originalText: originalText,
    wordAnalysis: comparisonResult.wordAnalysis,
    recordingURL: url,
    duration: duration,
    practiceType: mode
)
```

### 修正方法
```swift
let result = PracticeResult(
    id: UUID(),  // 明示的にIDを指定
    recognizedText: recognizedText,
    originalText: originalText,
    wordAnalysis: comparisonResult.wordAnalysis,
    recordingURL: url,
    duration: duration,
    practiceType: mode
)
```

## 2. PracticeResultモデルのプロパティ不足

### 問題箇所
`Features/History/HistoryView.swift`で`result.recordedAt`を参照しているが、`PracticeResult`には存在しない

### 修正方法
`Core/Models/PracticeResult.swift`に以下を追加：

```swift
extension PracticeResult {
    /// createdAtのエイリアス（互換性のため）
    var recordedAt: Date { createdAt }
}
```

## 3. AVAudioSession解放の問題（0%認識率バグ対策）

### 問題箇所
`Core/Services/AudioRecorder.swift`の`stopRecording`メソッド

### 現在のコード
```swift
try? recordingSession.setActive(false)
```

### 修正方法
```swift
// セッションを非アクティブ化（遅延を入れて確実に解放）
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    try? AVAudioSession.sharedInstance().setActive(false)
}
```

## 4. PracticeViewとViewModelの接続不足

### 問題箇所
`Features/Practice/PracticeView.swift`の`analyzePractice`メソッド

### 現在のコード
```swift
private func analyzePractice(recordingURL: URL) async {
    // TODO: 音声認識と評価の実装
    // 仮の結果を表示
    let result = PracticeResult(
        recognizedText: "This is a sample recognized text",
        originalText: material.transcription ?? "Original text not available",
        wordAnalysis: [],
        recordingURL: recordingURL,
        duration: recorder.recordingTime,
        practiceType: practiceMode
    )
    
    practiceResult = result
    showingResult = true
}
```

### 修正方法
```swift
private func analyzePractice(recordingURL: URL) async {
    guard let material = selectedMaterial else { return }
    
    // ViewModelを使用して実際の処理を実行
    viewModel.startPracticeSession(material: material, mode: practiceMode)
    
    do {
        let result = try await viewModel.analyzePracticeRecording(
            url: recordingURL, 
            mode: practiceMode
        )
        
        await MainActor.run {
            practiceResult = result
            showingResult = true
        }
    } catch {
        await MainActor.run {
            // エラー処理
            print("練習の分析エラー: \(error)")
            // エラーアラートを表示
        }
    }
}
```

## 5. メモリリークの可能性

### 問題箇所
`Features/Practice/ShadowingPracticeView.swift`の`startShadowing`メソッド

### 現在のコード
```swift
audioPlayer.onPlaybackFinished = { [weak recorder] in
    recorder?.stopRecording { result in
        isPracticing = false
        // 結果処理
    }
}
```

### 修正方法
```swift
audioPlayer.onPlaybackFinished = { [weak recorder, weak audioPlayer] in
    recorder?.stopRecording { result in
        Task { @MainActor in
            isPracticing = false
            // 結果処理
            audioPlayer?.onPlaybackFinished = nil  // クロージャを解放
        }
    }
}
```

## 6. 共通コンポーネントの整理

### 作業内容
以下のファイルを作成し、重複コードを整理：

#### 1. `Shared/Views/SearchBar.swift`
```swift
import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "検索"
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
```

#### 2. `Shared/Views/EmptyStateView.swift`
```swift
import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
```

### 既存コードの修正
`MaterialsListView.swift`と`HistoryView.swift`から重複する`SearchBar`定義を削除し、共通コンポーネントを使用するように変更。

## 7. エラーハンドリングの統一

### 作業内容
新規ファイル`Core/Models/AppError.swift`を作成：

```swift
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
```

## 8. ドキュメントの更新

### CLAUDE.mdの更新箇所

#### "Current Implementation Status"セクションを以下に更新：

```markdown
### Completed Features
- ✅ Material management (import, record, delete)
- ✅ Audio recording with AVAudioRecorder
- ✅ Speech recognition with SFSpeechRecognizer
- ✅ Text comparison and diff display
- ✅ Practice result scoring and analysis
- ✅ Basic UI for all main features
- ✅ Practice mode implementation (reading & shadowing)
- ✅ History view with statistics

### Known Issues Being Fixed
- 🔧 PracticeResult initialization signature mismatch
- 🔧 AVAudioSession proper deactivation for 0% recognition issue
- 🔧 Memory leak in audio playback callbacks
- 🔧 Shared components organization

### Pending Features
- ⏳ Practice history persistence to disk
- ⏳ Material transcription caching
- ⏳ Advanced statistics and progress tracking
- ⏳ Export functionality for practice results
- ⏳ iPad support
- ⏳ Offline speech recognition optimization
```

## 9. テスト追加

### 必須テストケース
以下のテストを`ShadowingPractice2Tests`に追加：

```swift
func testPracticeResultInitialization() {
    let result = PracticeResult(
        recognizedText: "test",
        originalText: "test",
        wordAnalysis: []
    )
    XCTAssertNotNil(result.id)
    XCTAssertEqual(result.recordedAt, result.createdAt)
}

func testAVAudioSessionDeactivation() async {
    let recorder = AudioRecorder()
    try? await recorder.startRecording()
    
    let expectation = XCTestExpectation(description: "Session deactivated")
    
    recorder.stopRecording { _ in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertFalse(AVAudioSession.sharedInstance().isOtherAudioPlaying)
            expectation.fulfill()
        }
    }
    
    await fulfillment(of: [expectation], timeout: 1.0)
}
```

## 10. ビルド設定の確認

### Info.plistの確認
以下の権限設定が正しく記載されているか確認：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>このアプリは発音練習のために音声を録音します。録音された音声はデバイス内でのみ処理され、外部に送信されることはありません。</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>このアプリは録音した音声を文字起こしして、発音の正確性を評価します。音声認識はデバイス内で行われます。</string>
```

## 実装優先順位

1. **最優先**：項目1, 2, 3（アプリがクラッシュする可能性のある問題）
2. **高優先**：項目4, 5（機能が正しく動作しない問題）
3. **中優先**：項目6, 7（コード品質とメンテナンス性）
4. **低優先**：項目8, 9, 10（ドキュメントとテスト）

## 完了確認チェックリスト

- [ ] PracticeResult初期化エラーが解消されビルドが通る
- [ ] 練習履歴画面でクラッシュしない
- [ ] 音声認識が0%にならない（5回以上テスト）
- [ ] 練習結果が正しく表示される
- [ ] メモリリークがない（Instrumentsで確認）
- [ ] 共通コンポーネントが整理されている
- [ ] エラーハンドリングが統一されている
- [ ] ドキュメントが更新されている
- [ ] テストが追加され、すべてパスする

以上の修正を完了させることで、アプリの安定性と保守性が大幅に向上します。