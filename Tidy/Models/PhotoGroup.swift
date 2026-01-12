import Foundation
import Photos

struct PhotoGroup: Identifiable {
    let id: UUID
    let photos: [PhotoItem]
    let timestamp: Date

    var count: Int {
        photos.count
    }

    var isSinglePhoto: Bool {
        photos.count == 1
    }

    var firstPhoto: PhotoItem? {
        photos.first
    }

    init(photos: [PhotoItem]) {
        self.id = UUID()
        self.photos = photos
        self.timestamp = photos.first?.creationDate ?? Date()
    }

    static func groupByTimestamp(_ items: [PhotoItem], threshold: TimeInterval = 10) -> [PhotoGroup] {
        guard !items.isEmpty else { return [] }

        let sorted = items.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }

        var groups: [PhotoGroup] = []
        var currentGroup: [PhotoItem] = []
        var lastDate: Date?

        for item in sorted {
            guard let currentDate = item.creationDate else {
                if !currentGroup.isEmpty {
                    groups.append(PhotoGroup(photos: currentGroup))
                    currentGroup = []
                }
                groups.append(PhotoGroup(photos: [item]))
                lastDate = nil
                continue
            }

            if let last = lastDate {
                if currentDate.timeIntervalSince(last) <= threshold {
                    currentGroup.append(item)
                } else {
                    if !currentGroup.isEmpty {
                        groups.append(PhotoGroup(photos: currentGroup))
                    }
                    currentGroup = [item]
                }
            } else {
                currentGroup = [item]
            }

            lastDate = currentDate
        }

        if !currentGroup.isEmpty {
            groups.append(PhotoGroup(photos: currentGroup))
        }

        return groups
    }
}
