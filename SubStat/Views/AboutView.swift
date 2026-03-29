import SwiftUI

struct AboutWindowView: View {
    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
                .cornerRadius(14)

            Text(AppConstants.appName)
                .font(.system(size: 22, weight: .bold))

            Text("Version \(AppConstants.appVersion) (\(AppConstants.buildNumber))")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Text("A lightweight native macOS menubar utility\nthat keeps you informed about your VLESS\nsubscription usage, data limits, and expiry\n— all at a glance, right from the menubar.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Divider()
                .frame(width: 220)

            HStack(spacing: 4) {
                Text("Developed by")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("AmirhpCom")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .onTapGesture {
                        NSWorkspace.shared.open(URL(string: AppConstants.websiteURL)!)
                    }
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
            }

            HStack(spacing: 4) {
                Image(systemName: "link")
                Text("View Source on GitHub")
            }
            .font(.system(size: 11))
            .foregroundColor(.accentColor)
            .onTapGesture {
                NSWorkspace.shared.open(URL(string: AppConstants.githubURL)!)
            }
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            Text(AppConstants.license)
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(minWidth: 320, minHeight: 340)
        .padding()
        .focusable(false)
    }
}
