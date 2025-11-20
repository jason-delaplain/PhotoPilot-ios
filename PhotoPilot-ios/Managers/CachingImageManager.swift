import Foundation
import Photos

/// Wrapper around PHCachingImageManager to allow preheating of upcoming assets (e.g., next/previous in grids).
final class CachingImageManager {
    static let shared = CachingImageManager()
    private let manager = PHCachingImageManager()
    private init() {}
    
    /// Preheat thumbnails for anticipated assets.
    func preheat(assets: [PHAsset], targetSize: CGSize) {
        guard !assets.isEmpty else { return }
        manager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: nil)
    }
    
    /// Stop caching when assets are no longer needed.
    func stopCaching(assets: [PHAsset], targetSize: CGSize) {
        guard !assets.isEmpty else { return }
        manager.stopCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: nil)
    }
    
    /// Convenience to reset all caching (e.g., memory warning).
    func reset() { manager.stopCachingImagesForAllAssets() }
}
