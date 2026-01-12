import SwiftUI
import Photos
import AVKit

struct PhotoDetailView: View {
    let photo: PhotoItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // Video playback
    @State private var player: AVPlayer?
    @State private var isPlayingVideo = false

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            if photo.isVideo {
                videoPlayerView
            } else {
                photoView
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(16)
                }
                Spacer()
            }

            // Photo info
            VStack {
                Spacer()
                photoInfoView
            }
        }
        .task {
            if photo.isVideo {
                await loadVideo()
            } else {
                await loadFullResolution()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    // MARK: - Photo View

    private var photoView: some View {
        GeometryReader { geometry in
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = min(max(scale * delta, 1), 5)
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                if scale < 1.2 {
                                    withAnimation(.spring()) {
                                        scale = 1.0
                                        offset = .zero
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            if scale > 1 {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.5
                            }
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Video View

    private var videoPlayerView: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                    Text("Loading video...")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Photo Info

    private var photoInfoView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // Date
                if let date = photo.creationDate {
                    Label {
                        Text(date, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
                }

                // Size
                Label {
                    Text(photo.fileSizeFormatted)
                } icon: {
                    Image(systemName: "doc")
                }
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.8))

                // Duration (for videos)
                if photo.isVideo {
                    Label {
                        Text(photo.durationFormatted)
                    } icon: {
                        Image(systemName: "play.fill")
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Loading

    private func loadFullResolution() async {
        isLoading = true
        let loadedImage = await PhotoCacheService.shared.fullResolutionImage(for: photo.asset)
        await MainActor.run {
            self.image = loadedImage
            self.isLoading = false
        }
    }

    private func loadVideo() async {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .highQualityFormat

        PHImageManager.default().requestAVAsset(forVideo: photo.asset, options: options) { asset, _, _ in
            guard let urlAsset = asset as? AVURLAsset else { return }

            DispatchQueue.main.async {
                self.player = AVPlayer(url: urlAsset.url)
            }
        }
    }
}

#Preview {
    PhotoDetailView(photo: PhotoItem(asset: PHAsset()))
}
