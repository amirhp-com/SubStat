import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var viewModel: SubscriptionViewModel
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 12)

            if let info = viewModel.subscriptionInfo {
                // Data Usage
                dataSection(info: info)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                Divider()
                    .padding(.horizontal, 12)

                // Time
                timeSection(info: info)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            } else if viewModel.isLoading {
                loadingSection
                    .padding(24)
            } else if settings.subscriptionURL.isEmpty {
                emptyStateSection
                    .padding(24)
            } else if let error = viewModel.errorMessage {
                errorSection(message: error)
                    .padding(24)
            }

            Divider()
                .padding(.horizontal, 12)

            // Footer
            footerSection
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .frame(width: 280)
        .background(.ultraThinMaterial)
        .onAppear {
            viewModel.startRefreshing(settings: settings)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(settings.subscriptionName)
                    .font(.system(size: 14, weight: .semibold))
                Text("Updated \(viewModel.lastUpdatedText)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: {
                viewModel.refresh(urlString: settings.subscriptionURL)
            }) {
                Image(systemName: viewModel.isLoading ? "arrow.trianglehead.2.counterclockwise" : "arrow.clockwise")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                    .animation(viewModel.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
            }
            .buttonStyle(.plain)
        }
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
                valueColor: info.usageRatio > 0.85 ? .red : .green
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
                    valueColor: days < 5 ? .red : (days < 10 ? .orange : .primary)
                )
            }
            StatRowView(label: "Expires", value: info.formattedExpiryDate)
        }
    }

    // MARK: - States

    private var loadingSection: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading subscription data...")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyStateSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            Text("No subscription URL configured")
                .font(.system(size: 12, weight: .medium))
            Text("Open Settings to add your subscription URL")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func errorSection(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(.orange)
            Text("Failed to load data")
                .font(.system(size: 12, weight: .medium))
            Text(message)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Button(action: openSettings) {
                Label("Settings", systemImage: "gear")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)

            Spacer()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit", systemImage: "xmark.circle")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
    }

    private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        // Fallback for older macOS versions
        if #available(macOS 14.0, *) {
            // showSettingsWindow is available
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}
