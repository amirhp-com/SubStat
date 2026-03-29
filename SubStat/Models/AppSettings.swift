import Foundation
import SwiftUI

enum RefreshInterval: Int, CaseIterable, Identifiable {
    case tenMinutes = 600
    case thirtyMinutes = 1800
    case oneHour = 3600
    case manual = 0

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .tenMinutes: return "Every 10 minutes"
        case .thirtyMinutes: return "Every 30 minutes"
        case .oneHour: return "Every hour"
        case .manual: return "Manual only"
        }
    }
}

class AppSettings: ObservableObject {
    // Subscription
    @AppStorage("subscriptionURL") var subscriptionURL: String = ""
    @AppStorage("subscriptionName") var subscriptionName: String = "My Subscription"

    // Refresh
    @AppStorage("refreshIntervalRaw") var refreshIntervalRaw: Int = RefreshInterval.thirtyMinutes.rawValue

    // Display
    @AppStorage("displayModeRaw") var displayModeRaw: String = MenuBarDisplayMode.daysAndGB.rawValue
    @AppStorage("dataUnitRaw") var dataUnitRaw: String = DataUnit.auto.rawValue
    @AppStorage("separator") var separator: String = " · "
    @AppStorage("orientationRaw") var orientationRaw: String = MenuBarOrientation.horizontal.rawValue
    @AppStorage("menuBarIcon") var menuBarIcon: String = "⚡"

    // Menubar appearance
    @AppStorage("menuBarFontFamily") var menuBarFontFamily: String = ""  // empty = system default
    @AppStorage("menuBarFontSize") var menuBarFontSize: Double = 12
    @AppStorage("menuBarUseCustomColor") var menuBarUseCustomColor: Bool = false
    @AppStorage("menuBarColorR") var menuBarColorR: Double = 1.0
    @AppStorage("menuBarColorG") var menuBarColorG: Double = 1.0
    @AppStorage("menuBarColorB") var menuBarColorB: Double = 1.0

    // System
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false

    var refreshInterval: RefreshInterval {
        get { RefreshInterval(rawValue: refreshIntervalRaw) ?? .thirtyMinutes }
        set { refreshIntervalRaw = newValue.rawValue }
    }

    var displayMode: MenuBarDisplayMode {
        get { MenuBarDisplayMode(rawValue: displayModeRaw) ?? .daysAndGB }
        set { displayModeRaw = newValue.rawValue }
    }

    var dataUnit: DataUnit {
        get { DataUnit(rawValue: dataUnitRaw) ?? .auto }
        set { dataUnitRaw = newValue.rawValue }
    }

    var orientation: MenuBarOrientation {
        get { MenuBarOrientation(rawValue: orientationRaw) ?? .horizontal }
        set { orientationRaw = newValue.rawValue }
    }

    var menuBarColor: Color {
        get { Color(red: menuBarColorR, green: menuBarColorG, blue: menuBarColorB) }
        set {
            if let components = NSColor(newValue).cgColor.components, components.count >= 3 {
                menuBarColorR = Double(components[0])
                menuBarColorG = Double(components[1])
                menuBarColorB = Double(components[2])
            }
        }
    }

    var menuBarNSColor: NSColor {
        NSColor(red: menuBarColorR, green: menuBarColorG, blue: menuBarColorB, alpha: 1.0)
    }

    func restoreDefaults() {
        let domain = Bundle.main.bundleIdentifier ?? "com.amirhpcom.SubStat"
        let url = subscriptionURL
        let name = subscriptionName
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        // Keep subscription URL and name
        subscriptionURL = url
        subscriptionName = name
        objectWillChange.send()
    }
}
