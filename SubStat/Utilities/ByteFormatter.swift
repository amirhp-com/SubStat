import Foundation

struct ByteFormatter {
    static func format(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useTB]
        formatter.countStyle = .binary
        formatter.includesUnit = true
        formatter.includesCount = true
        return formatter.string(fromByteCount: bytes)
    }

    static func formatCompact(_ bytes: Int64, unit: DataUnit = .auto) -> String {
        switch unit {
        case .mb:
            let mb = Double(bytes) / (1024 * 1024)
            if mb >= 1000 {
                return String(format: "%.0fMB", mb)
            } else if mb >= 100 {
                return String(format: "%.0fMB", mb)
            } else {
                return String(format: "%.1fMB", mb)
            }
        case .gb:
            let gb = Double(bytes) / (1024 * 1024 * 1024)
            if gb >= 100 {
                return String(format: "%.0fGB", gb)
            } else if gb >= 10 {
                return String(format: "%.1fGB", gb)
            } else {
                return String(format: "%.2fGB", gb)
            }
        case .gbz:
            let gb = Double(bytes) / (1024 * 1024 * 1024)
            return String(format: "%.3fG", gb)
        case .auto:
            let gb = Double(bytes) / (1024 * 1024 * 1024)
            if gb >= 1000 {
                return String(format: "%.1fTB", gb / 1024)
            } else if gb >= 100 {
                return String(format: "%.0fGB", gb)
            } else if gb >= 10 {
                return String(format: "%.1fGB", gb)
            } else if gb >= 1 {
                return String(format: "%.2fGB", gb)
            } else {
                let mb = Double(bytes) / (1024 * 1024)
                return String(format: "%.0fMB", mb)
            }
        }
    }
}
