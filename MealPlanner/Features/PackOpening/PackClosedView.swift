import SwiftUI

public struct PackClosedView: View {
    public var onTap: () -> Void = {}

    @State private var sway = false

    public init(onTap: @escaping () -> Void = {}) {
        self.onTap = onTap
    }

    public var body: some View {
        VStack(spacing: Spacing.xl) {
            Text("Открой пак на сегодня")
                .font(.display)
                .foregroundStyle(Color.inkText)
            Button(action: onTap) {
                CardBack(size: .init(width: 200, height: 280))
                    .rotationEffect(.degrees(sway ? 1.2 : -1.2))
                    .scaleEffect(sway ? 1.04 : 1.0)
            }
            .buttonStyle(.plain)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    sway = true
                }
            }
            Text("Карточки добавляются в твой план дня")
                .font(.bodyM)
                .foregroundStyle(Color.inkMuted)
        }
    }
}

#Preview {
    PackClosedView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.inkCanvas)
}
