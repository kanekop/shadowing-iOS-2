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
            ZStack {
                VStack(spacing: 0) {
                // 検索バー
                StandardSearchBar(text: $searchText, placeholder: "教材を検索")
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.xs)
                
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
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                
                // コンテンツ
                if filteredMaterials.isEmpty {
                    EmptyStateView(
                        icon: "folder.badge.plus",
                        title: "教材がありません",
                        message: "音声ファイルをインポートするか\n録音して教材を作成してください"
                    )
                } else {
                    ScrollView {
                        if viewMode == .grid {
                            MaterialGridView(materials: filteredMaterials, selectedMaterial: $selectedMaterial)
                                .padding(DesignSystem.Spacing.md)
                        } else {
                            MaterialListContentView(materials: filteredMaterials, selectedMaterial: $selectedMaterial)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                    }
                }
                
                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
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
                            FloatingActionButton(systemName: "plus", action: {})
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                }
            }
            .navigationTitle("教材")
            }  // ZStack closing brace
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
                        await viewModel.importRecordedFile(from: url, title: "録音した教材")
                    }
                }
            }
            .sheet(item: $selectedMaterial) { material in
                MaterialDetailView(material: material)
            }
        }
    }
}

// グリッド表示
struct MaterialGridView: View {
    let materials: [Material]
    @Binding var selectedMaterial: Material?
    
    let columns = [
        GridItem(.adaptive(minimum: DesignSystem.Size.materialCardMinWidth))
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
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
        CardView {
            VStack(spacing: DesignSystem.Spacing.xs) {
                // アイコン部分
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                        .fill(DesignSystem.Colors.accent.opacity(0.1))
                        .aspectRatio(DesignSystem.Size.materialCardAspectRatio, contentMode: .fit)
                    
                    VStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: material.sourceType == .imported ? "doc.fill" : "mic.fill")
                            .font(.system(size: DesignSystem.Size.iconLarge))
                            .foregroundColor(DesignSystem.Colors.accent)
                        
                        if material.isTranscribing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if material.transcription != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.success)
                                .font(.system(size: DesignSystem.Size.iconSmall))
                        }
                    }
                }
                
                // テキスト情報
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text(material.title)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(formatDuration(material.duration))
                            .font(DesignSystem.Typography.caption)
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    if material.practiceCount > 0 {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 12))
                            Text("\(material.practiceCount)回練習")
                                .font(DesignSystem.Typography.caption)
                        }
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: DesignSystem.Size.materialCardMinWidth)
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
        LazyVStack(spacing: DesignSystem.Spacing.xs) {
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
        HStack(spacing: DesignSystem.Spacing.sm) {
            // アイコン
            Image(systemName: material.sourceType == .imported ? "doc.fill" : "mic.fill")
                .font(.system(size: DesignSystem.Size.iconMedium))
                .foregroundColor(DesignSystem.Colors.accent)
                .frame(width: DesignSystem.Size.minTouchTarget)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(material.title)
                    .font(DesignSystem.Typography.bodyLarge)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Label(formatDuration(material.duration), systemImage: "clock")
                    
                    if material.practiceCount > 0 {
                        Label("\(material.practiceCount)回", systemImage: "checkmark.circle")
                    }
                    
                    if material.isTranscribing {
                        Label("文字起こし中", systemImage: "ellipsis")
                            .foregroundColor(DesignSystem.Colors.warning)
                    } else if material.transcription != nil {
                        Label("文字起こし済み", systemImage: "text.bubble")
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: DesignSystem.Size.iconSmall))
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.md)
        .frame(minHeight: DesignSystem.Size.listItemHeight)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.Radius.standard)
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
