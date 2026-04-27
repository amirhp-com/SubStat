import SwiftUI

struct RefreshButton: View {
    let isLoading: Bool
    let action: () -> Void
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .rotationEffect(.degrees(rotation))
            .frame(width: 28, height: 28)
            .background(Color.primary.opacity(0.001))
            .onTapGesture(perform: action)
            .onChange(of: isLoading) { loading in
                if loading {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                } else {
                    withAnimation(.default) {
                        rotation = 0
                    }
                }
            }
    }
}

struct PopoverContentView: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @ObservedObject var settings: AppSettings
    var onOpenSettings: () -> Void
    var onOpenAbout: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.subscriptionName)
                        .font(.system(size: 14, weight: .semibold))
                    Text("Updated \(viewModel.lastUpdatedText)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
                RefreshButton(isLoading: viewModel.isLoading) {
                    viewModel.refresh(urlString: settings.subscriptionURL)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 12)

            if let info = viewModel.subscriptionInfo {
                dataSection(info: info)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                Divider()
                    .padding(.horizontal, 12)

                timeSection(info: info)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            } else if viewModel.isLoading {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading subscription data...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            } else if settings.subscriptionURL.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No Subscription URL")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Add your VLESS subscription URL\nin Settings to start monitoring.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Open Settings")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .cornerRadius(6)
                        .onTapGesture(perform: onOpenSettings)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    Text("Failed to load data")
                        .font(.system(size: 13, weight: .semibold))
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                    if let detail = viewModel.errorDetail {
                        Text(detail)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 8)
                    }
                    Text("Check Settings")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(5)
                        .onTapGesture(perform: onOpenSettings)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            }

            Divider()
                .padding(.horizontal, 12)

            // Footer buttons
            HStack(spacing: 8) {
                footerBtn(icon: "gear", label: "Settings", action: onOpenSettings)
                footerBtn(icon: "info.circle", label: "About", action: onOpenAbout)
                footerBtn(icon: "xmark.circle", label: "Quit", action: onQuit)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // App info footer
            HStack(spacing: 6) {
                HStack(spacing: 0) {
                    Text(AppConstants.appName)
                        .fontWeight(.semibold)
                    Text(" v\(AppConstants.appVersion)")
                }
                Text("·").opacity(0.6)
                HStack(spacing: 0) {
                    Text("by ")
                    Text(AppConstants.developer)
                        .foregroundColor(.accentColor)
                        .onTapGesture {
                            NSWorkspace.shared.open(URL(string: AppConstants.websiteURL)!)
                        }
                        .onHover { h in
                            if h { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }
                }
                Text("·").opacity(0.6)
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 9))
                    Text("GitHub")
                }
                .foregroundColor(.accentColor)
                .onTapGesture {
                    NSWorkspace.shared.open(URL(string: AppConstants.githubURL)!)
                }
                .onHover { h in
                    if h { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .padding(.bottom, 10)
        }
        .frame(width: 320)
    }

    // MARK: - Data Section

    private func dataSection(info: SubscriptionInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DATA USAGE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(info.usageRatio * 100))%")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            ProgressBarView(value: info.usageRatio)

            StatRowView(label: "Total", value: info.totalDisplay)
            StatRowView(label: "Downloaded", value: info.downloadDisplay)
            StatRowView(label: "Uploaded", value: info.uploadDisplay)
            StatRowView(label: "Used", value: info.usedDisplay)
            StatRowView(
                label: "Remaining",
                value: info.remainedDisplay,
                valueColor: usageColor(ratio: info.usageRatio)
            )
        }
    }

    // MARK: - Time Section

    private func timeSection(info: SubscriptionInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TIME")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                if let days = info.daysRemaining {
                    Text("\(days) days left")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            ProgressBarView(value: info.timeRatio)

            if let days = info.daysRemaining {
                StatRowView(
                    label: "Days Remaining",
                    value: "\(days)",
                    valueColor: daysColor(days: days)
                )
            }
            StatRowView(label: "Expires", value: info.formattedExpiryDate)
        }
    }

    // MARK: - Footer Button

    private func footerBtn(icon: String, label: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label)
        }
        .font(.system(size: 11))
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.001))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
        .cornerRadius(6)
        .onTapGesture(perform: action)
    }

    // MARK: - Color Helpers

    private func usageColor(ratio: Double) -> Color {
        if ratio > 0.85 { return Color(red: 0.9, green: 0.2, blue: 0.15) }
        if ratio > 0.6 { return .orange }
        return Color(red: 0.2, green: 0.7, blue: 1.0)
    }

    private func daysColor(days: Int) -> Color {
        if days < 5 { return Color(red: 0.9, green: 0.2, blue: 0.15) }
        if days < 15 { return .orange }
        return Color(red: 0.2, green: 0.7, blue: 1.0)
    }
}
