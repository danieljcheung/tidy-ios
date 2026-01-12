import SwiftUI

struct UndoButtonView: View {
    let action: () -> Void
    let isEnabled: Bool

    @State private var isPressed = false
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            withAnimation(TidyTheme.Animation.buttonPress) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
                action()
            }
        }) {
            ZStack {
                // Outer circle - wax seal base
                Circle()
                    .fill(TidyTheme.Colors.waxSealRed)
                    .frame(width: TidyTheme.Dimensions.undoButtonSize,
                           height: TidyTheme.Dimensions.undoButtonSize)

                // Border
                Circle()
                    .strokeBorder(TidyTheme.Colors.waxSealBorder, lineWidth: 2)
                    .frame(width: TidyTheme.Dimensions.undoButtonSize,
                           height: TidyTheme.Dimensions.undoButtonSize)

                // Inner highlight ring
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear, .black.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .frame(width: TidyTheme.Dimensions.undoButtonSize - 4,
                           height: TidyTheme.Dimensions.undoButtonSize - 4)

                // Undo icon
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .rotationEffect(.degrees(isHovered ? 0 : TidyTheme.Dimensions.undoIconRotation))
                    .animation(.easeOut(duration: 0.2), value: isHovered)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .waxSealShadow()
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        UndoButtonView(action: {}, isEnabled: true)
        UndoButtonView(action: {}, isEnabled: false)
    }
    .padding()
    .background(TidyTheme.Colors.backgroundLight)
}
