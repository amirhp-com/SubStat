import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let settings = AppSettings()
    private let viewModel = SubscriptionViewModel()
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "SubStat"
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self

        let contentView = PopoverContentView(
            viewModel: viewModel,
            settings: settings,
            onOpenSettings: { [weak self] in self?.openSettings() },
            onOpenAbout: { [weak self] in self?.openAbout() },
            onQuit: { NSApplication.shared.terminate(nil) }
        )
        let hostingController = NSHostingController(rootView: contentView)
        // Make the hosting view transparent so the popover's native vibrancy/blur shows through
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = CGColor.clear
        popover.contentViewController = hostingController

        viewModel.startRefreshing(settings: settings)

        viewModel.$subscriptionInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateMenuBarText() }
            .store(in: &cancellables)

        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.updateMenuBarText()
                }
            }
            .store(in: &cancellables)

        // Close popover when clicking outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func updateMenuBarText() {
        guard let button = statusItem.button else { return }
        let mode = settings.displayMode
        let unit = settings.dataUnit
        let sep = settings.separator
        let orientation = settings.orientation

        guard let info = viewModel.subscriptionInfo else {
            button.attributedTitle = NSAttributedString(string: "SubStat")
            return
        }

        let days = info.daysRemaining.map { "\($0)d" } ?? "??d"
        let data = ByteFormatter.formatCompact(info.remainingBytes, unit: unit)

        var text: String
        switch mode {
        case .daysAndGB:
            text = orientation == .vertical ? "\(days)\n\(data)" : "\(days)\(sep)\(data)"
        case .daysOnly:
            text = days
        case .gbOnly:
            text = data
        case .iconDaysAndGB:
            let icon = settings.menuBarIcon
            text = orientation == .vertical ? "\(icon)\(days)\n\(data)" : "\(icon)\(days)\(sep)\(data)"
        }

        let fontSize = CGFloat(settings.menuBarFontSize)
        let fontFamily = settings.menuBarFontFamily
        let font: NSFont
        if !fontFamily.isEmpty, let customFont = NSFont(name: fontFamily, size: fontSize) {
            font = customFont
        } else {
            font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .medium)
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        if orientation == .vertical {
            paragraphStyle.lineSpacing = -2
            paragraphStyle.minimumLineHeight = fontSize
            paragraphStyle.maximumLineHeight = fontSize + 1
        }

        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .baselineOffset: orientation == .vertical ? -1 : 0
        ]

        if settings.menuBarUseCustomColor {
            attrs[.foregroundColor] = settings.menuBarNSColor
        }

        button.attributedTitle = NSAttributedString(string: text, attributes: attrs)
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Settings Window

    func openSettings() {
        popover.performClose(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            if let window = settingsWindow, window.isVisible {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }

            let settingsView = SettingsWindowView(settings: settings, viewModel: viewModel)
            let hostingController = NSHostingController(rootView: settingsView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "SubStat Settings"
            window.setContentSize(NSSize(width: 460, height: 600))
            window.styleMask = [.titled, .closable]
            window.center()
            window.isReleasedWhenClosed = false
            window.level = .floating
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            settingsWindow = window
        }
    }

    // MARK: - About Window

    func openAbout() {
        popover.performClose(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            if let window = aboutWindow, window.isVisible {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }

            let aboutView = AboutWindowView()
            let hostingController = NSHostingController(rootView: aboutView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "About SubStat"
            window.setContentSize(NSSize(width: 340, height: 400))
            window.styleMask = [.titled, .closable]
            window.center()
            window.isReleasedWhenClosed = false
            window.level = .floating
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            aboutWindow = window
        }
    }
}
