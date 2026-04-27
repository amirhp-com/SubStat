import Foundation

enum IPResolverError: LocalizedError {
    case noHost
    case invalidHost
    case noIP
    case invalidIP
    case noGateway
    case invalidGateway
    case userCancelled
    case scriptFailed(String)

    var errorDescription: String? {
        switch self {
        case .noHost: return "Subscription URL has no resolvable host."
        case .invalidHost: return "Host name contains invalid characters."
        case .noIP: return "Site IP is empty."
        case .invalidIP: return "Site IP is not a valid IPv4 address."
        case .noGateway: return "Could not detect default gateway. Enter it manually."
        case .invalidGateway: return "Gateway is not a valid IPv4 address."
        case .userCancelled: return "Cancelled."
        case .scriptFailed(let msg): return msg
        }
    }
}

enum IPResolverService {
    static let hostsMarker = "# SubStat-IPResolver"

    static func extractHost(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              let host = url.host,
              !host.isEmpty else { return nil }
        return host
    }

    static func detectGateway() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/sbin/route")
        task.arguments = ["-n", "get", "default"]
        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardOutput = outPipe
        task.standardError = errPipe
        do {
            try task.run()
        } catch {
            return nil
        }
        task.waitUntilExit()
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }
        for rawLine in output.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.lowercased().hasPrefix("gateway:") {
                let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
                if parts.count == 2 {
                    let gw = parts[1].trimmingCharacters(in: .whitespaces)
                    if isValidIPv4(gw) { return gw }
                }
            }
        }
        return nil
    }

    static func apply(host: String,
                      ip: String,
                      gateway: String,
                      completion: @escaping (Result<Void, Error>) -> Void) {
        guard !host.isEmpty else { return completion(.failure(IPResolverError.noHost)) }
        guard isValidHost(host) else { return completion(.failure(IPResolverError.invalidHost)) }
        guard !ip.isEmpty else { return completion(.failure(IPResolverError.noIP)) }
        guard isValidIPv4(ip) else { return completion(.failure(IPResolverError.invalidIP)) }
        guard !gateway.isEmpty else { return completion(.failure(IPResolverError.noGateway)) }
        guard isValidIPv4(gateway) else { return completion(.failure(IPResolverError.invalidGateway)) }

        let removeHosts = "/usr/bin/sed -i '' '/\(hostsMarker)/d' /etc/hosts"
        let appendHost = "/bin/echo '\(ip) \(host) \(hostsMarker)' >> /etc/hosts"
        let deleteRoute = "/sbin/route -n delete \(host) >/dev/null 2>&1 || true"
        let addRoute = "/sbin/route -n add \(host) \(gateway)"
        let combined = "\(removeHosts) ; \(appendHost) ; \(deleteRoute) ; \(addRoute)"

        runWithAdmin(shell: combined, completion: completion)
    }

    static func remove(host: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !host.isEmpty else { return completion(.success(())) }
        guard isValidHost(host) else { return completion(.failure(IPResolverError.invalidHost)) }

        let removeHosts = "/usr/bin/sed -i '' '/\(hostsMarker)/d' /etc/hosts"
        let deleteRoute = "/sbin/route -n delete \(host) >/dev/null 2>&1 || true"
        let combined = "\(removeHosts) ; \(deleteRoute)"

        runWithAdmin(shell: combined, completion: completion)
    }

    static func isValidHost(_ s: String) -> Bool {
        guard !s.isEmpty, s.count <= 253 else { return false }
        return s.range(of: "^[A-Za-z0-9.-]+$", options: .regularExpression) != nil
    }

    static func isValidIPv4(_ s: String) -> Bool {
        let parts = s.split(separator: ".")
        guard parts.count == 4 else { return false }
        for p in parts {
            guard let n = Int(p), n >= 0, n <= 255, String(n) == String(p) else { return false }
        }
        return true
    }

    private static func runWithAdmin(shell: String,
                                     completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let escaped = shell
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            let appleScript = "do shell script \"\(escaped)\" with administrator privileges"
            guard let script = NSAppleScript(source: appleScript) else {
                DispatchQueue.main.async {
                    completion(.failure(IPResolverError.scriptFailed("Could not initialize AppleScript.")))
                }
                return
            }
            var errorInfo: NSDictionary?
            _ = script.executeAndReturnError(&errorInfo)
            DispatchQueue.main.async {
                if let errorInfo = errorInfo {
                    let code = errorInfo[NSAppleScript.errorNumber] as? Int ?? 0
                    if code == -128 {
                        completion(.failure(IPResolverError.userCancelled))
                    } else {
                        let msg = errorInfo[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error."
                        completion(.failure(IPResolverError.scriptFailed(msg)))
                    }
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}
