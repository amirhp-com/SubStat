import Foundation

struct SubscriptionInfo: Equatable {
    let downloadBytes: Int64
    let uploadBytes: Int64
    let totalBytes: Int64
    let expire: Int64
    let downloadDisplay: String
    let uploadDisplay: String
    let usedDisplay: String
    let totalDisplay: String
    let remainedDisplay: String

    var usedBytes: Int64 {
        downloadBytes + uploadBytes
    }

    var remainingBytes: Int64 {
        max(totalBytes - usedBytes, 0)
    }

    var usageRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }

    var expiryDate: Date? {
        guard expire > 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(expire))
    }

    var daysRemaining: Int? {
        guard let expiryDate = expiryDate else { return nil }
        let components = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate)
        return max(components.day ?? 0, 0)
    }

    var timeRatio: Double {
        guard let expiryDate = expiryDate else { return 0 }
        let now = Date()
        guard expiryDate > now else { return 1.0 }
        let totalDuration: TimeInterval = 30 * 24 * 3600
        let remaining = expiryDate.timeIntervalSince(now)
        let elapsed = totalDuration - remaining
        guard totalDuration > 0 else { return 0 }
        return min(max(elapsed / totalDuration, 0), 1.0)
    }

    var formattedExpiryDate: String {
        guard let date = expiryDate else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    var remainingGBText: String {
        ByteFormatter.format(remainingBytes)
    }
}
