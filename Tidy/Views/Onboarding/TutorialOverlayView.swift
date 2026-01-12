import SwiftUI

// MARK: - Frame Preference Key

struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func captureFrame(id: String, coordinateSpace: CoordinateSpace = .global) -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: FramePreferenceKey.self,
                    value: [id: geo.frame(in: coordinateSpace)]
                )
            }
        )
    }
}

// MARK: - Tutorial Step

private struct TutorialStep {
    let text: String
    let frameKey: String?
    let isFinalStep: Bool

    init(text: String, frameKey: String? = nil, isFinalStep: Bool = false) {
        self.text = text
        self.frameKey = frameKey
        self.isFinalStep = isFinalStep
    }
}

// MARK: - Tutorial Overlay View

struct TutorialOverlayView: View {
    @Binding var isShowingTutorial: Bool
    let elementFrames: [String: CGRect]

    @State private var currentStep = 0
    @Environment(\.colorScheme) private var colorScheme

    private let steps: [TutorialStep] = [
        TutorialStep(text: "Swipe right to keep, left to delete, up for maybe", frameKey: "photoCard"),
        TutorialStep(text: "Made a mistake? Tap to undo your last swipe", frameKey: "undoButton"),
        TutorialStep(text: "Filter by screenshots, dates, or browse by year", frameKey: "filterButton"),
        TutorialStep(text: "Track your progress as you review", frameKey: "progressBar"),
        TutorialStep(text: "Review your deleted photos before they're permanently removed", frameKey: "trashButton"),
        TutorialStep(text: "You're ready to start tidying!", isFinalStep: true)
    ]

    private var currentStepData: TutorialStep {
        steps[currentStep]
    }

    private var currentHighlightFrame: CGRect? {
        guard let key = currentStepData.frameKey else { return nil }
        return elementFrames[key]
    }

    var body: some View {
        ZStack {
            SpotlightOverlay(
                highlightFrame: currentHighlightFrame,
                text: currentStepData.text,
                stepNumber: currentStep + 1,
                totalSteps: steps.count,
                isFinalStep: currentStepData.isFinalStep,
                onTap: advanceStep,
                onFinish: completeTutorial
            )
            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }

    private func advanceStep() {
        if currentStep < steps.count - 1 {
            currentStep += 1
        }
    }

    private func completeTutorial() {
        PersistenceService.shared.hasSeenTutorial = true
        withAnimation(.easeOut(duration: 0.3)) {
            isShowingTutorial = false
        }
    }
}

// MARK: - Spotlight Overlay

private struct SpotlightOverlay: View {
    let highlightFrame: CGRect?
    let text: String
    let stepNumber: Int
    let totalSteps: Int
    let isFinalStep: Bool
    let onTap: () -> Void
    let onFinish: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let highlightPadding: CGFloat = 12
    private let highlightCornerRadius: CGFloat = 12

    private var tooltipBackground: Color {
        colorScheme == .dark
            ? TidyTheme.Colors.cardBackgroundDark
            : TidyTheme.Colors.backgroundLight
    }

    private var tooltipTextColor: Color {
        TidyTheme.Colors.text(for: colorScheme)
    }

    var body: some View {
        ZStack {
            // Dark overlay with cutout
            overlayWithCutout

            // Tooltip
            tooltipView

            // Tap hint or finish button
            if isFinalStep {
                finishButton
            } else {
                tapHint
            }

            // Step indicator
            stepIndicator
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isFinalStep {
                onTap()
            }
        }
    }

    // MARK: - Overlay with Cutout

    @ViewBuilder
    private var overlayWithCutout: some View {
        Canvas { context, size in
            // Fill entire screen with dark color
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color.black.opacity(0.8))
            )

            // Cut out the highlight area
            if let frame = highlightFrame {
                let cutoutRect = frame.insetBy(dx: -highlightPadding, dy: -highlightPadding)
                context.blendMode = .destinationOut
                context.fill(
                    Path(roundedRect: cutoutRect, cornerRadius: highlightCornerRadius),
                    with: .color(.white)
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Tooltip

    private var tooltipView: some View {
        VStack(spacing: 8) {
            Text(text)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(tooltipTextColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tooltipBackground)
                        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 6)
                )
        }
        .padding(.horizontal, 32)
        .position(tooltipPosition)
    }

    private var tooltipPosition: CGPoint {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        guard let frame = highlightFrame else {
            // Center of screen for final step
            return CGPoint(x: screenWidth / 2, y: screenHeight * 0.4)
        }

        let tooltipHeight: CGFloat = 120

        // Position tooltip above or below the highlight depending on space
        if frame.midY > screenHeight / 2 {
            // Highlight is in bottom half - show tooltip above
            return CGPoint(x: screenWidth / 2, y: frame.minY - tooltipHeight)
        } else {
            // Highlight is in top half - show tooltip below
            return CGPoint(x: screenWidth / 2, y: frame.maxY + tooltipHeight)
        }
    }

    // MARK: - Tap Hint

    private var tapHint: some View {
        VStack {
            Spacer()
            HStack(spacing: 6) {
                Text("Tap to continue")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "hand.tap")
                    .font(.system(size: 14))
            }
            .foregroundColor(TidyTheme.Colors.primary)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Finish Button

    private var finishButton: some View {
        VStack {
            Spacer()
            Button(action: onFinish) {
                Text("Let's go")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 200)
                    .padding(.vertical, 14)
                    .background(TidyTheme.Colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .padding(.bottom, 60)
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        VStack {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index == stepNumber - 1 ? TidyTheme.Colors.primary : Color.white.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 60)
            Spacer()
        }
    }
}

#Preview {
    ZStack {
        TidyTheme.Colors.backgroundLight
            .ignoresSafeArea()

        TutorialOverlayView(
            isShowingTutorial: .constant(true),
            elementFrames: [
                "photoCard": CGRect(x: 50, y: 200, width: 300, height: 400)
            ]
        )
    }
}
