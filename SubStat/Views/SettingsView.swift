import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var viewModel: SubscriptionViewModel

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 420, height: 340)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section("Subscription") {
                TextField("Subscription URL", text: $settings.subscriptionURL)
                    .textFieldStyle(.roundedBorder)

                TextField("Name", text: $settings.subscriptionName)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Refresh") {
                Picker("Interval", selection: Binding(
                    get: { settings.refreshInterval },
                    set: { settings.refreshInterval = $0 }
                )) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
            }

            Section("Menubar") {
                Picker("Display", selection: Binding(
                    get: { settings.displayMode },
                    set: { settings.displayMode = $0 }
                )) {
                    ForEach(MenuBarDisplayMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }

            Section("System") {
                Toggle("Launch at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { newValue in
                        settings.launchAtLogin = newValue
                        LaunchAtLoginManager.setEnabled(newValue)
                    }
                ))
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        AboutView()
    }
}
