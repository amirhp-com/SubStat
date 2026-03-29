import Foundation

enum AppConstants {
    static let appName = "SubStat"
    static let developer = "AmirhpCom"
    static let githubURL = "https://github.com/AmirhpCom/SubStat"
    static let license = "MIT License"

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
