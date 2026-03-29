import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var viewModel: SubscriptionViewModel
    @State private var showRestoreAlert = false
    @State private var selectedColor: Color = .white

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

            Section("Menubar Content") {
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
            }

            Section("Menubar Appearance") {
                HStack {
                    Text("Font")
                    Spacer()
                    Picker("", selection: $settings.menuBarFontFamily) {
                        Text("System Default").tag("")
                        ForEach(availableFonts, id: \.self) { fontName in
                            Text(fontName).font(.custom(fontName, size: 12)).tag(fontName)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }

                HStack {
                    Text("Font Size")
                    Spacer()
                    Slider(value: $settings.menuBarFontSize, in: 9...18, step: 1)
                        .frame(width: 130)
                    Text("\(Int(settings.menuBarFontSize))pt")
                        .font(.system(size: 11, design: .monospaced))
                        .frame(width: 32, alignment: .trailing)
                }

                Toggle("Custom Text Color", isOn: $settings.menuBarUseCustomColor)

                if settings.menuBarUseCustomColor {
                    HStack {
                        Text("Color")
                        Spacer()
                        ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                            .labelsHidden()
                            .onChange(of: selectedColor) { newColor in
                                settings.menuBarColor = newColor
                            }
                    }
                }

                // Preview
                HStack {
                    Text("Preview")
                    Spacer()
                    Text(previewText)
                        .font(previewFont)
                        .foregroundColor(settings.menuBarUseCustomColor ? settings.menuBarColor : .primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .cornerRadius(4)
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
                    Button("Restore Defaults") {
                        showRestoreAlert = true
                    }

                    Spacer()

                    Button("Save & Refresh") {
                        viewModel.refresh(urlString: settings.subscriptionURL)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 460, minHeight: 620)
        .onAppear {
            selectedColor = settings.menuBarColor
        }
        .alert("Restore Defaults?", isPresented: $showRestoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                settings.restoreDefaults()
                selectedColor = .white
            }
        } message: {
            Text("This will reset all settings to defaults. Your subscription URL and name will be kept.")
        }
    }

    // MARK: - Helpers

    private var availableFonts: [String] {
        let favorites = [
            "SF Mono", "Menlo", "Monaco", "Courier New",
            "Helvetica Neue", "Avenir", "Futura", "Gill Sans",
            "SF Pro Display", "SF Pro Text", "SF Pro Rounded"
        ]
        let allFonts = NSFontManager.shared.availableFontFamilies
        let existing = favorites.filter { allFonts.contains($0) }
        let others = allFonts.filter { !existing.contains($0) }.sorted()
        return existing + others
    }

    private var previewText: String {
        let sep = settings.separator
        return settings.orientation == .vertical ? "12d\n4.72GB" : "12d\(sep)4.72GB"
    }

    private var previewFont: Font {
        let size = CGFloat(settings.menuBarFontSize)
        if !settings.menuBarFontFamily.isEmpty {
            return .custom(settings.menuBarFontFamily, size: size)
        }
        return .system(size: size, weight: .medium, design: .monospaced)
    }
}
