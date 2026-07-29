import SwiftUI

/// Рубашка карты: plasma-градиент, dashed-рамка, вилка по центру.
/// Размер задаёт контейнер (пропорция 7:10) — используется в flip-анимации reveal.
public struct CardBack: View {
    public init() {}

    public var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(LinearGradient.plasmaCta)
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(Color.inkText.opacity(0.4))
                    .padding(5)
            )
            .overlay(
                Text("🍴").font(.system(size: 34))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.plasma.opacity(0.7), lineWidth: 1)
            )
            .aspectRatio(7.0 / 10.0, contentMode: .fit)
    }
}

#Preview {
    CardBack()
        .frame(width: 109)
        .padding()
        .background(Color.inkCanvas)
}
