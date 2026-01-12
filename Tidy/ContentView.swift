import SwiftUI
import Photos

struct ContentView: View {
    @State private var hasCompletedOnboarding = PersistenceService.shared.hasCompletedOnboarding
    @State private var isAuthorized = PhotoLibraryService.shared.isAuthorized
    @State private var viewModel = MainSwipeViewModel()

    var body: some View {
        Group {
            if !hasCompletedOnboarding || !isAuthorized {
                OnboardingView {
                    hasCompletedOnboarding = true
                    isAuthorized = PhotoLibraryService.shared.isAuthorized
                }
            } else {
                mainAppView
            }
        }
        .onAppear {
            checkAuthorizationStatus()
        }
    }

    private var mainAppView: some View {
        NavigationStack {
            MainSwipeView(viewModel: viewModel)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        trashButton
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        maybeButton
                    }
                }
        }
        .sheet(isPresented: $viewModel.showTrashReview) {
            TrashReviewView()
        }
    }

    private var trashButton: some View {
        Button {
            viewModel.showTrashReview = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "trash")
                if viewModel.markedForDeletionCount > 0 {
                    Text("\(viewModel.markedForDeletionCount)")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundStyle(viewModel.markedForDeletionCount > 0 ? .red : .secondary)
        }
    }

    private var maybeButton: some View {
        NavigationLink {
            MaybePileView()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "questionmark.circle")
                if viewModel.maybePileCount > 0 {
                    Text("\(viewModel.maybePileCount)")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundStyle(viewModel.maybePileCount > 0 ? TidyTheme.Colors.primary : .secondary)
        }
    }

    private func checkAuthorizationStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        isAuthorized = status == .authorized || status == .limited

        if isAuthorized && !hasCompletedOnboarding {
            PersistenceService.shared.hasCompletedOnboarding = true
            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    ContentView()
}
