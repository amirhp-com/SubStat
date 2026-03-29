import SwiftUI

struct ProgressBarView: View {
    let value: Double
    var height: CGFloat = 8

    private var clampedValue: Double {
        min(max(value, 0), 1)
    }

    private var barColor: LinearGradient {
        if clampedValue > 0.85 {
            return LinearGradient(colors: [Color(red: 0.9, green: 0.2, blue: 0.15), Color(red: 1.0, green: 0.3, blue: 0.2)], startPoint: .leading, endPoint: .trailing)
        } else if clampedValue > 0.6 {
            return LinearGradient(colors: [Color.orange, Color(red: 1.0, green: 0.6, blue: 0.1)], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [Color(red: 0.1, green: 0.4, blue: 0.8), Color(red: 0.2, green: 0.6, blue: 1.0)], startPoint: .leading, endPoint: .trailing)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))
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
