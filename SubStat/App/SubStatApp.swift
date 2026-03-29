import SwiftUI

@main
struct SubStatApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var viewModel = SubscriptionViewModel()

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environmentObject(viewModel)
                .environmentObject(settings)
        } label: {
            MenuBarLabel(viewModel: viewModel, settings: settings)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(viewModel)
        }
    }
}
