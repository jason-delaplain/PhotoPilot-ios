import SwiftUI
import Photos
import UIKit

struct ScreenshotsView: View {
    let onBack: () -> Void
    @StateObject private var photoManager = PhotoLibraryManager()
    @State private var screenshots: [PHAsset] = []
    @State private var isLoading = true
    @State private var selectedAsset: PHAsset? = nil
    @State private var showViewer = false
    @State private var initialImage: UIImage? = nil
    @State private var alertMessage: String? = nil
    @State private var showAlert = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                content
            }
            if showViewer, let asset = selectedAsset {
                FullScreenPhotoViewer(
                    asset: asset,
                    isPresented: $showViewer,
                    initialImage: initialImage,
                    onDelete: { asset in
                        let mgr = PhotoLibraryManager()
                        let success = await mgr.deletePhoto(asset)
                        if success { await MainActor.run { removeAssetLocally(asset) } }
                        return success
                    }
                )
                .transition(.opacity.combined(with: .scale))
                .zIndex(2)
            }
        }
        .background(Color.black)
        .alert(alertMessage ?? "", isPresented: $showAlert) { Button("OK", role: .cancel) {} }
        .task { await initialize() }
    }
    
    private var header: some View {
        HStack {
            Button { onBack() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("Screenshots")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                if !isLoading {
                    Text("\(screenshots.count) items")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
            Spacer()
            if !isLoading {
                Button(action: { Task { await refresh() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Refresh screenshots")
            } else {
                Color.clear.frame(width: 32)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(height: 44)
        .background(
            LinearGradient(gradient: AppGradient.headerGradient, startPoint: .leading, endPoint: .trailing)
        )
    }
    
    private var content: some View {
        Group {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.4)
                        .tint(AppColors.primary)
                    Text("Scanning for screenshots…")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 15))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if screenshots.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "iphone")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primary)
                    Text("No Screenshots Found")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Try capturing a screenshot or refreshing.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Pull down to refresh")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(screenshots, id: \.localIdentifier) { asset in
                            ScreenshotThumbnail(asset: asset) { thumb in
                                initialImage = thumb ?? SolidColorImageBuilder.build(color: UIColor(white: 0.15, alpha: 1.0))
                                selectedAsset = asset
                                withAnimation(.easeInOut(duration: 0.18)) { showViewer = true }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .refreshable { await refresh() }
            }
        }
    }
    
    private func initialize() async {
        let authorized = await photoManager.requestAuthorization()
        guard authorized else {
            alertMessage = "Photo library access is required"
            showAlert = true
            isLoading = false
            return
        }
        await photoManager.fetchAllPhotos()
        screenshots = photoManager.photos.filter { $0.mediaSubtypes.contains(.photoScreenshot) }
        isLoading = false
    }
    
    private func refresh() async {
        isLoading = true
        await photoManager.fetchAllPhotos()
        screenshots = photoManager.photos.filter { $0.mediaSubtypes.contains(.photoScreenshot) }
        isLoading = false
    }
    
    private func removeAssetLocally(_ asset: PHAsset) {
        let id = asset.localIdentifier
        screenshots.removeAll { $0.localIdentifier == id }
        // Also prune from shared cache manager for consistency
        PhotoCacheManager.shared.removeAssets(withIDs: Set([id]))
    }
}

// MARK: - Thumbnail

private struct ScreenshotThumbnail: View {
    let asset: PHAsset
    let onTap: (_ thumbnail: UIImage?) -> Void
    @State private var image: UIImage? = nil
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width / 3 - 2, height: UIScreen.main.bounds.width / 3 - 2)
                    .clipped()
            } else {
                Rectangle()
                    .fill(AppColors.card)
                    .frame(width: UIScreen.main.bounds.width / 3 - 2, height: UIScreen.main.bounds.width / 3 - 2)
                    .overlay(
                        ProgressView()
                            .tint(AppColors.primary)
                            .scaleEffect(0.7)
                    )
            }
        }
        .onTapGesture { onTap(image) }
        .task { await loadImage() }
    }
    
    private func loadImage() async {
        let mgr = PhotoLibraryManager()
        image = await mgr.loadImage(from: asset, targetSize: CGSize(width: 400, height: 400))
    }
}

// Reuse SolidColorImageBuilder from ColorPhotosView (kept internal there); duplicate minimal builder here for independence.
fileprivate struct SolidColorImageBuilder {
    static func build(color: UIColor, size: CGSize = CGSize(width: 60, height: 60)) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            color.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            let highlightColor = UIColor(white: 1.0, alpha: 0.10)
            let center = CGPoint(x: size.width/2, y: size.height/2)
            let radius = min(size.width, size.height)/2
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [highlightColor.cgColor, UIColor.clear.cgColor] as CFArray, locations: [0,1])
            ctx.cgContext.drawRadialGradient(gradient!, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: .drawsAfterEndLocation)
        }
    }
}

#Preview {
    ScreenshotsView(onBack: {})
}
