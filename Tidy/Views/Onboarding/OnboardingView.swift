import SwiftUI
import Photos

struct OnboardingView: View {
    let onComplete: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isRequestingPermission = false
    @State private var permissionDenied = false

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

                // App icon / title area
                VStack(spacing: 16) {
                    // Decorative element
                    Image(systemName: "photo.stack")
                        .font(.system(size: 60))
                        .foregroundStyle(TidyTheme.Colors.primary)

                    Text("Tidy")
                        .font(TidyTheme.Typography.titleFallback())
                        .foregroundStyle(textColor)

                    Text("Camera Roll Cleaner")
                        .font(.system(size: 14, weight: .medium))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(textColor.opacity(0.6))
                }

                Spacer()

                // Privacy commitment
                VStack(spacing: 24) {
                    Text("Your Privacy, Protected")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(textColor)

                    VStack(alignment: .leading, spacing: 16) {
                        PrivacyBullet(icon: "wifi.slash", text: "100% offline - no internet required")
                        PrivacyBullet(icon: "eye.slash", text: "No analytics or tracking")
                        PrivacyBullet(icon: "icloud.slash", text: "Photos never leave your device")
                        PrivacyBullet(icon: "clock.arrow.circlepath", text: "Deleted photos go to Recently Deleted")
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()

                // Permission request
                VStack(spacing: 16) {
                    if permissionDenied {
                        Text("Photo access was denied. Please enable it in Settings to use Tidy.")
                            .font(.system(size: 14))
                            .foregroundStyle(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Open Settings")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(TidyTheme.Colors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 32)
                    } else {
                        Text("Tidy needs access to your photo library to help you clean up.")
                            .font(.system(size: 14))
                            .foregroundStyle(textColor.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button {
                            requestPermission()
                        } label: {
                            HStack(spacing: 8) {
                                if isRequestingPermission {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Allow Photo Access")
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(TidyTheme.Colors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isRequestingPermission)
                        .padding(.horizontal, 32)
                    }
                }

                Spacer()
                    .frame(height: 40)
            }
        }
    }

    private func requestPermission() {
        isRequestingPermission = true

        Task {
            let status = await PhotoLibraryService.shared.requestAuthorization()

            await MainActor.run {
                isRequestingPermission = false

                switch status {
                case .authorized, .limited:
                    PersistenceService.shared.hasCompletedOnboarding = true
                    onComplete()
                case .denied, .restricted:
                    permissionDenied = true
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}

// MARK: - Privacy Bullet

private struct PrivacyBullet: View {
    let icon: String
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(TidyTheme.Colors.primary)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(TidyTheme.Colors.text(for: colorScheme).opacity(0.8))

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
