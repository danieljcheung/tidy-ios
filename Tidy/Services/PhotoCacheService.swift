import Photos
import UIKit
import SwiftUI

actor PhotoCacheService {
    static let shared = PhotoCacheService()

    private let thumbnailCache = NSCache<NSString, UIImage>()
    private let fullSizeCache = NSCache<NSString, UIImage>()
    private let imageManager = PHCachingImageManager()

    private let thumbnailSize = CGSize(width: 200, height: 200)
    private let cardSize = CGSize(width: 600, height: 800)

    init() {
        thumbnailCache.countLimit = 200
        fullSizeCache.countLimit = 20

        imageManager.allowsCachingHighQualityImages = true
    }

    // MARK: - Thumbnail Loading

    func thumbnail(for asset: PHAsset) async -> UIImage? {
        let cacheKey = NSString(string: "\(asset.localIdentifier)_thumb")

        if let cached = thumbnailCache.object(forKey: cacheKey) {
            return cached
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, info in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }

                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false

                if let image = image, !isDegraded {
                    Task {
                        await self.cacheThumbnail(image, forKey: cacheKey)
                    }
                }

                if !isDegraded || image != nil {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    private func cacheThumbnail(_ image: UIImage, forKey key: NSString) {
        thumbnailCache.setObject(image, forKey: key)
    }

    // MARK: - Card Size Loading (for swipe view)

    func cardImage(for asset: PHAsset) async -> UIImage? {
        let cacheKey = NSString(string: "\(asset.localIdentifier)_card")

        if let cached = fullSizeCache.object(forKey: cacheKey) {
            return cached
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false

        let targetSize = CGSize(
            width: cardSize.width * UIScreen.main.scale,
            height: cardSize.height * UIScreen.main.scale
        )

        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { [weak self] image, info in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }

                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false

                if let image = image, !isDegraded {
                    Task {
                        await self.cacheFullSize(image, forKey: cacheKey)
                    }
                    continuation.resume(returning: image)
                } else if isDegraded, image != nil {
                    // Return degraded image first, will be replaced by high quality
                    continuation.resume(returning: image)
                }
            }
        }
    }

    private func cacheFullSize(_ image: UIImage, forKey key: NSString) {
        fullSizeCache.setObject(image, forKey: key)
    }

    // MARK: - Full Resolution Loading (for detail view)

    func fullResolutionImage(for asset: PHAsset) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    // MARK: - Prefetching

    func startCaching(assets: [PHAsset]) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false

        imageManager.startCachingImages(
            for: assets,
            targetSize: cardSize,
            contentMode: .aspectFit,
            options: options
        )
    }

    func stopCaching(assets: [PHAsset]) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic

        imageManager.stopCachingImages(
            for: assets,
            targetSize: cardSize,
            contentMode: .aspectFit,
            options: options
        )
    }

    func stopCachingAll() {
        imageManager.stopCachingImagesForAllAssets()
    }

    // MARK: - Cache Management

    func clearCaches() {
        thumbnailCache.removeAllObjects()
        fullSizeCache.removeAllObjects()
        imageManager.stopCachingImagesForAllAssets()
    }
}
