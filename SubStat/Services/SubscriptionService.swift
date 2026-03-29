import Foundation

enum SubscriptionError: LocalizedError {
    case invalidURL
    case noDataFound
    case parsingFailed
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid subscription URL"
        case .noDataFound:
            return "No subscription data found"
        case .parsingFailed:
            return "Failed to parse subscription data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

class SubscriptionService: NSObject, URLSessionDelegate {

    static let shared = SubscriptionService()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private override init() {
        super.init()
    }

    // Allow self-signed certificates
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func fetch(urlString: String) async throws -> SubscriptionInfo {
        guard let url = URL(string: urlString) else {
            throw SubscriptionError.invalidURL
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 20
        request.setValue("Mozilla/5.0 (Macintosh) SubStat/1.0", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw SubscriptionError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionError.networkError(NSError(domain: "SubStat", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }

        // Method 1: Check Subscription-Userinfo header (most common for X-UI/3X-UI)
        if let headerValue = httpResponse.value(forHTTPHeaderField: "Subscription-Userinfo") ??
                             httpResponse.value(forHTTPHeaderField: "subscription-userinfo") {
            return try parseSubscriptionHeader(headerValue)
        }

        // Method 2: Check HTML body for <template id="subscription-data">
        if let html = String(data: data, encoding: .utf8) {
            if let info = try? parseHTML(html) {
                return info
            }
        }

        throw SubscriptionError.noDataFound
    }

    // MARK: - Parse Subscription-Userinfo header
    // Format: upload=XXX; download=XXX; total=XXX; expire=XXX

    func parseSubscriptionHeader(_ header: String) throws -> SubscriptionInfo {
        var values: [String: Int64] = [:]

        let parts = header.components(separatedBy: ";")
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            let kv = trimmed.components(separatedBy: "=")
            if kv.count == 2, let val = Int64(kv[1].trimmingCharacters(in: .whitespaces)) {
                values[kv[0].trimmingCharacters(in: .whitespaces).lowercased()] = val
            }
        }

        guard let download = values["download"],
              let upload = values["upload"],
              let total = values["total"] else {
            throw SubscriptionError.parsingFailed
        }

        let expire = values["expire"] ?? 0

        return SubscriptionInfo(
            downloadBytes: download,
            uploadBytes: upload,
            totalBytes: total,
            expire: expire,
            downloadDisplay: ByteFormatter.format(download),
            uploadDisplay: ByteFormatter.format(upload),
            usedDisplay: ByteFormatter.format(download + upload),
            totalDisplay: ByteFormatter.format(total),
            remainedDisplay: ByteFormatter.format(max(total - download - upload, 0))
        )
    }

    // MARK: - Parse HTML template (fallback)

    func parseHTML(_ html: String) throws -> SubscriptionInfo {
        guard let templateRange = html.range(of: #"<template\s+id\s*=\s*"subscription-data""#, options: .regularExpression) else {
            throw SubscriptionError.noDataFound
        }

        let startIndex = templateRange.lowerBound
        guard let endRange = html.range(of: ">", range: startIndex..<html.endIndex) else {
            throw SubscriptionError.parsingFailed
        }

        let templateTag = String(html[startIndex...endRange.lowerBound])
        let attributes = parseDataAttributes(from: templateTag)

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
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return result }
        let nsTag = tag as NSString
        let matches = regex.matches(in: tag, range: NSRange(location: 0, length: nsTag.length))
        for match in matches {
            if match.numberOfRanges == 3 {
                result[nsTag.substring(with: match.range(at: 1))] = nsTag.substring(with: match.range(at: 2))
            }
        }
        return result
    }
}
