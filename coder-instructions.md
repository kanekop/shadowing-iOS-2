# ShadowingPractice2 修正指示書

## 概要
本ドキュメントは、ShadowingPractice2プロジェクトで発見された不整合と問題点を修正するための指示書です。優先度順に対応してください。

## 1. 【優先度：高】iOS バージョン要件の統一

### 問題
プロジェクト設定とドキュメントでiOSバージョン要件が異なっています。

### 修正内容
`ShadowingPractice2.xcodeproj/project.pbxproj`を修正：
```
IPHONEOS_DEPLOYMENT_TARGET = 17.0;
```
※ Debug/Release両方の設定を変更してください

### 確認方法
- Xcode上でプロジェクト設定を確認
- iOS 17.0のシミュレータでビルド・実行できることを確認

## 2. 【優先度：高】PracticeResultモデルの修正

### 問題
`PracticeResult`モデルに必要なプロパティが不足しており、ViewやViewModelでエラーが発生しています。

### 修正内容
`ShadowingPractice2/Core/Models/PracticeResult.swift`に以下のプロパティを追加：

```swift
struct PracticeResult: Identifiable, Codable {
    // 既存のプロパティに加えて以下を追加
    
    // 基本情報
    let materialId: UUID
    let practiceType: PracticeSession.PracticeType
    let recordingURL: URL
    let recordedAt: Date
    let duration: TimeInterval
    
    // 評価メトリクス（既存のものと統合）
    var score: Double { overallScore }  // エイリアス
    let accuracy: Double  // accuracyScoreのエイリアス or 新規
    let wordErrorRate: Double
    let wordsPerMinute: Double
    
    // 新しいinitメソッドを追加
    init(
        id: UUID = UUID(),
        materialId: UUID,
        practiceType: PracticeSession.PracticeType,
        recordingURL: URL,
        recordedAt: Date,
        duration: TimeInterval,
        recognizedText: String,
        originalText: String,
        score: Double,
        wordErrorRate: Double,
        accuracy: Double,
        fluencyScore: Double,
        pronunciationScore: Double,
        wordsPerMinute: Double,
        wordAnalysis: [WordAnalysis]
    ) {
        // 実装
    }
}
```

### 修正後の対応
- `PracticeResult.sampleData`も新しい初期化方法に合わせて更新
- コンパイルエラーがないことを確認

## 3. 【優先度：高】MaterialServiceの文字起こし機能実装

### 問題
`transcribeMaterial`メソッドが未実装のまま呼び出されています。

### 修正内容
`ShadowingPractice2/Core/Services/MaterialService.swift`の`transcribeMaterial`メソッドを実装：

```swift
func transcribeMaterial(_ material: Material) async throws {
    // 文字起こし中フラグを設定
    var updatedMaterial = material
    updatedMaterial.isTranscribing = true
    await updateMaterialAsync(updatedMaterial)
    
    do {
        // SpeechRecognizerを使用して文字起こし
        let recognizer = SpeechRecognizer.shared
        let transcription = try await recognizer.recognizeFromFile(url: material.url)
        
        // 結果を保存
        updatedMaterial.transcription = transcription
        updatedMaterial.isTranscribing = false
        updatedMaterial.transcriptionError = nil
        
    } catch {
        // エラーを記録
        updatedMaterial.isTranscribing = false
        updatedMaterial.transcriptionError = error.localizedDescription
        Logger.shared.error("文字起こしエラー: \(error)")
    }
    
    await updateMaterialAsync(updatedMaterial)
}
```

## 4. 【優先度：中】PracticeViewModelの評価処理実装

### 問題
`PracticeView.swift`の`analyzePractice`メソッドが仮データを返しています。

### 修正内容
`ShadowingPractice2/Features/Practice/PracticeView.swift`の`analyzePractice`メソッドを修正：

```swift
private func analyzePractice(recordingURL: URL) async {
    guard let material = selectedMaterial else { return }
    
    // ViewModelを使用して実際の評価を実行
    do {
        let viewModel = PracticeViewModel()
        viewModel.currentMaterial = material
        
        let result = try await viewModel.analyzePracticeRecording(
            url: recordingURL,
            mode: practiceMode
        )
        
        practiceResult = result
        showingResult = true
    } catch {
        // エラー処理
        print("評価エラー: \(error)")
    }
}
```

## 5. 【優先度：中】未実装機能の明示化

### 問題
未実装機能がユーザーには実装済みのように見えます。

### 修正内容

#### 5.1 音声波形表示
`ShadowingPractice2/Features/Practice/ShadowingPracticeView.swift`：
```swift
// 波形表示部分を修正
Text("音声波形（準備中）")
    .foregroundColor(.secondary)
    .italic()
```

#### 5.2 設定画面のデータ削除
`ShadowingPractice2/Features/Settings/SettingsView.swift`：
```swift
private func deleteAllData() {
    // アラートを表示
    Logger.shared.warning("データ削除機能は未実装です")
    // TODO: 実装
}
```

## 6. 【優先度：低】ドキュメントの更新

### 修正内容

#### 6.1 CLAUDE.mdの更新
以下の内容を追加：
- iOS最小バージョンを17.0に統一した旨を記載
- 既知の未実装機能リストを追加
- PracticeResultモデルの構造変更を記載

#### 6.2 lesson-learnt-iOSdev.mdの古い情報削除
- AudioRecorderの重複メソッド問題の記述を削除（既に解決済み）

## 7. 【優先度：低】エラー型の統一

### 問題
エラーハンドリングが統一されていません。

### 修正内容（将来的な改善案）
`ShadowingPractice2/Core/Utilities/`に`AppError.swift`を作成：

```swift
enum AppError: LocalizedError {
    case recoverable(message: String, retry: (() -> Void)?)
    case userAction(message: String, action: UserAction)
    case fatal(Error)
    
    // 実装詳細は development-guidelines.md 参照
}
```

※ この修正は大規模なリファクタリングになるため、次のフェーズで対応することを推奨

## テスト項目

修正完了後、以下をテストしてください：

1. **iOS 17.0互換性**
   - iOS 17.0シミュレータでの起動確認
   - 基本機能の動作確認

2. **練習機能**
   - 音読練習の完全フロー（録音→評価→結果表示）
   - シャドウィング練習の完全フロー
   - 評価結果の妥当性確認

3. **文字起こし機能**
   - 新規教材インポート時の自動文字起こし
   - 文字起こしエラー時の表示確認

4. **UI/UX**
   - 未実装機能の「準備中」表示確認
   - エラーメッセージの適切な表示

## 納期目安

- 優先度「高」: 2日以内
- 優先度「中」: 3日以内  
- 優先度「低」: 1週間以内

## 質問・相談

実装で不明な点があれば、以下の情報と共に質問してください：
- 該当するファイル名と行番号
- エラーメッセージ（ある場合）
- 試した解決策

以上