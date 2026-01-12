import SwiftUI

struct CardStackView: View {
    let currentPhoto: PhotoItem?
    let nextPhoto: PhotoItem?
    let thirdPhoto: PhotoItem?
    let offset: CGSize
    let rotation: Double
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        TidyTheme.Colors.cardBackground(for: colorScheme)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? .white.opacity(0.05)
            : TidyTheme.Colors.charcoal.opacity(0.05)
    }

    var body: some View {
        GeometryReader { geometry in
            let maxHeight = geometry.size.height * TidyTheme.Dimensions.cardMaxHeightRatio
            let width = maxHeight * TidyTheme.Dimensions.cardAspectRatio

            ZStack {
                // Third card (back) - placeholder only
                if thirdPhoto != nil {
                    RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius)
                        .fill(cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius)
                                .strokeBorder(borderColor, lineWidth: 1)
                        )
                        .frame(width: width, height: maxHeight)
                        .scaleEffect(TidyTheme.Dimensions.backCardScale)
                        .offset(y: TidyTheme.Dimensions.backCardOffset)
                        .opacity(TidyTheme.Dimensions.backCardOpacity)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }

                // Second card (middle) - placeholder only
                if nextPhoto != nil {
                    RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius)
                        .fill(cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: TidyTheme.Dimensions.cardCornerRadius)
                                .strokeBorder(borderColor, lineWidth: 1)
                        )
                        .frame(width: width, height: maxHeight)
                        .scaleEffect(TidyTheme.Dimensions.middleCardScale)
                        .offset(y: TidyTheme.Dimensions.middleCardOffset)
                        .opacity(TidyTheme.Dimensions.middleCardOpacity)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }

                // Current card (front) - actual photo
                if let photo = currentPhoto {
                    PhotoCardView(
                        photo: photo,
                        offset: offset,
                        rotation: rotation,
                        onTap: onTap
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    CardStackView(
        currentPhoto: nil,
        nextPhoto: nil,
        thirdPhoto: nil,
        offset: .zero,
        rotation: 0,
        onTap: {}
    )
    .frame(height: 500)
    .background(TidyTheme.Colors.backgroundLight)
}
