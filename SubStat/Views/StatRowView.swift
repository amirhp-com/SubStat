import SwiftUI

struct StatRowView: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .font(.system(size: 12))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 1)
    }
}
