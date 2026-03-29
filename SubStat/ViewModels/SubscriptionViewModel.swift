import Foundation
import Combine
import SwiftUI

class SubscriptionViewModel: ObservableObject {
    @Published var subscriptionInfo: SubscriptionInfo?
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var errorDetail: String?

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

        if !settings.subscriptionURL.isEmpty {
            refresh(urlString: settings.subscriptionURL)
        }
    }

    func refresh(urlString: String) {
        guard !urlString.isEmpty else {
            errorMessage = "No subscription URL configured"
            errorDetail = nil
            return
        }

        isLoading = true
        errorMessage = nil
        errorDetail = nil

        Task { @MainActor in
            do {
                let info = try await service.fetch(urlString: urlString)
                self.subscriptionInfo = info
                self.lastUpdated = Date()
                self.errorMessage = nil
                self.errorDetail = nil
            } catch let error as SubscriptionError {
                self.errorMessage = error.errorDescription
                switch error {
                case .networkError(let underlying):
                    let nsError = underlying as NSError
                    self.errorDetail = "[\(nsError.domain) \(nsError.code)] \(nsError.localizedDescription)"
                case .noDataFound:
                    self.errorDetail = "No Subscription-Userinfo header or HTML template found. Make sure the URL is a valid X-UI/3X-UI subscription link."
                case .parsingFailed:
                    self.errorDetail = "Found subscription data but could not parse it."
                case .invalidURL:
                    self.errorDetail = "The URL format is invalid. It should start with http:// or https://"
                }
            } catch {
                self.errorMessage = "Unexpected error"
                self.errorDetail = "\(error)"
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
