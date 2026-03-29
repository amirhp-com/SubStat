import SwiftUI

@main
struct SubStatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No scenes — everything managed by AppDelegate + NSPopover
        // Using WindowGroup with empty condition to satisfy the protocol
        Settings {
            Text("")
                .frame(width: 0, height: 0)
                .hidden()
        }
    }
}
