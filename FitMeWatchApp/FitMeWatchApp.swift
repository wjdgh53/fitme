import SwiftUI

@main
struct FitMeWatchApp: App {
    @StateObject private var controller = WatchWorkoutController()

    var body: some Scene {
        WindowGroup {
            WatchMainView(controller: controller)
        }
    }
}
