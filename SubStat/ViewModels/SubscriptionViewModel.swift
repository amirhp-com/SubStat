import Foundation
import Combine
import SwiftUI

class SubscriptionViewModel: ObservableObject {
    @Published var subscriptionInfo: SubscriptionInfo?
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = SubscriptionService.shared
    private let scheduler = RefreshScheduler()
    private var cancellables = Set<AnyCancellable>()

    var menuBarText: String {
        guard let info = subscriptionInfo else { return "SubStat" }
        let days = info.daysRemaining.map { "\($0)d" } ?? "??d"
        let gb = ByteFormatter.formatCompact(info.remainingBytes)
        return "\(days) · \(gb)"
    }

    var daysText: String {
        guard let info = subscriptionInfo else { return "--d" }
        return info.daysRemaining.map { "\($0)d" } ?? "??d"
    }

    var gbText: String {
        guard let info = subscriptionInfo else { return "--" }
        return ByteFormatter.formatCompact(info.remainingBytes)
    }

    var lastUpdatedText: String {
        guard let date = lastUpdated else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func startRefreshing(settings: AppSettings) {
        // Watch for settings changes
        settings.objectWillChange
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.configureScheduler(settings: settings)
                if !settings.subscriptionURL.isEmpty {
                    self?.refresh(urlString: settings.subscriptionURL)
                }
            }
            .store(in: &cancellables)

        configureScheduler(settings: settings)

        // Initial fetch
        if !settings.subscriptionURL.isEmpty {
            refresh(urlString: settings.subscriptionURL)
        }
    }

    func refresh(urlString: String) {
        guard !urlString.isEmpty else {
            errorMessage = "No subscription URL configured"
            return
        }

        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let info = try await service.fetch(urlString: urlString)
                self.subscriptionInfo = info
                self.lastUpdated = Date()
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    private func configureScheduler(settings: AppSettings) {
        scheduler.start(interval: settings.refreshInterval) { [weak self] in
            self?.refresh(urlString: settings.subscriptionURL)
        }
    }
}
