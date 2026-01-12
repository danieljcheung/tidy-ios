import Foundation
import SwiftUI

@Observable
final class FilterViewModel {
    private let photoService = PhotoLibraryService.shared
    private let persistence = PersistenceService.shared

    var selectedFilter: PhotoFilter = .all
    var selectedYear: Int?
    var availableYears: [Int] = []

    // Filter counts
    var allPhotosCount: Int = 0
    var screenshotsCount: Int = 0
    var last30DaysCount: Int = 0
    var maybePileCount: Int = 0

    init() {
        loadCounts()
    }

    func loadCounts() {
        availableYears = photoService.availableYears

        allPhotosCount = photoService.unreviewedCount(filter: .all)
        screenshotsCount = photoService.unreviewedCount(filter: .screenshots)
        last30DaysCount = photoService.unreviewedCount(filter: .last30Days)
        maybePileCount = photoService.maybePileCount()

        // Restore previous selection
        if let savedFilter = PhotoFilter(rawValue: persistence.currentFilter) {
            selectedFilter = savedFilter
        }
    }

    func count(for filter: PhotoFilter) -> Int {
        switch filter {
        case .all: return allPhotosCount
        case .screenshots: return screenshotsCount
        case .last30Days: return last30DaysCount
        case .maybePile: return maybePileCount
        }
    }

    func count(for year: Int) -> Int {
        photoService.unreviewedCount(filter: .all, year: year)
    }

    func selectFilter(_ filter: PhotoFilter) {
        selectedFilter = filter
        selectedYear = nil
        persistence.currentFilter = filter.rawValue
    }

    func selectYear(_ year: Int) {
        selectedFilter = .all
        selectedYear = year
        persistence.currentFilter = "year_\(year)"
    }
}
