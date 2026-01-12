import Foundation
import Photos
import SwiftUI

@Observable
final class MainSwipeViewModel {
    private let photoService = PhotoLibraryService.shared
    private let persistence = PersistenceService.shared
    private let cacheService = PhotoCacheService.shared

    // Current state
    var currentFilter: PhotoFilter = .all
    var selectedYear: Int?
    var currentIndex: Int = 0
    var photos: [PhotoItem] = []
    var isLoading = false

    // Swipe state
    var cardOffset: CGSize = .zero
    var cardRotation: Double = 0
    var swipeDirection: SwipeDecision = .undecided
    var isProcessingSwipe = false

    // UI state
    var showFilterSheet = false
    var showTrashReview = false
    var showPhotoDetail = false
    var selectedPhotoForDetail: PhotoItem?

    // Stats
    var sessionStats: SessionStats {
        persistence.sessionStats
    }

    var currentPhoto: PhotoItem? {
        guard currentIndex >= 0, currentIndex < photos.count else { return nil }
        return photos[currentIndex]
    }

    var nextPhoto: PhotoItem? {
        guard currentIndex + 1 < photos.count else { return nil }
        return photos[currentIndex + 1]
    }

    var thirdPhoto: PhotoItem? {
        guard currentIndex + 2 < photos.count else { return nil }
        return photos[currentIndex + 2]
    }

    var progress: Double {
        guard !photos.isEmpty else { return 0 }
        let reviewed = persistence.reviewedPhotos.count
        let total = photos.count + reviewed
        guard total > 0 else { return 0 }
        return Double(reviewed) / Double(total)
    }

    var progressText: String {
        let reviewed = persistence.reviewedPhotos.count
        let total = photos.count + reviewed
        return "\(reviewed) of \(total)"
    }

    var canUndo: Bool {
        !persistence.undoStack.isEmpty
    }

    var markedForDeletionCount: Int {
        persistence.markedForDeletion.count
    }

    var maybePileCount: Int {
        persistence.maybePile.count
    }

    // MARK: - Lifecycle

    func loadPhotos() async {
        isLoading = true

        // Restore filter
        if let savedFilter = PhotoFilter(rawValue: persistence.currentFilter) {
            currentFilter = savedFilter
        }

        // Fetch all photos if needed
        if photoService.allPhotos.isEmpty {
            await photoService.fetchAllPhotos()
        }

        // Apply filter
        photos = photoService.filteredPhotos(filter: currentFilter, year: selectedYear)
        currentIndex = min(persistence.currentSessionIndex, max(0, photos.count - 1))

        // Prefetch upcoming photos
        await prefetchUpcoming()

        isLoading = false
    }

    func applyFilter(_ filter: PhotoFilter, year: Int? = nil) {
        currentFilter = filter
        selectedYear = year
        persistence.currentFilter = filter.rawValue
        photos = photoService.filteredPhotos(filter: filter, year: year)
        currentIndex = 0
        persistence.currentSessionIndex = 0

        Task {
            await prefetchUpcoming()
        }
    }

    // MARK: - Swipe Handling

    func handleSwipe(_ direction: SwipeDecision) {
        guard let photo = currentPhoto else { return }

        // Record action for undo
        let action = SwipeAction(assetIdentifier: photo.id, decision: direction)
        persistence.pushUndo(action)

        // Apply decision
        switch direction {
        case .keep:
            persistence.markAsReviewed(photo.id)

        case .delete:
            persistence.markForDeletion(photo.id)
            persistence.markAsReviewed(photo.id)

        case .maybe:
            persistence.addToMaybePile(photo.id)
            persistence.markAsReviewed(photo.id)

        case .undecided:
            break
        }

        // Update stats
        var stats = persistence.sessionStats
        stats.photosReviewed += 1
        persistence.sessionStats = stats

        // Move to next
        moveToNext()
    }

    func undo() {
        guard let lastAction = persistence.popUndo() else { return }

        // Reverse the decision
        switch lastAction.decision {
        case .keep:
            persistence.unmarkAsReviewed(lastAction.assetIdentifier)

        case .delete:
            persistence.unmarkForDeletion(lastAction.assetIdentifier)
            persistence.unmarkAsReviewed(lastAction.assetIdentifier)

        case .maybe:
            persistence.removeFromMaybePile(lastAction.assetIdentifier)
            persistence.unmarkAsReviewed(lastAction.assetIdentifier)

        case .undecided:
            break
        }

        // Reload photos and go back
        photos = photoService.filteredPhotos(filter: currentFilter, year: selectedYear)

        // Find the photo we just undid
        if let index = photos.firstIndex(where: { $0.id == lastAction.assetIdentifier }) {
            currentIndex = index
            persistence.currentSessionIndex = index
        } else {
            // Photo might be at the beginning now
            currentIndex = max(0, currentIndex - 1)
            persistence.currentSessionIndex = currentIndex
        }

        // Update stats
        var stats = persistence.sessionStats
        stats.photosReviewed = max(0, stats.photosReviewed - 1)
        persistence.sessionStats = stats
    }

    // MARK: - Navigation

    private func moveToNext() {
        // Remove current photo from filtered list (it's been reviewed)
        if currentIndex < photos.count {
            photos.remove(at: currentIndex)
        }

        // Keep index valid
        if currentIndex >= photos.count {
            currentIndex = max(0, photos.count - 1)
        }

        persistence.currentSessionIndex = currentIndex

        // Prefetch
        Task {
            await prefetchUpcoming()
        }
    }

    func showDetail(for photo: PhotoItem) {
        selectedPhotoForDetail = photo
        showPhotoDetail = true
    }

    // MARK: - Card Animation

    func updateCardPosition(_ translation: CGSize) {
        cardOffset = translation
        cardRotation = Double(translation.width) / 20

        // Determine swipe direction for visual feedback
        if translation.width > TidyTheme.Dimensions.swipeThreshold {
            swipeDirection = .keep
        } else if translation.width < -TidyTheme.Dimensions.swipeThreshold {
            swipeDirection = .delete
        } else if translation.height < -TidyTheme.Dimensions.verticalSwipeThreshold {
            swipeDirection = .maybe
        } else {
            swipeDirection = .undecided
        }
    }

    func resetCardPosition() {
        withAnimation(TidyTheme.Animation.cardSwipe) {
            cardOffset = .zero
            cardRotation = 0
            swipeDirection = .undecided
        }
    }

    func completeSwipe() {
        let direction = swipeDirection
        guard direction != .undecided, !isProcessingSwipe else {
            resetCardPosition()
            return
        }

        isProcessingSwipe = true

        // Process swipe immediately (before animation completes)
        handleSwipe(direction)

        // Animate card off screen
        withAnimation(TidyTheme.Animation.cardSwipe) {
            switch direction {
            case .keep:
                cardOffset = CGSize(width: 500, height: 0)
            case .delete:
                cardOffset = CGSize(width: -500, height: 0)
            case .maybe:
                cardOffset = CGSize(width: 0, height: -500)
            case .undecided:
                break
            }
        }

        // Reset card position after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.cardOffset = .zero
            self?.cardRotation = 0
            self?.swipeDirection = .undecided
            self?.isProcessingSwipe = false
        }
    }

    // MARK: - Prefetching

    private func prefetchUpcoming() async {
        let upcomingCount = min(5, photos.count - currentIndex)
        guard upcomingCount > 0 else { return }

        let startIndex = currentIndex
        let endIndex = min(currentIndex + upcomingCount, photos.count)
        let upcomingAssets = photos[startIndex..<endIndex].map { $0.asset }

        await cacheService.startCaching(assets: upcomingAssets)
    }
}
