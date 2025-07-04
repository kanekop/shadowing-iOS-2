import SwiftUI

enum EngineType: String, CaseIterable {
    case apple = "apple"
    case whisper = "whisper"
    case google = "google"
    
    var displayName: String {
        switch self {
        case .apple: return "Apple Speech（無料）"
        case .whisper: return "OpenAI Whisper（高精度）"
        case .google: return "Google Speech（高精度）"
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .apple: return true
        case .whisper, .google: return false
        }
    }
}

struct SettingsView: View {
    @AppStorage("selectedEngine") private var selectedEngine: EngineType = .apple
    @AppStorage("enablePracticeReminder") private var enablePracticeReminder = false
    @AppStorage("reminderTime") private var reminderTime = Date()
    @AppStorage("autoDeleteOldRecordings") private var autoDeleteOldRecordings = true
    @AppStorage("retentionDays") private var retentionDays = 30
    @State private var showingAbout = false
    @State private var showingLicenses = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                // 音声認識設定
                Section(header: Text("音声認識")) {
                    Picker("認識エンジン", selection: $selectedEngine) {
                        ForEach(EngineType.allCases, id: \.self) { engine in
                            HStack {
                                Text(engine.displayName)
                                if !engine.isAvailable {
                                    Text("（準備中）")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tag(engine)
                        }
                    }
                    .disabled(true) // 現在はAppleのみ
                    
                    if selectedEngine != .apple {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("APIキーの設定が必要です")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 通知設定
                Section(header: Text("通知")) {
                    Toggle("練習リマインダー", isOn: $enablePracticeReminder)
                    
                    if enablePracticeReminder {
                        DatePicker(
                            "リマインダー時刻",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                
                // ストレージ設定
                Section(
                    header: Text("ストレージ"),
                    footer: Text("古い練習録音を自動的に削除してストレージを節約します")
                ) {
                    Toggle("古い録音を自動削除", isOn: $autoDeleteOldRecordings)
                    
                    if autoDeleteOldRecordings {
                        Stepper(
                            "\(retentionDays)日後に削除",
                            value: $retentionDays,
                            in: 7...90,
                            step: 7
                        )
                    }
                    
                    Button("キャッシュをクリア") {
                        clearCache()
                    }
                    
                    HStack {
                        Text("使用容量")
                        Spacer()
                        Text(formatStorageSize(getStorageUsage()))
                            .foregroundColor(.secondary)
                    }
                }
                
                // データ管理
                Section(header: Text("データ管理")) {
                    Button("すべての練習データを削除", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                }
                
                // アプリ情報
                Section(header: Text("アプリ情報")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text(getAppVersion())
                            .foregroundColor(.secondary)
                    }
                    
                    Button("このアプリについて") {
                        showingAbout = true
                    }
                    
                    Button("ライセンス") {
                        showingLicenses = true
                    }
                    
                    Link("プライバシーポリシー", destination: URL(string: "https://example.com/privacy")!)
                    
                    Link("利用規約", destination: URL(string: "https://example.com/terms")!)
                }
                
                // デバッグ（開発時のみ）
                #if DEBUG
                Section(header: Text("デバッグ")) {
                    Button("サンプルデータを追加") {
                        addSampleData()
                    }
                    
                    Button("すべてのUserDefaultsをリセット") {
                        resetUserDefaults()
                    }
                    .foregroundColor(.red)
                }
                #endif
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingLicenses) {
                LicensesView()
            }
            .alert("データを削除しますか？", isPresented: $showingDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("すべての教材と練習履歴が削除されます。この操作は取り消せません。")
            }
        }
    }
    
    private func clearCache() {
        // キャッシュクリアの実装
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            do {
                let cacheFiles = try FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
                for file in cacheFiles {
                    try FileManager.default.removeItem(at: file)
                }
            } catch {
                print("キャッシュクリアエラー: \(error)")
            }
        }
    }
    
    private func getStorageUsage() -> Int64 {
        var totalSize: Int64 = 0
        
        // Documents内のファイルサイズを計算
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if let enumerator = FileManager.default.enumerator(at: documentsURL, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize += Int64(fileSize)
                    }
                }
            }
        }
        
        return totalSize
    }
    
    private func formatStorageSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    private func deleteAllData() {
        // すべてのデータを削除
        // TODO: 実装
    }
    
    #if DEBUG
    private func addSampleData() {
        // サンプルデータを追加
        print("サンプルデータを追加しました")
    }
    
    private func resetUserDefaults() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
    #endif
}

// アバウトビュー
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // アプリアイコン
                    Image(systemName: "mic.badge.plus")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                        .padding(.top, 40)
                    
                    // アプリ名
                    Text("シャドウィング練習")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("英語の発音を改善するアプリ")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // 説明
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "mic.fill",
                            title: "シャドウィング練習",
                            description: "音声を聞きながら同時に発音する練習法"
                        )
                        
                        FeatureRow(
                            icon: "text.bubble",
                            title: "音読練習",
                            description: "テキストを見ながら正確に発音する練習"
                        )
                        
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "詳細な評価",
                            description: "AIによる発音の正確性評価とフィードバック"
                        )
                        
                        FeatureRow(
                            icon: "doc.badge.plus",
                            title: "柔軟な教材",
                            description: "音声ファイルをインポートまたは録音して教材作成"
                        )
                    }
                    .padding(.horizontal)
                    
                    // 開発者情報
                    VStack(spacing: 8) {
                        Text("開発者")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Your Name")
                            .font(.body)
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("このアプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 機能行
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// ライセンスビュー
struct LicensesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("オープンソースライブラリ") {
                    Text("このアプリは以下のオープンソースライブラリを使用しています")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    
                    // 現在は外部ライブラリを使用していない
                    Text("現在、外部ライブラリは使用していません")
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                Section("システムフレームワーク") {
                    LicenseRow(name: "AVFoundation", license: "Apple SDK")
                    LicenseRow(name: "Speech Framework", license: "Apple SDK")
                    LicenseRow(name: "SwiftUI", license: "Apple SDK")
                }
            }
            .navigationTitle("ライセンス")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// ライセンス行
struct LicenseRow: View {
    let name: String
    let license: String
    
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Text(license)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}