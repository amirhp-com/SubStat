import Foundation

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case daysAndGB = "daysAndGB"
    case daysOnly = "daysOnly"
    case gbOnly = "gbOnly"
    case iconDaysAndGB = "iconDaysAndGB"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daysAndGB: return "Days + GB"
        case .daysOnly: return "Days only"
        case .gbOnly: return "GB only"
        case .iconDaysAndGB: return "Icon + Days + GB"
        }
    }
}
