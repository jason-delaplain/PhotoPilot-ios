# PhotoPilot iOS

AI-assisted photo management and cleanup app for iOS. PhotoPilot helps you rapidly triage, explore, and intelligently organize your photo library using on-device analysis (no cloud upload). It focuses on fast progressive loading, frictionless deletion, and smart grouping.

## ✨ Core Features

| Area | What It Does |
|------|--------------|
| Swipe Photos | Rapid left/right (keep vs delete) triage workflow with full-screen progressive viewer |
| Blurry Photos | Detects low-quality / out-of-focus images for quick cleanup |
| Duplicate Detection | Identifies identical or near-identical assets to reclaim storage |
| Similar Photos | Clusters visually similar shots (bursts, near-duplicates) for selective pruning |
| Color Photos | Groups images by dominant color(s) for creative browsing or mood curation |
| Keyword Search | Semantic content search using natural language queries (e.g. "sunset beach") |
| Screenshots | Dedicated view for screenshot cleanup; fast bulk review & deletion |
| Progressive Loading | Low-res fastFormat placeholder → high-res fetch → data fallback if needed |
| Safe Deletion | Confirmation dialog + PhotoKit change request + immediate UI/cache pruning |
| Smart Caching | Background preparation of feature-specific subsets with status tracking |

## 🧠 Technical Highlights
- SwiftUI overlay viewer eliminates black screen flickers (replaces modal fullScreenCover).
- Multi-tier image fallback: pre-seeded placeholder → opportunistic low-res → high-res → raw data.
- Central `PhotoLibraryManager` for authorization, fetching, high-res loading, and deletion.
- `PhotoAssetLoader` progressive pipeline tuned with `PHImageRequestOptions.fastFormat` for instant pixels.
- Feature-level cache statuses (`notStarted`, `loading`, `completed`) via a shared cache manager.
- Deletion path: confirmation → async PhotoKit `performChanges` → local state & color group pruning.
- Screenshots auto-scan integrated into initial background processing like other features.

## 📂 Project Structure (High-Level)
```
PhotoPilot-ios/
├── PhotoPilot_iosApp.swift        # App entry point (SwiftUI)
├── ContentView.swift              # Top-level navigation container
├── LandingView.swift              # Feature selection grid
├── Managers/
│   └── PhotoLibraryManager.swift  # Library access, image load, deletion
├── Utilities/
│   ├── PhotoAssetLoader.swift     # Progressive loading helpers
│   ├── PhotoAlgorithms.swift      # Image analysis (colors, similarity, etc.)
│   └── Extensions.swift           # Reusable Swift extensions
├── Views/
│   ├── SwipePhotosView.swift      # Swipe triage
│   ├── BlurryPhotosView.swift     # Blur detection UI
│   ├── DuplicatesView.swift       # Duplicate management
│   ├── SimilarPhotosView.swift    # Similar clustering
│   ├── ColorPhotosView.swift      # Dominant color grouping
│   ├── KeywordSearchView.swift    # Semantic search interface
│   └── ScreenshotsView.swift      # Screenshot cleanup
└── Assets.xcassets/               # App icons, color assets
```

## 🚀 Getting Started
1. Clone:
   ```bash
   git clone https://github.com/jason-delaplain/PhotoPilot-ios.git
   cd PhotoPilot-ios
   ```
2. Open in Xcode (15+):
   ```bash
   open PhotoPilot-ios.xcodeproj
   ```
3. Select an iOS 17+ simulator or device.
4. Build & Run (⌘R). Grant photo library permission when prompted.

## ✅ Current Implemented Behaviors
- Overlay full-screen viewer with centered alignment and progressive image loading.
- Screenshot feature parity (auto-scan + deletion workflow).
- Color grouping with dynamic pruning after deletions.
- Keyword search view foundation (semantic tokenization improvements).
- Placeholder strategy preventing black flashes on viewer open.

## 🔄 Progressive Image Loading Contract
- Input: `PHAsset` (+ target size).
- Output: `UIImage?` (first low-res opportunistic, then upgraded to high-res).
- Fallback: Raw data decoding if normal request yields nil.
- Guarantees: Always a non-black placeholder within ~1 frame; upgrades do not block UI.

## 🛡️ Deletion Workflow
1. User taps trash → confirmation dialog.
2. PhotoKit `performChanges` executes removal.
3. Local collections & caches updated immediately (optimistic UI).
4. Color groups & screenshot lists re-render without the asset.

## 📦 Caching & Background Prep
- Each feature has a cache status to enable optimistic UI and show readiness.
- Screenshots now included in initial load sequence (marked loading → completed automatically).
- Background processing order prioritizes user-visible subsets.

## 🧪 Testing Strategy (Planned/Partial)
- Unit tests for progressive loader fallback paths.
- Snapshot tests for viewer overlay layout.
- Performance sampling for low-res fetch latency (future instrumentation).

## 🗺️ Roadmap / Next Enhancements
- Bulk selection & multi-delete (especially for screenshots & duplicates).
- Similar photo scoring refinements & confidence UI.
- On-device semantic embedding indexing acceleration.
- Date/app grouping for screenshots.
- Undo buffer / soft delete staging area.
- Accessibility (VoiceOver descriptions from semantic index).

## 🔐 Privacy
All analysis occurs on-device. Photos are never uploaded externally. Only the minimum permissions required for reading & deleting user-selected assets are requested.

## 🤝 Contributing
Issues and PRs welcome once core feature set stabilizes. Please:
- Prefer small, focused changes.
- Include rationale + screenshots for UI updates.
- Add/adjust tests when modifying loading or deletion logic.

## 📝 License
See `LICENSE` for details.

---
If you encounter flicker or loading regressions, open an issue with device model, iOS version, and steps. Enjoy faster photo cleanup with PhotoPilot!
