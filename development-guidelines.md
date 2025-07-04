# ShadowingPractice 開発ガイドライン v2.0

## 変更履歴
- v2.0 (2025/07/04): 実装経験に基づく更新

## 1. 開発環境と制約

### 開発環境
- **IDE**: Xcode 16.3以降
- **macOS**: Sonoma以降推奨
- **開発言語**: Swift 5.0以降
- **UIフレームワーク**: SwiftUI（UIKit使用は音声波形表示等の特殊ケースのみ）
- **最小サポートiOS**: 17.0（iOS 18.4の新機能は使用せず互換性重視）
- **対象デバイス**: iPhone専用（iPad対応は将来検討）

### 制約事項
- **外部ライブラリ**: 原則使用不可（Pure Swift/SwiftUIのみ）
- **サードパーティSDK**: 音声認識API以外は使用しない
- **ファイルサイズ**: アプリ本体は50MB以下を目標
- **オフライン対応**: 基本機能はオフラインで動作必須

## 2. 実装から得た重要な知見

### 2.1 AVAudioSession管理
**問題**: 録音と認識のセッション競合により0%問題が発生
**解決策**:
```swift
// 録音終了後、必ずセッションを非アクティブ化
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    try? AVAudioSession.sharedInstance().setActive(false)
}
```

### 2.2 ファイルアクセス権限
**問題**: DocumentPickerで選択したファイルへのアクセスエラー
**解決策**:
```swift
guard url.startAccessingSecurityScopedResource() else {
    throw ImportError.accessDenied
}
defer { url.stopAccessingSecurityScopedResource() }
```

### 2.3 SwiftUIでの非同期処理
**問題**: @StateObjectと@ObservedObjectの誤用によるView更新問題
**解決策**:
- ViewModelは必ず`@StateObject`で初期化
- 子Viewへの受け渡しは`@ObservedObject`使用
- `Task { @MainActor in }`でUI更新を確実に実行

### 2.4 音声認識の精度向上
**実装で判明した最適設定**:
```swift
request.shouldReportPartialResults = true
request.taskHint = .dictation
request.requiresOnDeviceRecognition = false  // オンライン認識で精度UP
if #available(iOS 16, *) {
    request.addsPunctuation = true  // 句読点自動追加
}
```

## 3. アーキテクチャ最適化

### 3.1 推奨ディレクトリ構造
```
ShadowingPractice/
├── App/                    # アプリのエントリーポイント
├── Core/
│   ├── Models/            # データモデル（Codable準拠）
│   ├── Services/          # ビジネスロジック（シングルトン）
│   └── Utilities/         # 汎用ユーティリティ
├── Features/              # 機能別モジュール
│   ├── [Feature]/
│   │   ├── Views/        # SwiftUIビュー
│   │   ├── ViewModels/   # ViewModelクラス
│   │   └── Components/   # 再利用可能なコンポーネント
└── Shared/
    ├── Views/            # 共通UIコンポーネント
    └── Extensions/       # Swift拡張
```

### 3.2 命名規則（更新）
- **View**: `〜View`（例: `MaterialListView`）
- **ViewModel**: `〜ViewModel`（例: `PracticeViewModel`）
- **Service**: `〜Service`（シングルトン、例: `MaterialService.shared`）
- **Model**: 単数形の名詞（例: `Material`, `PracticeSession`）
- **Extension**: `型名+機能.swift`（例: `FileManager+Audio.swift`）

### 3.3 依存性注入パターン
```swift
// ❌ 避けるべき：View内でのService直接参照
struct SomeView: View {
    let result = MaterialService.shared.loadMaterials()  // Bad
}

// ✅ 推奨：ViewModelを介したアクセス
class SomeViewModel: ObservableObject {
    private let materialService = MaterialService.shared
    
    func loadMaterials() {
        // ViewModelでServiceを使用
    }
}
```

## 4. エラーハンドリングベストプラクティス

### 4.1 エラーの種類と対処法
```swift
enum AppError: LocalizedError {
    case recoverable(message: String, retry: (() -> Void)?)
    case userAction(message: String, action: UserAction)
    case fatal(Error)
    
    var errorDescription: String? {
        switch self {
        case .recoverable(let message, _):
            return message
        case .userAction(let message, _):
            return message
        case .fatal(let error):
            return "予期しないエラー: \(error.localizedDescription)"
        }
    }
}

enum UserAction {
    case openSettings
    case checkNetwork
    case freeUpStorage
}
```

### 4.2 ユーザーフレンドリーなエラー表示
```swift
// エラー時は具体的な解決方法を提示
.alert(item: $viewModel.error) { error in
    Alert(
        title: Text("エラー"),
        message: Text(error.localizedDescription),
        primaryButton: .default(Text("再試行")) {
            error.retry?()
        },
        secondaryButton: .cancel(Text("キャンセル"))
    )
}
```

## 5. パフォーマンス最適化テクニック

### 5.1 メモリ管理
```swift
// ❌ 避けるべき：強参照サイクル
class ViewModel: ObservableObject {
    var timer: Timer?
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.update()  // selfへの強参照
        }
    }
}

// ✅ 推奨：weak selfの使用
func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        self?.update()
    }
}
```

