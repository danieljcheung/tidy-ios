import SwiftUI
import Photos

struct MaybePileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var maybePhotos: [PhotoItem] = []
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

                if maybePhotos.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        infoBanner

                        PhotoGridView(
                            photos: maybePhotos,
                            onTap: { photo in
                                selectedPhotoForDetail = photo
                            }
                        )
                    }
                }
            }
            .navigationTitle("Maybe Pile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TidyTheme.Colors.primary)
                }

                if !maybePhotos.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Review All") {
                            persistence.currentFilter = PhotoFilter.maybePile.rawValue
                            dismiss()
                        }
                        .foregroundStyle(TidyTheme.Colors.primary)
                    }
                }
            }
            .sheet(item: $selectedPhotoForDetail) { photo in
                PhotoDetailView(photo: photo)
            }
        }
        .onAppear {
            loadMaybePhotos()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(textColor.opacity(0.3))

            Text("No Maybe Photos")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(textColor)

            Text("Photos you swipe up on will appear here. Use this pile for photos you're unsure about.")
                .font(.system(size: 14))
                .foregroundStyle(textColor.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var infoBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb")
                .foregroundStyle(TidyTheme.Colors.primary)

            Text("Tap \"Review All\" to swipe through your maybes again.")
                .font(.system(size: 13))
                .foregroundStyle(textColor.opacity(0.7))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(TidyTheme.Colors.primary.opacity(0.1))
    }

    private func loadMaybePhotos() {
        maybePhotos = photoService.maybePilePhotos()
    }
}

#Preview {
    MaybePileView()
}
