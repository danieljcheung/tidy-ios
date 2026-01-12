import Photos
import UIKit

enum PhotoFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case screenshots = "screenshots"
    case last30Days = "last30days"
    case largestFirst = "largest"
    case maybePile = "maybe"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All Photos"
        case .screenshots: return "Screenshots"
        case .last30Days: return "Last 30 Days"
        case .largestFirst: return "Largest First"
        case .maybePile: return "Maybe Pile"
        }
    }

    var iconName: String {
        switch self {
        case .all: return "photo.on.rectangle"
        case .screenshots: return "camera.viewfinder"
        case .last30Days: return "calendar"
        case .largestFirst: return "arrow.up.doc"
        case .maybePile: return "questionmark.circle"
        }
    }
}

enum PhotoYear: Hashable, Identifiable {
    case year(Int)

    var id: Int {
        switch self {
        case .year(let y): return y
        }
    }

    var displayName: String {
        switch self {
        case .year(let y): return String(y)
        }
    }
}

@Observable
final class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    private(set) var authorizationStatus: PHAuthorizationStatus = .notDetermined
    private(set) var isLoading = false
    private(set) var allPhotos: [PhotoItem] = []
    private(set) var availableYears: [Int] = []

    private let persistence = PersistenceService.shared

    private init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    // MARK: - Authorization

    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            self.authorizationStatus = status
        }
        return status
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    // MARK: - Fetching

    func fetchAllPhotos() async {
        guard isAuthorized else { return }

        await MainActor.run {
            self.isLoading = true
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeHiddenAssets = false
        fetchOptions.includeAllBurstAssets = false

        let results = PHAsset.fetchAssets(with: fetchOptions)
        let assets = results.toArray()
        let items = assets.map { PhotoItem(asset: $0) }

        // Extract available years
        let years = Set(items.compactMap { $0.creationDate?.year }).sorted(by: >)

        await MainActor.run {
            self.allPhotos = items
            self.availableYears = years
            self.isLoading = false
        }
    }

    // MARK: - Filtering

    func filteredPhotos(filter: PhotoFilter, year: Int? = nil) -> [PhotoItem] {
        let reviewed = persistence.reviewedPhotos
        let maybePile = persistence.maybePile
        let markedForDeletion = persistence.markedForDeletion

        var result: [PhotoItem]

        switch filter {
        case .all:
            result = allPhotos.filter { !reviewed.contains($0.id) && !markedForDeletion.contains($0.id) }

        case .screenshots:
            result = allPhotos.filter {
                $0.isScreenshot && !reviewed.contains($0.id) && !markedForDeletion.contains($0.id)
            }

        case .last30Days:
            result = allPhotos.filter {
                $0.asset.isFromLast30Days && !reviewed.contains($0.id) && !markedForDeletion.contains($0.id)
            }

        case .largestFirst:
            result = allPhotos
                .filter { !reviewed.contains($0.id) && !markedForDeletion.contains($0.id) }
                .sorted { $0.fileSize > $1.fileSize }

        case .maybePile:
            result = allPhotos.filter { maybePile.contains($0.id) && !markedForDeletion.contains($0.id) }
        }

        // Apply year filter if specified
        if let year = year {
            result = result.filter { $0.asset.year == year }
        }

        return result
    }

    func photosMarkedForDeletion() -> [PhotoItem] {
        let markedIds = persistence.markedForDeletion
        return allPhotos.filter { markedIds.contains($0.id) }
    }

    func maybePilePhotos() -> [PhotoItem] {
        let maybeIds = persistence.maybePile
        return allPhotos.filter { maybeIds.contains($0.id) }
    }

    // MARK: - Photo Groups (timestamp-based)

    func groupedPhotos(filter: PhotoFilter, year: Int? = nil) -> [PhotoGroup] {
        let photos = filteredPhotos(filter: filter, year: year)
        return PhotoGroup.groupByTimestamp(photos)
    }

    // MARK: - Deletion

    func deletePhotos(identifiers: [String]) async throws -> Int64 {
        let assetsToDelete = allPhotos
            .filter { identifiers.contains($0.id) }
            .map { $0.asset }

        guard !assetsToDelete.isEmpty else { return 0 }

        // Calculate total size before deletion
        var totalSize: Int64 = 0
        for asset in assetsToDelete {
            totalSize += await asset.estimatedFileSize()
        }

        // Perform deletion (moves to Recently Deleted)
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
        }

        // Clear from persistence
        for identifier in identifiers {
            persistence.unmarkForDeletion(identifier)
            persistence.removeFromMaybePile(identifier)
            persistence.unmarkAsReviewed(identifier)
        }

        // Remove from local array
        await MainActor.run {
            self.allPhotos.removeAll { identifiers.contains($0.id) }
        }

        return totalSize
    }

    // MARK: - Stats

    func totalPhotosCount() -> Int {
        allPhotos.count
    }

    func unreviewedCount(filter: PhotoFilter, year: Int? = nil) -> Int {
        filteredPhotos(filter: filter, year: year).count
    }

    func reviewedCount() -> Int {
        persistence.reviewedPhotos.count
    }

    func markedForDeletionCount() -> Int {
        persistence.markedForDeletion.count
    }

    func maybePileCount() -> Int {
        persistence.maybePile.count
    }
}

private extension Date {
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
}
