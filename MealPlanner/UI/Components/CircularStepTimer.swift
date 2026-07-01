import SwiftUI

/// Круглый таймер для шага рецепта. Управляется снаружи: `progress` 0..1.
public struct CircularStepTimer: View {
    public let progress: Double
    public let remainingSeconds: Int
    public var lineWidth: CGFloat = 8

    public init(progress: Double, remainingSeconds: Int, lineWidth: CGFloat = 8) {
        self.progress = progress
        self.remainingSeconds = remainingSeconds
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.inkRaised, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(Color.plasma, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
            VStack(spacing: 2) {
                Text(timeString)
                    .font(.numeric)
                    .foregroundStyle(Color.inkText)
                Text("осталось")
                    .font(.captionM)
                    .foregroundStyle(Color.inkMuted)
            }
        }
    }

    private var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    CircularStepTimer(progress: 0.42, remainingSeconds: 154)
        .frame(width: 180, height: 180)
        .padding()
        .background(Color.inkCanvas)
}
