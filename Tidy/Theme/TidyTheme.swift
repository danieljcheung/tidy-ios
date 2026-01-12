import SwiftUI

enum TidyTheme {
    // MARK: - Colors

    enum Colors {
        // Light Mode
        static let backgroundLight = Color(hex: "#F5F0E6")
        static let charcoal = Color(hex: "#36322b")
        static let primary = Color(hex: "#b6890c")
        static let primaryDark = Color(hex: "#8a6605")

        // Dark Mode
        static let backgroundDark = Color(hex: "#221d10")
        static let darkModeText = Color(hex: "#e8e1cf")
        static let cardBackgroundDark = Color(hex: "#2a2415")

        // Wax Seal
        static let waxSealRed = Color(hex: "#8B0000")
        static let waxSealBorder = Color(hex: "#6d0000")

        // Semantic colors that adapt to color scheme
        static func background(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? backgroundDark : backgroundLight
        }

        static func text(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? darkModeText : charcoal
        }

        static func cardBackground(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? cardBackgroundDark : .white
        }
    }

    // MARK: - Typography

    enum Typography {
        static func title() -> Font {
            .custom("Newsreader", size: 30)
                .italic()
        }

        static func titleFallback() -> Font {
            .system(size: 30, weight: .medium, design: .serif)
                .italic()
        }

        static func progress() -> Font {
            .system(size: 11, weight: .semibold, design: .default)
        }

        static func actionLabel() -> Font {
            .custom("Newsreader", size: 14)
                .italic()
        }

        static func actionLabelFallback() -> Font {
            .system(size: 14, weight: .regular, design: .serif)
                .italic()
        }

        static func filterOption() -> Font {
            .system(size: 16, weight: .regular, design: .serif)
        }

        static func statsLarge() -> Font {
            .system(size: 48, weight: .bold, design: .serif)
        }

        static func statsLabel() -> Font {
            .system(size: 14, weight: .medium, design: .default)
        }
    }

    // MARK: - Dimensions

    enum Dimensions {
        // Photo Card
        static let cardAspectRatio: CGFloat = 3.0 / 4.0
        static let cardMaxHeightRatio: CGFloat = 0.65
        static let cardPadding: CGFloat = 12
        static let cardCornerRadius: CGFloat = 8

        // Stacked Cards
        static let backCardScale: CGFloat = 0.95
        static let backCardOffset: CGFloat = 12
        static let backCardOpacity: CGFloat = 0.6
        static let middleCardScale: CGFloat = 0.975
        static let middleCardOffset: CGFloat = 6
        static let middleCardOpacity: CGFloat = 0.8

        // Undo Button
        static let undoButtonSize: CGFloat = 56
        static let undoIconRotation: Double = -12

        // Indicators
        static let indicatorCircleSize: CGFloat = 48

        // Progress Bar
        static let progressBarMaxWidth: CGFloat = 200
        static let progressBarHeight: CGFloat = 4

        // Swipe Thresholds
        static let swipeThreshold: CGFloat = 100
        static let verticalSwipeThreshold: CGFloat = 80
    }

    // MARK: - Shadows

    enum Shadows {
        static func archival(_ content: some View) -> some View {
            content
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 10)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 4)
        }

        static func waxSeal(_ content: some View) -> some View {
            content
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
        }
    }

    // MARK: - Animation

    enum Animation {
        static let cardHover = SwiftUI.Animation.easeOut(duration: 0.3)
        static let cardSwipe = SwiftUI.Animation.easeOut(duration: 0.3)
        static let buttonPress = SwiftUI.Animation.easeOut(duration: 0.15)
        static let progressBar = SwiftUI.Animation.easeOut(duration: 0.5)
    }
}

// MARK: - View Modifiers

struct ArchivalShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        TidyTheme.Shadows.archival(content)
    }
}

struct WaxSealShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        TidyTheme.Shadows.waxSeal(content)
    }
}

extension View {
    func archivalShadow() -> some View {
        modifier(ArchivalShadowModifier())
    }

    func waxSealShadow() -> some View {
        modifier(WaxSealShadowModifier())
    }
}