### 5.2 非同期処理の最適化
```swift
// 並列実行で高速化
func loadAllData() async {
    async let materials = loadMaterials()
    async let history = loadHistory()
    async let settings = loadSettings()
    
    let (mat, hist, set) = await (materials, history, settings)
    // すべてのデータが並列で読み込まれる
}
```

### 5.3 SwiftUIビューの最適化
```swift
// ❌ 避けるべき：不必要な再レンダリング
struct BadView: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            ForEach(viewModel.items) { item in
                ItemView(item: item, viewModel: viewModel)  // ViewModelを渡すと全体が再描画
            }
        }
    }
}

// ✅ 推奨：必要最小限のデータのみ渡す
struct GoodView: View {
    var body: some View {
        VStack {
            ForEach(viewModel.items) { item in
                ItemView(item: item, onTap: { viewModel.selectItem(item) })
            }
        }
    }
}
```

## 6. 音声処理のベストプラクティス

### 6.1 録音品質の設定
```swift
// 用途別の最適設定
struct AudioSettings {
    // 教材録音（ファイルサイズ重視）
    static let materialRecording: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,  // モノラル
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        AVEncoderBitRateKey: 128000
    ]
    
    // 練習録音（品質重視）
    static let practiceRecording: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 2,  // ステレオ
        AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
        AVEncoderBitRateKey: 256000
    ]
}
```

### 6.2 音声認識の最適化
```swift
// バッチ処理で効率化
func transcribeMaterials(_ materials: [Material]) async {
    // 最大3つまで並列実行
    await withTaskGroup(of: Void.self) { group in
        for material in materials {
            group.addTask {
                await self.transcribeSingle(material)
            }
            
            // 並列数を制限
            if group.count >= 3 {
                await group.next()
            }
        }
    }
}
```

## 7. UI/UXガイドライン

### 7.1 レスポンシブデザイン
```swift
struct ResponsiveView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var columns: [GridItem] {
        sizeClass == .compact ? 
            [GridItem(.flexible())] :  // iPhone: 1列
            [GridItem(.flexible()), GridItem(.flexible())]  // iPad: 2列
    }
}
```

### 7.2 アクセシビリティ
```swift
Button(action: startRecording) {
    Image(systemName: "mic.fill")
}
.accessibilityLabel("録音開始")
.accessibilityHint("タップして録音を開始します")
```

### 7.3 フィードバックの即時性
```swift
// ユーザーアクションには必ず即座にフィードバック
Button("インポート") {
    // 即座にローディング表示
    isLoading = true
    
    Task {
        do {
            try await importFile()
        } catch {
            // エラー処理
        }
        isLoading = false
    }
}
.disabled(isLoading)
.overlay(isLoading ? ProgressView() : nil)
```

## 8. テスト戦略

### 8.1 ユニットテスト必須項目
```swift
class TextComparisonTests: XCTestCase {
    func testAccuracyCalculation() {
        // 境界値テスト
        XCTAssertEqual(service.calculateAccuracy(correct: 0, total: 0), 0)
        XCTAssertEqual(service.calculateAccuracy(correct: 10, total: 10), 100)
        XCTAssertEqual(service.calculateAccuracy(correct: 7, total: 10), 70)
    }
    
    func testEdgeCases() {
        // エッジケース
        XCTAssertNoThrow(service.compare(original: "", recognized: ""))
        XCTAssertNoThrow(service.compare(original: "test", recognized: ""))
    }
}
```

### 8.2 UIテストのポイント
- 権限リクエストのモック
- ファイル選択のシミュレーション
- 非同期処理の待機
- エラー状態の再現

## 9. リリース前チェックリスト

### 9.1 パフォーマンス
- [ ] Instrumentsでメモリリーク確認
- [ ] 起動時間が3秒以内
- [ ] 60fps維持（ProMotion対応）
- [ ] バッテリー消費の最適化

### 9.2 品質保証
- [ ] すべての画面でVoiceOver動作確認
- [ ] Dynamic Type（文字サイズ）対応
- [ ] ダークモード完全対応
- [ ] 各iOSバージョンでの動作確認

### 9.3 App Store要件
- [ ] スクリーンショット準備（ダークモード版も）
- [ ] App Preview動画（オプション）
- [ ] メタデータのローカライズ
- [ ] Export Compliance（暗号化なし）

## 10. トラブルシューティング

### 10.1 よくある問題と解決策

#### 音声認識が0%になる
1. AVAudioSessionが正しく解放されているか確認
2. 音声ファイルの形式とサンプリングレートを確認
3. 認識言語設定が正しいか確認

#### メモリ使用量が増え続ける
1. Timer、NotificationCenterの解放確認
2. Combineのcancellable管理
3. 循環参照の確認（weak self使用）

#### UI更新が反映されない
1. @Publishedプロパティの使用確認
2. MainActorでの更新確認
3. ObservableObjectの正しい実装

### 10.2 デバッグTips
```swift
// 条件付きログ出力
#if DEBUG
Logger.shared.debug("詳細なデバッグ情報")
#endif

// メモリ使用量の監視
var memoryFootprint: Float {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    return result == KERN_SUCCESS ? Float(info.resident_size) / 1024.0 / 1024.0 : 0
}
```

---

このガイドラインv2.0は、実際の開発経験に基づいて大幅に更新されました。
特に、AVAudioSession管理、SwiftUIの最適化、エラーハンドリングに関する実践的な知見を追加しています。