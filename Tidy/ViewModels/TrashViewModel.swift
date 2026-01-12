import Foundation
import SwiftUI

@Observable
final class TrashViewModel {
    private let photoService = PhotoLibraryService.shared
    private let persistence = PersistenceService.shared

    var trashedPhotos: [PhotoItem] = []
    var selectedPhotos: Set<String> = []
    var isLoading = false
    var isDeleting = false
    var showStats = false
    var deletionStats: SessionStats?

    var selectedCount: Int {
        selectedPhotos.count
    }

    var hasSelection: Bool {
        !selectedPhotos.isEmpty
    }

    var trashedCount: Int {
        trashedPhotos.count
    }

    func loadTrashedPhotos() {
        trashedPhotos = photoService.photosMarkedForDeletion()
    }

    func toggleSelection(_ photoId: String) {
        if selectedPhotos.contains(photoId) {
            selectedPhotos.remove(photoId)
        } else {
            selectedPhotos.insert(photoId)
        }
    }

    func selectAll() {
        selectedPhotos = Set(trashedPhotos.map { $0.id })
    }

    func deselectAll() {
        selectedPhotos.removeAll()
    }

    func restoreSelected() {
        for id in selectedPhotos {
            persistence.unmarkForDeletion(id)
            persistence.unmarkAsReviewed(id)
        }
        selectedPhotos.removeAll()
        loadTrashedPhotos()
    }

    func restorePhoto(_ photoId: String) {
        persistence.unmarkForDeletion(photoId)
        persistence.unmarkAsReviewed(photoId)
        selectedPhotos.remove(photoId)
        loadTrashedPhotos()
    }

    func emptyTrash() async {
        guard !trashedPhotos.isEmpty else { return }

        isDeleting = true

        let idsToDelete = trashedPhotos.map { $0.id }

        do {
            let bytesFreed = try await photoService.deletePhotos(identifiers: idsToDelete)

            // Update stats
            var stats = persistence.sessionStats
            stats.bytesFreed = bytesFreed
            stats.photosDeleted = idsToDelete.count
            stats.endSession()
            persistence.sessionStats = stats

            await MainActor.run {
                self.deletionStats = stats
                self.isDeleting = false
                self.trashedPhotos = []
                self.selectedPhotos = []
                self.showStats = true
            }
        } catch {
            await MainActor.run {
                self.isDeleting = false
            }
        }
    }

    func deleteSelected() async {
        guard !selectedPhotos.isEmpty else { return }

        isDeleting = true

        let idsToDelete = Array(selectedPhotos)

        do {
            let bytesFreed = try await photoService.deletePhotos(identifiers: idsToDelete)

            var stats = persistence.sessionStats
            stats.bytesFreed += bytesFreed
            stats.photosDeleted += idsToDelete.count
            persistence.sessionStats = stats

            await MainActor.run {
                self.isDeleting = false
                self.selectedPhotos = []
                self.loadTrashedPhotos()
            }
        } catch {
            await MainActor.run {
                self.isDeleting = false
            }
        }
    }
}
