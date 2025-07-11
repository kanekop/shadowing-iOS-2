import SwiftUI
import AVFoundation

enum PracticeMode: String, CaseIterable, Codable {
    case reading = "音読"
    case shadowing = "シャドウィング"
    
    var description: String {
        switch self {
        case .reading:
            return "教材のテキストを見ながら音読練習"
        case .shadowing:
            return "教材音声を聞きながら同時に発音"
        }
    }
    
    var icon: String {
        switch self {
        case .reading:
            return "text.bubble"
        case .shadowing:
            return "headphones"
        }
    }
}

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @State private var selectedMaterial: Material?
    @State private var showingMaterialPicker = false
    @State private var practiceMode: PracticeMode = .reading
    
    var body: some View {
        NavigationView {
            if selectedMaterial == nil {
                // 教材未選択状態
                MaterialSelectionView(
                    onSelectMaterial: { material in
                        selectedMaterial = material
                    }
                )
            } else {
                // 練習画面
                PracticeContentView(
                    material: selectedMaterial!,
                    practiceMode: $practiceMode,
                    onComplete: { result in
                        // 練習完了後の処理
                        viewModel.savePracticeResult(result)
                    },
                    onChangeMaterial: {
                        selectedMaterial = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showingMaterialPicker) {
            MaterialPickerView { material in
                selectedMaterial = material
            }
        }
    }
}

// 教材選択画面
struct MaterialSelectionView: View {
    let onSelectMaterial: (Material) -> Void
    @State private var recentMaterials: [Material] = []
    @State private var showingMaterialPicker = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // アイコン
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            // タイトル
            VStack(spacing: 8) {
                Text("練習を始める")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("教材を選択して練習を開始しましょう")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 教材選択ボタン
            Button {
                showingMaterialPicker = true
            } label: {
                Label("教材を選択", systemImage: "folder.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // 最近の教材
            if !recentMaterials.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("最近使った教材")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(recentMaterials.prefix(5)) { material in
                                RecentMaterialCard(material: material) {
                                    onSelectMaterial(material)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            Spacer()
        }
        .navigationTitle("練習")
        .onAppear {
            loadRecentMaterials()
        }
        .sheet(isPresented: $showingMaterialPicker) {
            MaterialPickerView { material in
                onSelectMaterial(material)
            }
        }
    }
    
    private func loadRecentMaterials() {
        // TODO: 最近使った教材を読み込む
        // 仮データ
        #if DEBUG
        recentMaterials = [Material.sampleData[0]]
        #endif
    }
}

// 最近の教材カード
struct RecentMaterialCard: View {
    let material: Material
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Image(systemName: material.sourceType == .imported ? "doc.fill" : "mic.fill")
                    .font(.system(size: DesignSystem.Size.iconMedium))
                    .foregroundColor(DesignSystem.Colors.accent)
                
                Text(material.title)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(formatDuration(material.duration))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .frame(width: 120, height: 100)
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.backgroundSecondary)
            .cornerRadius(DesignSystem.Radius.large)
        }
        .buttonStyle(ButtonPressStyle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// 練習コンテンツビュー
struct PracticeContentView: View {
    let material: Material
    @Binding var practiceMode: PracticeMode
    let onComplete: (PracticeResult) -> Void
    let onChangeMaterial: () -> Void
    
    @StateObject private var viewModel = PracticeViewModel()
    @StateObject private var recorder = AudioRecorder()
    @State private var isPracticing = false
    @State private var showingResult = false
    @State private var practiceResult: PracticeResult?
    @State private var showingCountdown = false
    @State private var countdownValue = 3
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            PracticeHeaderView(
                material: material,
                practiceMode: practiceMode,
                onChangeMaterial: onChangeMaterial
            )
            
            // コンテンツ
            ScrollView {
                VStack(spacing: 20) {
                    // 練習モード選択
                    Picker("練習モード", selection: $practiceMode) {
                        ForEach(PracticeMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // モード説明
                    Text(practiceMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // 練習エリア
                    if practiceMode == .reading {
                        ReadingPracticeView(
                            material: material,
                            recorder: recorder,
                            isPracticing: $isPracticing,
                            onComplete: handlePracticeComplete
                        )
                    } else {
                        ShadowingPracticeView(
                            material: material,
                            recorder: recorder,
                            isPracticing: $isPracticing,
                            onComplete: handlePracticeComplete
                        )
                    }
                }
                .padding(.vertical)
            }
            
            // 録音コントロール
            if !showingResult {
                RecordingControlView(
                    recorder: recorder,
                    isPracticing: $isPracticing,
                    showingCountdown: $showingCountdown,
                    countdownValue: $countdownValue,
                    onStart: startPractice,
                    onStop: stopPractice
                )
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingResult) {
            if let result = practiceResult {
                PracticeResultView(result: result) {
                    // もう一度練習
                    showingResult = false
                    practiceResult = nil
                }
            }
        }
        .overlay(
            // カウントダウンオーバーレイ
            Group {
                if showingCountdown {
                    CountdownOverlay(value: $countdownValue)
                }
            }
        )
    }
    
    private func startPractice() {
        // カウントダウン開始
        showingCountdown = true
        countdownValue = 3
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdownValue -= 1
            if countdownValue == 0 {
                timer.invalidate()
                showingCountdown = false
                
                // 録音開始
                Task { @MainActor in
                    do {
                        try await recorder.startRecording(isMaterial: false)
                        isPracticing = true
                    } catch {
                        // エラー処理
                        print("録音開始エラー: \(error)")
                    }
                }
            }
        }
    }
    
    private func stopPractice() {
        recorder.stopRecording { result in
            switch result {
            case .success(let url):
                // 音声認識と評価を実行
                Task {
                    await analyzePractice(recordingURL: url)
                }
            case .failure(let error):
                print("録音停止エラー: \(error)")
            }
        }
        isPracticing = false
    }
    
    private func analyzePractice(recordingURL: URL) async {
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
    
    private func handlePracticeComplete(_ result: PracticeResult) {
        practiceResult = result
        showingResult = true
        onComplete(result)
    }
}

// 練習ヘッダービュー
struct PracticeHeaderView: View {
    let material: Material
    let practiceMode: PracticeMode
    let onChangeMaterial: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(material.title)
                    .font(DesignSystem.Typography.h4)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Label(practiceMode.rawValue, systemImage: practiceMode.icon)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("•")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(formatDuration(material.duration))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            TextButton(title: "変更", action: onChangeMaterial)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.backgroundSecondary)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// カウントダウンオーバーレイ
struct CountdownOverlay: View {
    @Binding var value: Int
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            Text("\(value)")
                .font(DesignSystem.Typography.displayMedium) // 48pt instead of 120pt
                .foregroundColor(.white)
                .scaleEffect(value == 0 ? 1.5 : 1.0)
                .opacity(value == 0 ? 0 : 1)
                .animation(DesignSystem.Animation.springBouncy, value: value)
        }
    }
}

// Preview
struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeView()
    }
}
