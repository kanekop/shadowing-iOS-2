import SwiftUI

struct MaterialPickerView: View {
    @StateObject private var viewModel = MaterialPickerViewModel()
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    let onSelect: (Material) -> Void
    
    var filteredMaterials: [Material] {
        if searchText.isEmpty {
            return viewModel.materials
        } else {
            return viewModel.materials.filter { material in
                material.title.localizedCaseInsensitiveContains(searchText) ||
                (material.transcription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー
                SearchBar(text: $searchText)
                    .padding()
                
                if viewModel.isLoading {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredMaterials.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: searchText.isEmpty ? "folder" : "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text(searchText.isEmpty ? "教材がありません" : "該当する教材が見つかりません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredMaterials) { material in
                        MaterialRow(material: material) {
                            onSelect(material)
                            dismiss()
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("教材を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadMaterials()
        }
    }
}

// 教材行
struct MaterialRow: View {
    let material: Material
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // アイコン
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: material.sourceType == .imported ? "doc.fill" : "mic.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(material.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        // 長さ
                        Label(formatDuration(material.duration), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 練習回数
                        if material.practiceCount > 0 {
                            Label("\(material.practiceCount)回", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // 文字起こし状態
                        if material.transcription != nil {
                            Image(systemName: "text.bubble.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if material.isTranscribing {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                }
                
                Spacer()
                
                // 最終練習日
                if let lastPracticed = material.lastPracticedAt {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("最終練習")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(formatRelativeDate(lastPracticed))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// ViewModel
@MainActor
class MaterialPickerViewModel: ObservableObject {
    @Published var materials: [Material] = []
    @Published var isLoading = false
    
    private let materialService = MaterialService.shared
    
    func loadMaterials() {
        isLoading = true
        materialService.reloadMaterials()
        materials = materialService.materials
            .sorted { $0.lastPracticedAt ?? $0.createdAt > $1.lastPracticedAt ?? $1.createdAt }
        isLoading = false
    }
}

// Preview
struct MaterialPickerView_Previews: PreviewProvider {
    static var previews: some View {
        MaterialPickerView { _ in }
    }
}