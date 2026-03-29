import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        switch settings.displayMode {
        case .daysAndGB:
            Text(viewModel.menuBarText)
        case .daysOnly:
            Text(viewModel.daysText)
        case .gbOnly:
            Text(viewModel.gbText)
        case .iconDaysAndGB:
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down.circle")
                Text(viewModel.menuBarText)
            }
        }
    }
}
