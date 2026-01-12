import SwiftUI

struct StatsView: View {
    let stats: SessionStats
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var animateStats = false

    private var backgroundColor: Color {
        TidyTheme.Colors.background(for: colorScheme)
    }

    private var textColor: Color {
        TidyTheme.Colors.text(for: colorScheme)
    }

    var body: some View {
        ZStack {
            // Background
            backgroundColor.ignoresSafeArea()

            // Vignette
            RadialGradient(
                colors: [.clear, TidyTheme.Colors.charcoal.opacity(0.08)],
                center: .center,
                startRadius: 200,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Celebration icon
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(TidyTheme.Colors.primary)
                    .scaleEffect(animateStats ? 1.0 : 0.5)
                    .opacity(animateStats ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: animateStats)

                // Title
                Text("Tidy Complete!")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(textColor)
                    .opacity(animateStats ? 1.0 : 0)
                    .offset(y: animateStats ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animateStats)

                Spacer()

                // Stats cards
                VStack(spacing: 24) {
                    // Space freed
                    StatCard(
                        value: stats.gbFreedFormatted,
                        label: "Space Freed",
                        icon: "externaldrive",
                        delay: 0.4,
                        animate: animateStats
                    )

                    HStack(spacing: 16) {
                        // Photos removed
                        StatCard(
                            value: "\(stats.photosDeleted)",
                            label: "Photos Removed",
                            icon: "trash",
                            delay: 0.5,
                            animate: animateStats,
                            isCompact: true
                        )

                        // Photos reviewed
                        StatCard(
                            value: "\(stats.photosReviewed)",
                            label: "Photos Reviewed",
                            icon: "eye",
                            delay: 0.6,
                            animate: animateStats,
                            isCompact: true
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Recovery notice
                Text("Deleted photos are in your Recently Deleted album for 30 days.")
                    .font(.system(size: 13))
                    .foregroundStyle(textColor.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animateStats ? 1.0 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.7), value: animateStats)

                // Done button
                Button(action: onDismiss) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(TidyTheme.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(animateStats ? 1.0 : 0)
                .offset(y: animateStats ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.8), value: animateStats)
            }
        }
        .onAppear {
            animateStats = true
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let delay: Double
    let animate: Bool
    var isCompact: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white
    }

    private var textColor: Color {
        TidyTheme.Colors.text(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: isCompact ? 8 : 12) {
            Image(systemName: icon)
                .font(.system(size: isCompact ? 20 : 24))
                .foregroundStyle(TidyTheme.Colors.primary)

            Text(value)
                .font(.system(size: isCompact ? 28 : 40, weight: .bold, design: .serif))
                .foregroundStyle(textColor)

            Text(label)
                .font(.system(size: isCompact ? 12 : 13, weight: .medium))
                .foregroundStyle(textColor.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isCompact ? 20 : 28)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .scaleEffect(animate ? 1.0 : 0.8)
        .opacity(animate ? 1.0 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animate)
    }
}

#Preview {
    StatsView(
        stats: {
            var s = SessionStats()
            s.photosReviewed = 342
            s.photosDeleted = 156
            s.bytesFreed = 2_500_000_000
            return s
        }(),
        onDismiss: {}
    )
}
