import Foundation
import Photos
import UIKit
import OSLog

/// Centralized progressive photo loading helper used by full-screen viewers.
/// Provides low-res opportunistic fetch, high-res fetch via custom manager, and data fallback.
struct PhotoAssetLoader {
    private static let logger = Logger(subsystem: "com.photopilot.loader", category: "PhotoAssetLoader")
    private static let highResCache = HighResImageCache.shared
    private static let cachingManager = CachingImageManager.shared
    /// Fetch a quick low-resolution image opportunistically.
    static func loadLowRes(asset: PHAsset, target: CGSize = CGSize(width: 600, height: 600)) async -> UIImage? {
        let t0 = CACurrentMediaTime()
        let options = PHImageRequestOptions()
        // Use fastFormat for the earliest possible placeholder to avoid black screen flashes.
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        var result: UIImage? = nil
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var didResume = false
            PHImageManager.default().requestImage(for: asset, targetSize: target, contentMode: .aspectFill, options: options) { img, info in
                if let img = img { result = img }
                if !didResume { didResume = true; continuation.resume() }
            }
        }
    let msLow = (CACurrentMediaTime() - t0) * 1000
    let msLowStr = String(format: "%.1f", msLow)
    logger.debug("LowRes load for \(asset.localIdentifier, privacy: .public) took \(msLowStr) ms")
        return result
    }

    /// Fetch a higher resolution image via PhotoLibraryManager abstraction.
    static func loadHighRes(asset: PHAsset, target: CGSize = CGSize(width: 2400, height: 2400)) async -> UIImage? {
        // Cache check first
        if let cached = highResCache.get(for: asset) {
            logger.debug("HighRes cache HIT for \(asset.localIdentifier, privacy: .public)")
            return cached
        }
        logger.debug("HighRes cache MISS for \(asset.localIdentifier, privacy: .public). Loading…")
        let t0 = CACurrentMediaTime()
        let manager = PhotoLibraryManager() // Consider refactoring to a shared instance later
        let image = await manager.loadImage(from: asset, targetSize: target)
        if let img = image { highResCache.put(img, for: asset) }
    let msHigh = (CACurrentMediaTime() - t0) * 1000
    let msHighStr = String(format: "%.1f", msHigh)
    logger.debug("HighRes load for \(asset.localIdentifier, privacy: .public) took \(msHighStr) ms")
        return image
    }

    /// Fallback: load raw image data when normal request fails.
    static func loadDataFallback(asset: PHAsset) async -> UIImage? {
        let t0 = CACurrentMediaTime()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        var image: UIImage? = nil
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                if let data, let img = UIImage(data: data) { image = img }
                continuation.resume()
            }
        }
        if let img = image { highResCache.put(img, for: asset) }
    let msData = (CACurrentMediaTime() - t0) * 1000
    let msDataStr = String(format: "%.1f", msData)
    logger.debug("Data fallback for \(asset.localIdentifier, privacy: .public) took \(msDataStr) ms (image? \(image != nil ? 1 : 0))")
        return image
    }
}
