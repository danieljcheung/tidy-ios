import SwiftUI

struct TrashReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = TrashViewModel()
    @State private var showDeleteConfirmation = false
    @State private var selectedPhotoForDetail: PhotoItem?

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

                if viewModel.trashedPhotos.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        // Info banner
                        infoBanner

                        // Photo grid
                        PhotoGridView(
                            photos: viewModel.trashedPhotos,
                            selectedIds: viewModel.selectedPhotos,
                            onTap: { photo in
                                viewModel.toggleSelection(photo.id)
                            },
                            onLongPress: { photo in
                                selectedPhotoForDetail = photo
                            }
                        )

                        // Bottom action bar
                        bottomActionBar
                    }
                }

                // Loading overlay
                if viewModel.isDeleting {
                    deletingOverlay
                }
            }
            .navigationTitle("Review Trash")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(TidyTheme.Colors.primary)
                }

                ToolbarItem(placement: .primaryAction) {
                    if !viewModel.trashedPhotos.isEmpty {
                        Button(viewModel.hasSelection ? "Deselect All" : "Select All") {
                            if viewModel.hasSelection {
                                viewModel.deselectAll()
                            } else {
                                viewModel.selectAll()
                            }
                        }
                        .foregroundStyle(TidyTheme.Colors.primary)
                    }
                }
            }
            .confirmationDialog(
                "Delete \(viewModel.trashedCount) Photos?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    Task {
                        await viewModel.emptyTrash()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("These photos will be moved to your Recently Deleted album where you can recover them for 30 days.")
            }
            .fullScreenCover(isPresented: $viewModel.showStats) {
                if let stats = viewModel.deletionStats {
                    StatsView(stats: stats) {
                        viewModel.showStats = false
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedPhotoForDetail) { photo in
                PhotoDetailView(photo: photo)
            }
        }
        .onAppear {
            viewModel.loadTrashedPhotos()
        }
    }

    // MARK: - Views

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "trash")
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

            Text("Tap to select photos. Long press to preview.")
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
                // Restore button
                if viewModel.hasSelection {
                    Button {
                        viewModel.restoreSelected()
                    } label: {
                        Label("Restore", systemImage: "arrow.uturn.backward")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(TidyTheme.Colors.primary)
                    }
                }

                Spacer()

                // Delete button
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                        Text(viewModel.hasSelection ? "Delete Selected (\(viewModel.selectedCount))" : "Empty Trash (\(viewModel.trashedCount))")
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
}

#Preview {
    TrashReviewView()
}
