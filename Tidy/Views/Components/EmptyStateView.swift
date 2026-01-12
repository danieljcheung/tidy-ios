import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    private var textColor: Color {
        TidyTheme.Colors.text(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundStyle(TidyTheme.Colors.primary)

            // Title
            Text(title)
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundStyle(textColor)

            // Message
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(textColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(TidyTheme.Colors.primary)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        title: "All Done!",
        message: "You've reviewed all your photos. Your camera roll is now tidy!",
        actionTitle: "Review Trash",
        action: {}
    )
    .background(TidyTheme.Colors.backgroundLight)
}
