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
                    practiceMode: practiceMode,
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
                // 教材選択画面を表示
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
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: material.sourceType == .imported ? "doc.fill" : "mic.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text(material.title)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(formatDuration(material.duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 120, height: 100)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
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
    let practiceMode: PracticeMode
    let onComplete: (PracticeResult) -> Void
    let onChangeMaterial: () -> Void
    
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
                    Picker("練習モード", selection: .constant(practiceMode)) {
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
                Task {
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
        // TODO: 音声認識と評価の実装
        // 仮の結果を表示
        let result = PracticeResult(
            id: UUID(),
            materialId: material.id,
            practiceType: practiceMode == .reading ? .reading : .shadowing,
            recordingURL: recordingURL,
            recordedAt: Date(),
            duration: recorder.recordingTime,
            recognizedText: "This is a sample recognized text",
            score: 85.5,
            wordErrorRate: 0.15,
            accuracy: 85.5,
            fluencyScore: 80.0,
            pronunciationScore: 90.0,
            wordsPerMinute: 120,
            wordAnalysis: []
        )
        
        practiceResult = result
        showingResult = true
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
            VStack(alignment: .leading, spacing: 4) {
                Text(material.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Label(practiceMode.rawValue, systemImage: practiceMode.icon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(formatDuration(material.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("変更") {
                onChangeMaterial()
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
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
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(value == 0 ? 1.5 : 1.0)
                .opacity(value == 0 ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: value)
        }
    }
}

// Preview
struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeView()
    }
}