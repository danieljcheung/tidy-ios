import SwiftUI
import Photos
import AVKit

struct PhotoCardView: View {
    let photo: PhotoItem
    let offset: CGSize
    let rotation: Double
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var player: AVPlayer?

    private var cardBackground: Color {
        TidyTheme.Colors.cardBackground(for: colorScheme)
    }

    private var borderColor: Color {
        TidyTheme.Colors.primary.opacity(0.2)
    }

    var body: some View {
        GeometryReader { geometry in
            let maxHeight = geometry.size.height * TidyTheme.Dimensions.cardMaxHeightRatio
            let width = maxHeight * TidyTheme.Dimensions.cardAspectRatio

            ZStack {
                // Card background with padding (frame effect)
                RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )

                // Content: Video or Photo
                VStack {
                    if photo.isVideo {
                        videoContent(width: width, height: maxHeight)
                    } else {
                        photoContent(width: width, height: maxHeight)
                    }
                }
                .padding(TidyTheme.Dimensions.cardPadding)

                // Live Photo indicator
                if photo.isLivePhoto && !photo.isVideo {
                    VStack {
                        HStack {
                            Image(systemName: "livephoto")
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(.black.opacity(0.6))
                                .clipShape(Circle())
                                .padding(TidyTheme.Dimensions.cardPadding + 8)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: width, height: maxHeight)
            .archivalShadow()
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .onTapGesture {
                onTap()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            if photo.isVideo {
                loadVideo()
            } else {
                loadImage()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    // MARK: - Photo Content

    @ViewBuilder
    private func photoContent(width: CGFloat, height: CGFloat) -> some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(
                    width: width - TidyTheme.Dimensions.cardPadding * 2,
                    height: height - TidyTheme.Dimensions.cardPadding * 2
                )
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius - 4))
                .overlay(
                    RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius - 4)
                        .strokeBorder(.black.opacity(0.1), lineWidth: 0.5)
                )
        } else {
            loadingPlaceholder(width: width, height: height)
        }
    }

    // MARK: - Video Content

    @ViewBuilder
    private func videoContent(width: CGFloat, height: CGFloat) -> some View {
        if let player = player {
            VideoPlayer(player: player)
                .frame(
                    width: width - TidyTheme.Dimensions.cardPadding * 2,
                    height: height - TidyTheme.Dimensions.cardPadding * 2
                )
                .clipShape(RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius - 4))
                .overlay(
                    RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius - 4)
                        .strokeBorder(.black.opacity(0.1), lineWidth: 0.5)
                )
                .onAppear {
                    player.play()
                }
        } else {
            loadingPlaceholder(width: width, height: height)
        }
    }

    // MARK: - Loading Placeholder

    @ViewBuilder
    private func loadingPlaceholder(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius - 4)
            .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
            .frame(
                width: width - TidyTheme.Dimensions.cardPadding * 2,
                height: height - TidyTheme.Dimensions.cardPadding * 2
            )
            .overlay {
                if isLoading {
                    ProgressView()
                        .tint(TidyTheme.Colors.primary)
                }
            }
    }

    // MARK: - Loading

    private func loadImage() {
        isLoading = true

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = false

        let targetSize = CGSize(width: 600 * UIScreen.main.scale, height: 800 * UIScreen.main.scale)

        PHImageManager.default().requestImage(
            for: photo.asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { result, info in
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            if !isDegraded, let result = result {
                DispatchQueue.main.async {
                    self.image = result
                    self.isLoading = false
                }
            }
        }
    }

    private func loadVideo() {
        isLoading = true

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .automatic

        PHImageManager.default().requestPlayerItem(forVideo: photo.asset, options: options) { playerItem, info in
            if let playerItem = playerItem {
                DispatchQueue.main.async {
                    self.player = AVPlayer(playerItem: playerItem)
                    self.player?.isMuted = true  // Start muted
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    PhotoCardView(
        photo: PhotoItem(asset: PHAsset()),
        offset: .zero,
        rotation: 0,
        onTap: {}
    )
    .frame(height: 600)
    .background(TidyTheme.Colors.backgroundLight)
}
