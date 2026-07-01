import SwiftUI

/// Рубашка пака — стопка из 3 наклонённых карт.
public struct CardBack: View {
    public var size: CGSize = .init(width: 109, height: 156)

    public init(size: CGSize = .init(width: 109, height: 156)) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            backFace
                .rotationEffect(.degrees(-6))
                .offset(x: -8, y: 6)
                .opacity(0.6)
            backFace
                .rotationEffect(.degrees(4))
                .offset(x: 6, y: 2)
                .opacity(0.8)
            backFace
        }
        .frame(width: size.width + 24, height: size.height + 16)
    }

    private var backFace: some View {
        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
            .fill(LinearGradient.plasmaCta)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(Color.inkText.opacity(0.4))
                    .padding(6)
            )
            .overlay(
                Text("🍴")
                    .font(.system(size: 42))
            )
            .frame(width: size.width, height: size.height)
    }
}

#Preview {
    CardBack()
        .padding()
        .background(Color.inkCanvas)
}
