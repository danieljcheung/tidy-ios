import SwiftUI
import Photos

struct PhotoGridView: View {
    let photos: [PhotoItem]
    let selectedIds: Set<String>
    let onTap: (PhotoItem) -> Void
    let onLongPress: ((PhotoItem) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    init(
        photos: [PhotoItem],
        selectedIds: Set<String> = [],
        onTap: @escaping (PhotoItem) -> Void,
        onLongPress: ((PhotoItem) -> Void)? = nil
    ) {
        self.photos = photos
        self.selectedIds = selectedIds
        self.onTap = onTap
        self.onLongPress = onLongPress
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(photos) { photo in
                    PhotoGridCell(
                        photo: photo,
                        isSelected: selectedIds.contains(photo.id),
                        onTap: { onTap(photo) },
                        onLongPress: { onLongPress?(photo) }
                    )
                }
            }
            .padding(2)
        }
    }
}

// MARK: - Grid Cell

private struct PhotoGridCell: View {
    let photo: PhotoItem
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Thumbnail
                if let image = thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: geometry.size.width, height: geometry.size.width)
                }

                // Video indicator
                if photo.isVideo {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                Text(photo.durationFormatted)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(4)
                        }
                    }
                }

                // Selection overlay
                if isSelected {
                    Rectangle()
                        .fill(TidyTheme.Colors.primary.opacity(0.3))

                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(TidyTheme.Colors.primary)
                                .background(Circle().fill(.white))
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.width)
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        let image = await PhotoCacheService.shared.thumbnail(for: photo.asset)
        await MainActor.run {
            self.thumbnail = image
        }
    }
}

#Preview {
    PhotoGridView(
        photos: [],
        selectedIds: [],
        onTap: { _ in }
    )
}
