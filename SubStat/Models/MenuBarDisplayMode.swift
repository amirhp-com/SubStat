import Foundation

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case daysAndGB = "daysAndGB"
    case daysOnly = "daysOnly"
    case gbOnly = "gbOnly"
    case iconDaysAndGB = "iconDaysAndGB"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daysAndGB: return "Days + Data"
        case .daysOnly: return "Days only"
        case .gbOnly: return "Data only"
        case .iconDaysAndGB: return "Icon + Days + Data"
        }
    }
}

enum DataUnit: String, CaseIterable, Identifiable {
    case auto = "auto"
    case mb = "mb"
    case gb = "gb"
    case gbz = "gbz"  // 3 decimal places like 4.545G

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .mb: return "MB"
        case .gb: return "GB"
        case .gbz: return "GBz (4.545G)"
        }
    }
}

enum MenuBarOrientation: String, CaseIterable, Identifiable {
    case horizontal = "horizontal"
    case vertical = "vertical"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .horizontal: return "Horizontal"
        case .vertical: return "Vertical (stacked)"
        }
    }
}
