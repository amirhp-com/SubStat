import Foundation
import Combine

class RefreshScheduler: ObservableObject {
    private var timer: AnyCancellable?
    private var onRefresh: (() -> Void)?

    func start(interval: RefreshInterval, onRefresh: @escaping () -> Void) {
        self.onRefresh = onRefresh
        stop()

        guard interval != .manual, interval.rawValue > 0 else { return }

        timer = Timer.publish(every: TimeInterval(interval.rawValue), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.onRefresh?()
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func refreshNow() {
        onRefresh?()
    }

    deinit {
        stop()
    }
}
