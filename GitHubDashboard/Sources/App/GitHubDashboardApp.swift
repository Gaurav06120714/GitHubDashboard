import SwiftUI

@main
struct GitHubDashboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var service = GitHubService()

    var body: some Scene {
        WindowGroup("GitHub Dashboard") {
            if service.isAuthenticated {
                MainView()
                    .environmentObject(service)
            } else {
                TokenSetupView()
                    .environmentObject(service)
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appSettings) {
                Button("Sign Out") {
                    // Access service via the environment in the active window
                }
            }
        }
    }
}
