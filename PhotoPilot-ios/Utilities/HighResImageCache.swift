import Foundation
import Photos
import UIKit

/// Simple LRU cache for high-resolution images keyed by PHAsset localIdentifier.
/// Size bound by maxCount to avoid excessive memory usage; purged on memory warning.
final class HighResImageCache {
    static let shared = HighResImageCache()
    private init() {}
    
    private struct Entry { let id: String; let image: UIImage }
    private var entries: [Entry] = []
    private var indexMap: [String: Int] = [:]
    private let lock = NSLock()
    
    /// Maximum number of high-res images to retain. Tune as needed.
    var maxCount: Int = 60
    
    func get(for asset: PHAsset) -> UIImage? {
        let id = asset.localIdentifier
        lock.lock(); defer { lock.unlock() }
        guard let idx = indexMap[id] else { return nil }
        // Move to front (most recently used)
        let entry = entries.remove(at: idx)
        entries.insert(entry, at: 0)
        // Rebuild indexMap for affected range (small overhead acceptable at this scale)
        rebuildIndices()
        return entry.image
    }
    
    func put(_ image: UIImage, for asset: PHAsset) {
        let id = asset.localIdentifier
        lock.lock(); defer { lock.unlock() }
        if let idx = indexMap[id] {
            // Replace & move to front
            entries.remove(at: idx)
        }
        entries.insert(Entry(id: id, image: image), at: 0)
        if entries.count > maxCount { entries.removeLast() }
        rebuildIndices()
    }
    
    func purge() {
        lock.lock(); defer { lock.unlock() }
        entries.removeAll(); indexMap.removeAll()
    }
    
    var count: Int { lock.lock(); defer { lock.unlock() }; return entries.count }
    
    private func rebuildIndices() {
        indexMap.removeAll(keepingCapacity: true)
        for (i, e) in entries.enumerated() { indexMap[e.id] = i }
    }
}
