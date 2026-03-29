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
    @AppStorage("subscriptionURL") var subscriptionURL: String = ""
    @AppStorage("subscriptionName") var subscriptionName: String = "My Subscription"
    @AppStorage("refreshIntervalRaw") var refreshIntervalRaw: Int = RefreshInterval.thirtyMinutes.rawValue
    @AppStorage("displayModeRaw") var displayModeRaw: String = MenuBarDisplayMode.daysAndGB.rawValue
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false

    var refreshInterval: RefreshInterval {
        get { RefreshInterval(rawValue: refreshIntervalRaw) ?? .thirtyMinutes }
        set { refreshIntervalRaw = newValue.rawValue }
    }

    var displayMode: MenuBarDisplayMode {
        get { MenuBarDisplayMode(rawValue: displayModeRaw) ?? .daysAndGB }
        set { displayModeRaw = newValue.rawValue }
    }
}
