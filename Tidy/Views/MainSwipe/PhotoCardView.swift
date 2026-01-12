import SwiftUI
import Photos

struct PhotoCardView: View {
    let photo: PhotoItem
    let offset: CGSize
    let rotation: Double
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var image: UIImage?
    @State private var isLoading = true

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

                // Photo content
                VStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: width - TidyTheme.Dimensions.cardPadding * 2,
                                height: maxHeight - TidyTheme.Dimensions.cardPadding * 2
                            )
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius - 4))
                            .overlay(
                                // Inner matte border
                                RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius - 4)
                                    .strokeBorder(.black.opacity(0.1), lineWidth: 0.5)
                            )
                    } else {
                        // Loading placeholder
                        RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius - 4)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                            .frame(
                                width: width - TidyTheme.Dimensions.cardPadding * 2,
                                height: maxHeight - TidyTheme.Dimensions.cardPadding * 2
                            )
                            .overlay {
                                if isLoading {
                                    ProgressView()
                                        .tint(TidyTheme.Colors.primary)
                                }
                            }
                    }
                }
                .padding(TidyTheme.Dimensions.cardPadding)

                // Video indicator
                if photo.isVideo {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12))
                                Text(photo.durationFormatted)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(TidyTheme.Dimensions.cardPadding + 8)
                        }
                    }
                }

                // Live Photo indicator
                if photo.isLivePhoto {
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
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        isLoading = true
        let loadedImage = await PhotoCacheService.shared.cardImage(for: photo.asset)
        await MainActor.run {
            self.image = loadedImage
            self.isLoading = false
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
