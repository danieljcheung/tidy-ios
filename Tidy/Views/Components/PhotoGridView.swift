import SwiftUI
import Photos

struct PhotoGridView: View {
    let photos: [PhotoItem]
    let selectedIds: Set<String>
    let onTap: (PhotoItem) -> Void
    let onLongPress: ((PhotoItem) -> Void)?

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
                    SimpleThumbnailView(
                        asset: photo.asset,
                        isVideo: photo.isVideo,
                        duration: photo.durationFormatted,
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

// Simple thumbnail that loads without async/await continuation issues
struct SimpleThumbnailView: View {
    let asset: PHAsset
    let isVideo: Bool
    let duration: String
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Thumbnail
                if let image = image {
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
                if isVideo {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                Text(duration)
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
        .onTapGesture { onTap() }
        .onLongPressGesture { onLongPress() }
        .onAppear { loadThumbnail() }
    }

    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = false
        options.resizeMode = .fast

        let size = CGSize(width: 200, height: 200)

        // Use direct callback - no continuation issues
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { result, info in
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            // Accept any image, prefer non-degraded
            if self.image == nil || !isDegraded {
                DispatchQueue.main.async {
                    self.image = result
                }
            }
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
