import SwiftUI

@main
struct FitMeApp: App {
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appViewModel)
        }
    }
}
