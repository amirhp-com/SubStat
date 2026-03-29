import SwiftUI

struct ProgressBarView: View {
    let value: Double
    var color: Color = .blue
    var backgroundColor: Color = Color.gray.opacity(0.2)
    var height: CGFloat = 8

    private var clampedValue: Double {
        min(max(value, 0), 1)
    }

    private var barColor: LinearGradient {
        if clampedValue > 0.85 {
            return LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        } else if clampedValue > 0.7 {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [Color(nsColor: .systemTeal), Color(nsColor: .systemBlue)], startPoint: .leading, endPoint: .trailing)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)
                    .frame(height: height)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(barColor)
                    .frame(width: geometry.size.width * clampedValue, height: height)
                    .animation(.easeInOut(duration: 0.5), value: clampedValue)
            }
        }
        .frame(height: height)
    }
}
