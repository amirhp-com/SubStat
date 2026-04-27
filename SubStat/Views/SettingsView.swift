import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var viewModel: SubscriptionViewModel
    @State private var showRestoreAlert = false
    @State private var selectedColor: Color = .white
    @State private var showSavedNotification = false
    @State private var resolverStatus: String = ""
    @State private var resolverIsError: Bool = false
    @State private var resolverInProgress: Bool = false

    var body: some View {
        ZStack {
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
                        ForEach(MenuBarDisplayMode.pickerCases) { mode in
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
                        TextField("", text: $settings.separator)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        Button(action: { settings.separator = " · " }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Reset to default")
                    }
                }

                Section("Menubar Icon") {
                    HStack {
                        Text("Icon")
                        Spacer()
                        TextField("", text: $settings.menuBarIcon)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        Button("Reset") { settings.menuBarIcon = "⚡" }
                            .controlSize(.small)
                    }

                    HStack(alignment: .center) {
                        Text("Quick Pick")
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(["⚡", "🔒", "📡", "🌐", "🛜", "▲", "◆", "●"], id: \.self) { emoji in
                                Text(emoji)
                                    .font(.system(size: 14))
                                    .frame(width: 26, height: 26)
                                    .background(settings.menuBarIcon == emoji ? Color.accentColor.opacity(0.3) : Color.clear)
                                    .cornerRadius(4)
                                    .onTapGesture { settings.menuBarIcon = emoji }
                            }
                        }
                    }
                    .frame(height: 28)
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

                Section("IP Resolver (VPN Bypass)") {
                    Toggle("Enable Manual IP Resolver", isOn: $settings.enableIPResolver)

                    if settings.enableIPResolver {
                        let host = IPResolverService.extractHost(from: settings.subscriptionURL) ?? "—"

                        HStack {
                            Text("Site host")
                            Spacer()
                            Text(host)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }

                        HStack {
                            Text("Site IP")
                            Spacer()
                            TextField("e.g. 2.145.24.35", text: $settings.manualSiteIP)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 180)
                        }

                        HStack {
                            Text("Gateway IP")
                            Spacer()
                            TextField("Auto-detect", text: $settings.manualGatewayIP)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 180)
                            Button(action: {
                                if let gw = IPResolverService.detectGateway() {
                                    settings.manualGatewayIP = gw
                                    resolverStatus = "Detected gateway: \(gw)"
                                    resolverIsError = false
                                } else {
                                    resolverStatus = "Could not detect gateway. Enter one manually."
                                    resolverIsError = true
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Auto-detect default gateway")
                        }

                        Text("Modifies /etc/hosts and adds a host route through the local gateway. macOS will prompt for your administrator password.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack {
                            Button("Apply Resolver") {
                                applyIPResolver(host: host)
                            }
                            .disabled(resolverInProgress || host == "—" || settings.manualSiteIP.isEmpty)

                            Button("Remove Resolver") {
                                removeIPResolver()
                            }
                            .disabled(resolverInProgress || settings.ipResolverLastHost.isEmpty)

                            Spacer()
                        }

                        if !resolverStatus.isEmpty {
                            Text(resolverStatus)
                                .font(.system(size: 10))
                                .foregroundColor(resolverIsError ? .red : .green)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Section {
                    HStack {
                        Button("Restore Defaults") {
                            showRestoreAlert = true
                        }

                        Spacer()

                        Button("Save & Refresh") {
                            viewModel.refresh(urlString: settings.subscriptionURL)
                            withAnimation {
                                showSavedNotification = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showSavedNotification = false
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .formStyle(.grouped)

            // Save notification toast
            if showSavedNotification {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Settings saved & data refreshed")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .padding(.bottom, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(minWidth: 460, minHeight: 680)
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

    private func applyIPResolver(host: String) {
        guard host != "—" else {
            resolverStatus = "Could not extract host from subscription URL."
            resolverIsError = true
            return
        }
        var gateway = settings.manualGatewayIP.trimmingCharacters(in: .whitespaces)
        if gateway.isEmpty {
            if let auto = IPResolverService.detectGateway() {
                gateway = auto
                settings.manualGatewayIP = auto
            } else {
                resolverStatus = "No gateway detected. Enter one manually."
                resolverIsError = true
                return
            }
        }
        let ip = settings.manualSiteIP.trimmingCharacters(in: .whitespaces)
        resolverInProgress = true
        resolverStatus = "Applying…"
        resolverIsError = false
        IPResolverService.apply(host: host, ip: ip, gateway: gateway) { result in
            resolverInProgress = false
            switch result {
            case .success:
                settings.ipResolverLastHost = host
                resolverStatus = "Applied · \(host) → \(ip) via \(gateway)"
                resolverIsError = false
            case .failure(let error):
                resolverStatus = error.localizedDescription
                resolverIsError = true
            }
        }
    }

    private func removeIPResolver() {
        let host = settings.ipResolverLastHost
        guard !host.isEmpty else { return }
        resolverInProgress = true
        resolverStatus = "Removing…"
        resolverIsError = false
        IPResolverService.remove(host: host) { result in
            resolverInProgress = false
            switch result {
            case .success:
                settings.ipResolverLastHost = ""
                resolverStatus = "Removed."
                resolverIsError = false
            case .failure(let error):
                resolverStatus = error.localizedDescription
                resolverIsError = true
            }
        }
    }

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
        let mode = settings.displayMode
        let useIcon = mode == .iconDaysAndGB || mode == .iconDays || mode == .iconGB || mode == .iconGBAndDays
        let icon = useIcon ? settings.menuBarIcon : ""
        return settings.orientation == .vertical ? "\(icon)12d\n4.72GB" : "\(icon)12d\(sep)4.72GB"
    }

    private var previewFont: Font {
        let size = CGFloat(settings.menuBarFontSize)
        if !settings.menuBarFontFamily.isEmpty {
            return .custom(settings.menuBarFontFamily, size: size)
        }
        return .system(size: size, weight: .medium, design: .monospaced)
    }
}
