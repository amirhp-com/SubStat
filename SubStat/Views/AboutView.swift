import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
                .cornerRadius(14)

            // App Name
            Text(AppConstants.appName)
                .font(.system(size: 22, weight: .bold))

            Text("Version \(AppConstants.appVersion) (\(AppConstants.buildNumber))")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Text("Monitor your VLESS subscription usage\nright from the macOS menubar.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Divider()
                .frame(width: 200)

            VStack(spacing: 6) {
                Text("Developed by \(AppConstants.developer)")
                    .font(.system(size: 12, weight: .medium))

                Link("View on GitHub", destination: URL(string: AppConstants.githubURL)!)
                    .font(.system(size: 11))

                Text(AppConstants.license)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
