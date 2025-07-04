import SwiftUI
import UniformTypeIdentifiers

enum ViewMode {
    case grid, list
}

enum SortOrder: String, CaseIterable {
    case createdDate = "作成日"
    case title = "タイトル"
    case practiceCount = "練習回数"
    case lastPracticed = "最終練習日"
}

struct MaterialsListView: View {
    @StateObject private var viewModel = MaterialsListViewModel()
    @State private var viewMode: ViewMode = .grid
    @State private var sortOrder: SortOrder = .createdDate
    @State private var searchText = ""
    @State private var showingFilePicker = false
    @State private var showingRecorder = false
    @State private var selectedMaterial: Material?
    
    var filteredMaterials: [Material] {
        var materials = viewModel.materials
        
        // 検索フィルタ
        if !searchText.isEmpty {
            materials = materials.filter { material in
                material.title.localizedCaseInsensitiveContains(searchText) ||
                (material.memo?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (material.transcription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // ソート
        switch sortOrder {
        case .createdDate:
            materials.sort { $0.createdAt > $1.createdAt }
        case .title:
            materials.sort { $0.title < $1.title }
        case .practiceCount:
            materials.sort { $0.practiceCount > $1.practiceCount }
        case .lastPracticed:
            materials.sort {
                guard let date1 = $0.lastPracticedAt else { return false }
                guard let date2 = $1.lastPracticedAt else { return true }
                return date1 > date2
            }
        }
        
        return materials
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // ビュー切り替えとソート
                HStack {
                    Picker("表示モード", selection: $viewMode) {
                        Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                        Image(systemName: "list.bullet").tag(ViewMode.list)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 100)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button(order.rawValue) {
                                sortOrder = order
                            }
                        }
                    } label: {
                        Label("並び替え: \(sortOrder.rawValue)", systemImage: "arrow.up.arrow.down")
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // コンテンツ
                if filteredMaterials.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        if viewMode == .grid {
                            MaterialGridView(materials: filteredMaterials, selectedMaterial: $selectedMaterial)
                                .padding()
                        } else {
                            MaterialListContentView(materials: filteredMaterials, selectedMaterial: $selectedMaterial)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("教材")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingFilePicker = true
                        } label: {
                            Label("ファイルから追加", systemImage: "doc.badge.plus")
                        }
                        
                        Button {
                            showingRecorder = true
                        } label: {
                            Label("録音して追加", systemImage: "mic.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker(completion: { url in
                    Task {
                        await viewModel.importAudioFile(from: url)
                    }
                })
            }
            .sheet(isPresented: $showingRecorder) {
                MaterialRecorderView { url in
                    Task {
                        await viewModel.importRecordedFile(from: url)
                    }
                }
            }
            .sheet(item: $selectedMaterial) { material in
                MaterialDetailView(material: material)
            }
        }
    }
}

// 検索バー
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("教材を検索", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

// 空の状態表示
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("教材がありません")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("音声ファイルをインポートするか\n録音して教材を作成してください")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// グリッド表示
struct MaterialGridView: View {
    let materials: [Material]
    @Binding var selectedMaterial: Material?
    
    let columns = [
        GridItem(.adaptive(minimum: 150))
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(materials) { material in
                MaterialGridItem(material: material)
                    .onTapGesture {
                        selectedMaterial = material
                    }
            }
        }
    }
}

// グリッドアイテム
struct MaterialGridItem: View {
    let material: Material
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // アイコン部分
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(height: 100)
                
                VStack(spacing: 4) {
                    Image(systemName: material.sourceType == .imported ? "doc.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    if material.isTranscribing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if material.transcription != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            
            // テキスト情報
            VStack(alignment: .leading, spacing: 4) {
                Text(material.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(formatDuration(material.duration))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                if material.practiceCount > 0 {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .font(.caption2)
                        Text("\(material.practiceCount)回練習")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// リスト表示
struct MaterialListContentView: View {
    let materials: [Material]
    @Binding var selectedMaterial: Material?
    
    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(materials) { material in
                MaterialListItem(material: material)
                    .onTapGesture {
                        selectedMaterial = material
                    }
            }
        }
    }
}

// リストアイテム
struct MaterialListItem: View {
    let material: Material
    
    var body: some View {
        HStack {
            // アイコン
            Image(systemName: material.sourceType == .imported ? "doc.fill" : "mic.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(material.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label(formatDuration(material.duration), systemImage: "clock")
                    
                    if material.practiceCount > 0 {
                        Label("\(material.practiceCount)回", systemImage: "checkmark.circle")
                    }
                    
                    if material.isTranscribing {
                        Label("文字起こし中", systemImage: "ellipsis")
                            .foregroundColor(.orange)
                    } else if material.transcription != nil {
                        Label("文字起こし済み", systemImage: "text.bubble")
                            .foregroundColor(.green)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// Preview
struct MaterialsListView_Previews: PreviewProvider {
    static var previews: some View {
        MaterialsListView()
    }
}