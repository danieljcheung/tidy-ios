import Photos
import UIKit
import SwiftUI

// Helper class to track if continuation has been resumed (reference type)
private final class ContinuationState {
    var hasResumed = false
}

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
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            let state = ContinuationState()

            imageManager.requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, info in
                // Ensure we only resume once (state is reference type)
                guard !state.hasResumed else { return }
                state.hasResumed = true

                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let hasError = info?[PHImageErrorKey] != nil

                if isCancelled || hasError {
                    continuation.resume(returning: nil)
                    return
                }

                if let image = image {
                    if let self = self {
                        Task {
                            await self.cacheThumbnail(image, forKey: cacheKey)
                        }
                    }
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
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
            let state = ContinuationState()

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { [weak self] image, info in
                // Ensure we only resume once
                guard !state.hasResumed else { return }

                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let hasError = info?[PHImageErrorKey] != nil
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false

                if isCancelled || hasError {
                    state.hasResumed = true
                    continuation.resume(returning: nil)
                    return
                }

                // Wait for the non-degraded (final) image
                if !isDegraded {
                    state.hasResumed = true
                    if let image = image {
                        if let self = self {
                            Task {
                                await self.cacheFullSize(image, forKey: cacheKey)
                            }
                        }
                    }
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
            let state = ContinuationState()

            imageManager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                // Ensure we only resume once
                guard !state.hasResumed else { return }

                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let hasError = info?[PHImageErrorKey] != nil
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false

                if isCancelled || hasError {
                    state.hasResumed = true
                    continuation.resume(returning: nil)
                    return
                }

                // Wait for the non-degraded (final) image
                if !isDegraded {
                    state.hasResumed = true
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
