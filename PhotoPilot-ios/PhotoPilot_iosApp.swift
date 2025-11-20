import SwiftUI
import SwiftData
import Photos
import OSLog

@main
struct PhotoPilot_iosApp: App {
    private static let logger = Logger(subsystem: "com.photopilot.app", category: "Lifecycle")
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }

    init() {
        // Observe memory warnings to purge high-res cache proactively.
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) { _ in
            HighResImageCache.shared.purge()
            CachingImageManager.shared.reset()
            PhotoPilot_iosApp.logger.info("Memory warning received – purged HighResImageCache and reset CachingImageManager")
        }
    }
}
