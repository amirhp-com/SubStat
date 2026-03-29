import Foundation

enum SubscriptionError: LocalizedError {
    case invalidURL
    case templateNotFound
    case parsingFailed
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid subscription URL"
        case .templateNotFound:
            return "Subscription data not found in response"
        case .parsingFailed:
            return "Failed to parse subscription data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

class SubscriptionService {

    static let shared = SubscriptionService()
    private init() {}

    func fetch(urlString: String) async throws -> SubscriptionInfo {
        guard let url = URL(string: urlString) else {
            throw SubscriptionError.invalidURL
        }

        let data: Data
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 15
            let result = try await URLSession.shared.data(for: request)
            data = result.0
        } catch {
            throw SubscriptionError.networkError(error)
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw SubscriptionError.parsingFailed
        }

        // Also try subscription-userinfo header approach as fallback
        return try parseHTML(html)
    }

    func parseHTML(_ html: String) throws -> SubscriptionInfo {
        // Find <template id="subscription-data" ... >
        guard let templateRange = html.range(of: #"<template\s+id\s*=\s*"subscription-data""#, options: .regularExpression) else {
            throw SubscriptionError.templateNotFound
        }

        // Get the full template tag (up to the closing >)
        let startIndex = templateRange.lowerBound
        guard let endRange = html.range(of: ">", range: startIndex..<html.endIndex) else {
            throw SubscriptionError.parsingFailed
        }

        let templateTag = String(html[startIndex...endRange.lowerBound])

        // Extract all data-* attributes
        let attributes = parseDataAttributes(from: templateTag)

        // Build SubscriptionInfo
        guard let downloadByte = attributes["downloadbyte"].flatMap({ Int64($0) }),
              let uploadByte = attributes["uploadbyte"].flatMap({ Int64($0) }),
              let totalByte = attributes["totalbyte"].flatMap({ Int64($0) }),
              let expire = attributes["expire"].flatMap({ Int64($0) }) else {
            throw SubscriptionError.parsingFailed
        }

        return SubscriptionInfo(
            downloadBytes: downloadByte,
            uploadBytes: uploadByte,
            totalBytes: totalByte,
            expire: expire,
            downloadDisplay: attributes["download"] ?? ByteFormatter.format(downloadByte),
            uploadDisplay: attributes["upload"] ?? ByteFormatter.format(uploadByte),
            usedDisplay: attributes["used"] ?? ByteFormatter.format(downloadByte + uploadByte),
            totalDisplay: attributes["total"] ?? ByteFormatter.format(totalByte),
            remainedDisplay: attributes["remained"] ?? ByteFormatter.format(max(totalByte - downloadByte - uploadByte, 0))
        )
    }

    private func parseDataAttributes(from tag: String) -> [String: String] {
        var result: [String: String] = [:]

        let pattern = #"data-([\w-]+)\s*=\s*"([^"]*)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return result
        }

        let nsTag = tag as NSString
        let matches = regex.matches(in: tag, range: NSRange(location: 0, length: nsTag.length))

        for match in matches {
            if match.numberOfRanges == 3 {
                let key = nsTag.substring(with: match.range(at: 1))
                let value = nsTag.substring(with: match.range(at: 2))
                result[key] = value
            }
        }

        return result
    }
}
