import Photos
import UIKit

extension PHAsset {
    var isScreenshot: Bool {
        mediaSubtypes.contains(.photoScreenshot)
    }

    var isLivePhoto: Bool {
        mediaSubtypes.contains(.photoLive)
    }

    var year: Int? {
        guard let date = creationDate else { return nil }
        return Calendar.current.component(.year, from: date)
    }

    var isFromLast30Days: Bool {
        guard let date = creationDate else { return false }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return date >= thirtyDaysAgo
    }

    func estimatedFileSize() async -> Int64 {
        let resources = PHAssetResource.assetResources(for: self)
        guard let resource = resources.first else { return 0 }

        if let size = resource.value(forKey: "fileSize") as? Int64 {
            return size
        }

        // Fallback: estimate based on dimensions and media type
        if mediaType == .video {
            // Rough estimate: 10MB per minute of video
            return Int64(duration * 10 * 1024 * 1024 / 60)
        } else {
            // Rough estimate: 2-5MB per photo based on dimensions
            let pixels = Int64(pixelWidth * pixelHeight)
            return pixels * 3 / 1024 / 1024 * 1024 * 1024 // Rough JPEG estimate
        }
    }
}

extension PHFetchResult where ObjectType == PHAsset {
    func toArray() -> [PHAsset] {
        var assets: [PHAsset] = []
        assets.reserveCapacity(count)
        enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }
}
