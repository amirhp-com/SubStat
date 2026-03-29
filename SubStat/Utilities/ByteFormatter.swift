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

    static func formatCompact(_ bytes: Int64) -> String {
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
