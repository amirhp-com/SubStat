import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var viewModel: SubscriptionViewModel

    var body: some View {
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

            Section("Menubar Display") {
                Picker("Show", selection: Binding(
                    get: { settings.displayMode },
                    set: { settings.displayMode = $0 }
                )) {
                    ForEach(MenuBarDisplayMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Picker("Data Unit", selection: Binding(
                    get: { settings.dataUnit },
                    set: { settings.dataUnit = $0 }
                )) {
                    ForEach(DataUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }

                Picker("Orientation", selection: Binding(
                    get: { settings.orientation },
                    set: { settings.orientation = $0 }
                )) {
                    ForEach(MenuBarOrientation.allCases) { o in
                        Text(o.displayName).tag(o)
                    }
                }

                HStack {
                    Text("Separator")
                    Spacer()
                    TextField("·", text: $settings.separator)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }

                HStack {
                    Text("Font Size")
                    Spacer()
                    Slider(value: $settings.menuBarFontSize, in: 9...16, step: 1) {
                        Text("")
                    }
                    .frame(width: 120)
                    Text("\(Int(settings.menuBarFontSize))pt")
                        .font(.system(size: 11, design: .monospaced))
                        .frame(width: 30)
                }

                Toggle("Custom Text Color", isOn: $settings.menuBarUseCustomColor)

                if settings.menuBarUseCustomColor {
                    HStack {
                        Text("Color Hex")
                        Spacer()
                        TextField("#FFFFFF", text: $settings.menuBarColorHex)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(nsColor: NSColor(hex: settings.menuBarColorHex) ?? .white))
                            .frame(width: 20, height: 20)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray, lineWidth: 0.5))
                    }
                }
            }

            Section("System") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { newValue in
                        settings.launchAtLogin = newValue
                        LaunchAtLoginManager.setEnabled(newValue)
                    }
                ))
            }

            Section {
                HStack {
                    Spacer()
                    Button("Save & Refresh") {
                        viewModel.refresh(urlString: settings.subscriptionURL)
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 440, minHeight: 560)
    }
}
