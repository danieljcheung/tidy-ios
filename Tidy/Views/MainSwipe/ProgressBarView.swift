import SwiftUI

struct ProgressBarView: View {
    let current: Int
    let total: Int
    let progress: Double

    @Environment(\.colorScheme) private var colorScheme

    private var textColor: Color {
        TidyTheme.Colors.text(for: colorScheme).opacity(0.6)
    }

    private var barBackground: Color {
        colorScheme == .dark
            ? .white.opacity(0.1)
            : TidyTheme.Colors.charcoal.opacity(0.1)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Progress text
            Text("\(current) of \(total)")
                .font(TidyTheme.Typography.progress())
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(textColor)

            // Progress bar
            GeometryReader { geometry in
                let width = min(geometry.size.width, TidyTheme.Dimensions.progressBarMaxWidth)

                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: TidyTheme.Dimensions.progressBarHeight / 2)
                        .fill(barBackground)
                        .frame(width: width, height: TidyTheme.Dimensions.progressBarHeight)

                    // Fill
                    RoundedRectangle(cornerRadius: TidyTheme.Dimensions.progressBarHeight / 2)
                        .fill(TidyTheme.Colors.primary)
                        .frame(
                            width: width * progress,
                            height: TidyTheme.Dimensions.progressBarHeight
                        )
                        .animation(TidyTheme.Animation.progressBar, value: progress)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: TidyTheme.Dimensions.progressBarHeight)
            .frame(maxWidth: TidyTheme.Dimensions.progressBarMaxWidth)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        ProgressBarView(current: 124, total: 1832, progress: 0.15)
        ProgressBarView(current: 500, total: 1000, progress: 0.5)
        ProgressBarView(current: 900, total: 1000, progress: 0.9)
    }
    .padding()
    .background(TidyTheme.Colors.backgroundLight)
}
