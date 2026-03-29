import SwiftUI

@main
struct SubStatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty scene — everything is managed by AppDelegate
        Settings {
            EmptyView()
        }
    }
}
