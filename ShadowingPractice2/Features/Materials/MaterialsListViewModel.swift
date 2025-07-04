import Foundation
import Combine

@MainActor
class MaterialsListViewModel: ObservableObject {
    @Published var materials: [Material] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let materialService = MaterialService.shared
    private let logger = Logger.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMaterials()
        observeMaterialChanges()
    }
    
    func loadMaterials() {
        isLoading = true
        materialService.reloadMaterials()
        materials = materialService.materials
        isLoading = false
    }
    
    func importAudioFile(from url: URL) async {
        do {
            isLoading = true
            let material = try await materialService.importAudioFile(from: url)
            materials.append(material)
            isLoading = false
            
            // バックグラウンドで文字起こし
            Task {
                try? await materialService.transcribeMaterial(material)
                if let index = materials.firstIndex(where: { $0.id == material.id }) {
                    if let updatedMaterial = materialService.getMaterial(by: material.id) {
                        materials[index] = updatedMaterial
                    }
                }
            }
        } catch {
            logger.error("Failed to import audio file: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func importRecordedFile(from url: URL, title: String) async {
        do {
            isLoading = true
            let material = try await materialService.importRecordedFile(from: url, title: title)
            materials.append(material)
            isLoading = false
            
            // バックグラウンドで文字起こし
            Task {
                try? await materialService.transcribeMaterial(material)
                if let index = materials.firstIndex(where: { $0.id == material.id }) {
                    if let updatedMaterial = materialService.getMaterial(by: material.id) {
                        materials[index] = updatedMaterial
                    }
                }
            }
        } catch {
            logger.error("Failed to import recorded file: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func deleteMaterial(_ material: Material) async {
        do {
            try await materialService.deleteMaterialAsync(material)
            materials.removeAll { $0.id == material.id }
        } catch {
            logger.error("Failed to delete material: \(error)")
            errorMessage = "教材の削除に失敗しました"
        }
    }
    
    private func observeMaterialChanges() {
        // 教材の変更を監視（将来的にCombineやNotificationCenterで実装）
    }
}