import SwiftUI
import Photos

struct TrashReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var trashedPhotos: [PhotoItem] = []
    @State private var selectedIds: Set<String> = []
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showStats = false
    @State private var deletionStats: SessionStats?
    @State private var selectedPhotoForDetail: PhotoItem?

    private let photoService = PhotoLibraryService.shared
    private let persistence = PersistenceService.shared

    private var backgroundColor: Color {
        TidyTheme.Colors.background(for: colorScheme)
    }

    private var textColor: Color {
        TidyTheme.Colors.text(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()

                if trashedPhotos.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        infoBanner

                        PhotoGridView(
                            photos: trashedPhotos,
                            selectedIds: selectedIds,
                            onTap: { photo in
                                toggleSelection(photo.id)
                            },
                            onLongPress: { photo in
                                selectedPhotoForDetail = photo
                            }
                        )

                        bottomActionBar
                    }
                }

                if isDeleting {
                    deletingOverlay
                }
            }
            .navigationTitle("Review Trash")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TidyTheme.Colors.primary)
                }

                ToolbarItem(placement: .primaryAction) {
                    if !trashedPhotos.isEmpty {
                        Button(selectedIds.isEmpty ? "Select All" : "Deselect") {
                            if selectedIds.isEmpty {
                                selectedIds = Set(trashedPhotos.map { $0.id })
                            } else {
                                selectedIds.removeAll()
                            }
                        }
                        .foregroundStyle(TidyTheme.Colors.primary)
                    }
                }
            }
            .confirmationDialog(
                "Delete \(trashedPhotos.count) Photos?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    emptyTrash()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Photos will be moved to Recently Deleted and can be recovered for 30 days.")
            }
            .fullScreenCover(isPresented: $showStats) {
                if let stats = deletionStats {
                    StatsView(stats: stats) {
                        showStats = false
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedPhotoForDetail) { photo in
                PhotoDetailView(photo: photo)
            }
        }
        .onAppear {
            loadTrashedPhotos()
        }
    }

    // MARK: - Views

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "trash.slash")
                .font(.system(size: 48))
                .foregroundStyle(textColor.opacity(0.3))

            Text("No Photos to Delete")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(textColor)

            Text("Photos you swipe left on will appear here for review before deletion.")
                .font(.system(size: 14))
                .foregroundStyle(textColor.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var infoBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(TidyTheme.Colors.primary)

            Text("Tap to select. Long press to preview.")
                .font(.system(size: 13))
                .foregroundStyle(textColor.opacity(0.7))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(TidyTheme.Colors.primary.opacity(0.1))
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 16) {
                if !selectedIds.isEmpty {
                    Button {
                        restoreSelected()
                    } label: {
                        Label("Restore", systemImage: "arrow.uturn.backward")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(TidyTheme.Colors.primary)
                    }
                }

                Spacer()

                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                        Text(selectedIds.isEmpty ? "Empty Trash (\(trashedPhotos.count))" : "Delete (\(selectedIds.count))")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor)
        }
    }

    private var deletingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)

                Text("Deleting photos...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Actions

    private func loadTrashedPhotos() {
        trashedPhotos = photoService.photosMarkedForDeletion()
    }

    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    private func restoreSelected() {
        for id in selectedIds {
            persistence.unmarkForDeletion(id)
            persistence.unmarkAsReviewed(id)
        }
        selectedIds.removeAll()
        loadTrashedPhotos()
    }

    private func emptyTrash() {
        guard !trashedPhotos.isEmpty else { return }

        isDeleting = true

        let idsToDelete = selectedIds.isEmpty
            ? trashedPhotos.map { $0.id }
            : Array(selectedIds)

        let assetsToDelete = trashedPhotos
            .filter { idsToDelete.contains($0.id) }
            .map { $0.asset }

        // Calculate size
        var totalSize: Int64 = 0
        for asset in assetsToDelete {
            let resources = PHAssetResource.assetResources(for: asset)
            if let resource = resources.first,
               let size = resource.value(forKey: "fileSize") as? Int64 {
                totalSize += size
            }
        }

        // Perform deletion
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                self.isDeleting = false

                if success {
                    // Update stats
                    var stats = self.persistence.sessionStats
                    stats.bytesFreed = totalSize
                    stats.photosDeleted = idsToDelete.count
                    stats.endSession()
                    self.persistence.sessionStats = stats

                    // Clear from persistence
                    for id in idsToDelete {
                        self.persistence.unmarkForDeletion(id)
                        self.persistence.removeFromMaybePile(id)
                        self.persistence.unmarkAsReviewed(id)
                    }

                    self.deletionStats = stats
                    self.selectedIds.removeAll()
                    self.trashedPhotos.removeAll { idsToDelete.contains($0.id) }

                    if self.trashedPhotos.isEmpty {
                        self.showStats = true
                    }
                }
            }
        }
    }
}

#Preview {
    TrashReviewView()
}
