import Foundation
import Photos
import UIKit

struct PhotoItem: Identifiable, Equatable {
    let id: String
    let asset: PHAsset

    var isVideo: Bool {
        asset.mediaType == .video
    }

    var isLivePhoto: Bool {
        asset.mediaSubtypes.contains(.photoLive)
    }

    var isScreenshot: Bool {
        asset.mediaSubtypes.contains(.photoScreenshot)
    }

    var creationDate: Date? {
        asset.creationDate
    }

    var fileSize: Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first else { return 0 }
        if let size = resource.value(forKey: "fileSize") as? Int64 {
            return size
        }
        return 0
    }

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var duration: TimeInterval {
        asset.duration
    }

    var durationFormatted: String {
        guard isVideo else { return "" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
    }

    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}
