import SwiftUI

struct SwipeIndicatorsView: View {
    let swipeDirection: SwipeDecision

    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        TidyTheme.Colors.background(for: colorScheme).opacity(0.8)
    }

    var body: some View {
        ZStack {
            // Left indicator (Delete)
            HStack {
                DeleteIndicator(isActive: swipeDirection == .delete, colorScheme: colorScheme)
                    .opacity(0.4)
                Spacer()
            }

            // Right indicator (Keep)
            HStack {
                Spacer()
                KeepIndicator(isActive: swipeDirection == .keep)
                    .opacity(0.4)
            }

            // Top indicator (Maybe)
            VStack {
                MaybeIndicator(isActive: swipeDirection == .maybe)
                    .opacity(0.6)
                Spacer()
            }
        }
    }
}

// MARK: - Delete Indicator

private struct DeleteIndicator: View {
    let isActive: Bool
    let colorScheme: ColorScheme

    private var iconColor: Color {
        TidyTheme.Colors.text(for: colorScheme).opacity(0.7)
    }

    private var borderColor: Color {
        TidyTheme.Colors.text(for: colorScheme).opacity(0.2)
    }

    private var bgColor: Color {
        TidyTheme.Colors.background(for: colorScheme).opacity(0.8)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(bgColor)
                    .frame(width: TidyTheme.Dimensions.indicatorCircleSize,
                           height: TidyTheme.Dimensions.indicatorCircleSize)
                    .blur(radius: 0.5)

                Circle()
                    .strokeBorder(borderColor, lineWidth: 1)
                    .frame(width: TidyTheme.Dimensions.indicatorCircleSize,
                           height: TidyTheme.Dimensions.indicatorCircleSize)

                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            Text("Delete")
                .font(TidyTheme.Typography.actionLabelFallback())
                .foregroundStyle(TidyTheme.Colors.text(for: colorScheme).opacity(0.6))
                .rotationEffect(.degrees(-90))
        }
        .scaleEffect(isActive ? 1.1 : 1.0)
        .opacity(isActive ? 1.0 : 0.4)
        .animation(.easeOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Keep Indicator

private struct KeepIndicator: View {
    let isActive: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(TidyTheme.Colors.backgroundLight.opacity(0.8))
                    .frame(width: TidyTheme.Dimensions.indicatorCircleSize,
                           height: TidyTheme.Dimensions.indicatorCircleSize)
                    .blur(radius: 0.5)

                Circle()
                    .strokeBorder(TidyTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                    .frame(width: TidyTheme.Dimensions.indicatorCircleSize,
                           height: TidyTheme.Dimensions.indicatorCircleSize)

                Image(systemName: "heart.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(TidyTheme.Colors.primary)
            }

            Text("Keep")
                .font(TidyTheme.Typography.actionLabelFallback())
                .foregroundStyle(TidyTheme.Colors.primary)
                .rotationEffect(.degrees(90))
        }
        .scaleEffect(isActive ? 1.1 : 1.0)
        .opacity(isActive ? 1.0 : 0.4)
        .animation(.easeOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Maybe Indicator

private struct MaybeIndicator: View {
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "questionmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(TidyTheme.Colors.primary.opacity(0.7))

            Text("MAYBE")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundStyle(TidyTheme.Colors.primary.opacity(0.8))
        }
        .scaleEffect(isActive ? 1.1 : 1.0)
        .opacity(isActive ? 1.0 : 0.6)
        .animation(.easeOut(duration: 0.2), value: isActive)
    }
}

#Preview {
    ZStack {
        TidyTheme.Colors.backgroundLight
            .ignoresSafeArea()

        SwipeIndicatorsView(swipeDirection: .undecided)
            .padding(40)
    }
}
