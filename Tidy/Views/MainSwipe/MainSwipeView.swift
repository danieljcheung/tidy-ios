import SwiftUI

struct MainSwipeView: View {
    @Bindable var viewModel: MainSwipeViewModel
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        TidyTheme.Colors.background(for: colorScheme)
    }

    private var textColor: Color {
        TidyTheme.Colors.text(for: colorScheme)
    }

    var body: some View {
        ZStack {
            // Background with texture and vignette
            BackgroundView()

            // Main content
            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                // Main content area
                mainContentArea
                    .padding(.horizontal, 24)

                // Footer with progress
                footerView
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .padding(.top, 16)
            }
        }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            FilterSheetView(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $viewModel.showPhotoDetail) {
            if let photo = viewModel.selectedPhotoForDetail {
                PhotoDetailView(photo: photo)
            }
        }
        .task {
            await viewModel.loadPhotos()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // Left spacer for balance
            Color.clear
                .frame(width: 48, height: 48)

            Spacer()

            // Title (triple-tap to reset tutorial for testing)
            Text("Tidy")
                .font(TidyTheme.Typography.titleFallback())
                .foregroundStyle(textColor)
                .onTapGesture(count: 3) {
                    #if DEBUG
                    PersistenceService.shared.hasSeenTutorial = false
                    #endif
                }

            Spacer()

            // Filter button
            Button {
                viewModel.showFilterSheet = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 20))
                    .foregroundStyle(textColor)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)
            .captureFrame(id: "filterButton")
        }
    }

    // MARK: - Main Content

    private var mainContentArea: some View {
        ZStack {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.currentPhoto == nil {
                emptyStateView
            } else {
                // Swipe indicators (behind card)
                SwipeIndicatorsView(swipeDirection: viewModel.swipeDirection)
                    .padding(.horizontal, 40)

                // Card stack
                cardStackWithGesture

                // Action labels at bottom of card area
                actionLabelsView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(TidyTheme.Colors.primary)
            Text("Loading photos...")
                .font(TidyTheme.Typography.actionLabelFallback())
                .foregroundStyle(textColor.opacity(0.6))
        }
    }

    private var emptyStateView: some View {
        EmptyStateView(
            title: "All Done!",
            message: allDoneMessage,
            actionTitle: viewModel.markedForDeletionCount > 0 ? "Review Trash" : nil,
            action: {
                viewModel.showTrashReview = true
            }
        )
    }

    private var allDoneMessage: String {
        if viewModel.markedForDeletionCount > 0 {
            return "You've reviewed all photos. You have \(viewModel.markedForDeletionCount) photos marked for deletion."
        } else if viewModel.maybePileCount > 0 {
            return "Ready to tackle your \(viewModel.maybePileCount) maybes?"
        } else {
            return "Your photo library is all tidied up!"
        }
    }

    private var cardStackWithGesture: some View {
        CardStackView(
            currentPhoto: viewModel.currentPhoto,
            nextPhoto: viewModel.nextPhoto,
            thirdPhoto: viewModel.thirdPhoto,
            offset: viewModel.cardOffset,
            rotation: viewModel.cardRotation,
            onTap: {
                if let photo = viewModel.currentPhoto {
                    viewModel.showDetail(for: photo)
                }
            }
        )
        .captureFrame(id: "photoCard")
        .id(viewModel.currentPhoto?.id ?? "empty")
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !viewModel.isProcessingSwipe {
                        viewModel.updateCardPosition(value.translation)
                    }
                }
                .onEnded { _ in
                    if !viewModel.isProcessingSwipe {
                        viewModel.completeSwipe()
                    }
                }
        )
    }

    private var actionLabelsView: some View {
        VStack {
            Spacer()

            HStack {
                // Delete label
                Button {
                    viewModel.updateCardPosition(CGSize(width: -150, height: 0))
                    viewModel.completeSwipe()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                        Text("Delete")
                            .font(TidyTheme.Typography.actionLabelFallback())
                    }
                    .foregroundStyle(textColor.opacity(0.6))
                }
                .buttonStyle(.plain)

                Spacer()

                // Undo button (centered, elevated)
                UndoButtonView(
                    action: { viewModel.undo() },
                    isEnabled: viewModel.canUndo
                )
                .captureFrame(id: "undoButton")
                .offset(y: -12)

                Spacer()

                // Keep label
                Button {
                    viewModel.updateCardPosition(CGSize(width: 150, height: 0))
                    viewModel.completeSwipe()
                } label: {
                    HStack(spacing: 6) {
                        Text("Keep")
                            .font(TidyTheme.Typography.actionLabelFallback())
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                    }
                    .foregroundStyle(textColor.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        let reviewed = PersistenceService.shared.reviewedPhotos.count
        let total = viewModel.photos.count + reviewed

        return ProgressBarView(
            current: reviewed,
            total: total,
            progress: viewModel.progress
        )
        .captureFrame(id: "progressBar")
    }
}

// MARK: - Background View

private struct BackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Base color
            TidyTheme.Colors.background(for: colorScheme)
                .ignoresSafeArea()

            // Paper texture overlay (simulated with noise)
            Rectangle()
                .fill(
                    colorScheme == .dark
                        ? Color.white.opacity(0.02)
                        : Color.black.opacity(0.02)
                )
                .ignoresSafeArea()

            // Vignette
            RadialGradient(
                colors: [
                    .clear,
                    TidyTheme.Colors.charcoal.opacity(0.08)
                ],
                center: .center,
                startRadius: UIScreen.main.bounds.height * 0.25,
                endRadius: UIScreen.main.bounds.height * 0.7
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    MainSwipeView(viewModel: MainSwipeViewModel())
}
