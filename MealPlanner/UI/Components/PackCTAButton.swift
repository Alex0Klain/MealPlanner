import SwiftUI

/// Компактный CTA «Открыть пак» из дизайна Home: высота ~96pt,
/// plasma-градиент, caption DAILY PACK, stack-mark из трёх карт справа.
/// Анимации из спеки: pulseCta-glow 2.4s loop + покачивание стопки ±1.2°.
public struct PackCTAButton: View {
    public var onTap: () -> Void

    @State private var pulsing = false

    public init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .trailing) {
                LinearGradient.plasmaCta
                radialGlow
                stackMark
                    .rotationEffect(.degrees(pulsing ? 1.2 : -1.2))
                    .padding(.trailing, 20)
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        MonoCaption("Daily Pack", size: 10, color: Color.inkText.opacity(0.85))
                        Text("Открыть пак")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.inkText)
                        Text("9 карточек · шанс ★ Legendary")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.inkText.opacity(0.85))
                    }
                    Spacer(minLength: 76)
                }
                .padding(.horizontal, 18)
            }
            .frame(height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.plasma.opacity(pulsing ? 0.9 : 0.4), lineWidth: 1)
            )
            .shadow(
                color: Color.plasmaDeep.opacity(pulsing ? 0.7 : 0.3),
                radius: pulsing ? 24 : 10, x: 0, y: 8
            )
        }
        .pressScale()
        .task {
            withAnimation(Motion.pulse) { pulsing = true }
        }
    }

    private var radialGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.plasma.opacity(0.5), .clear],
                    center: .center, startRadius: 0, endRadius: 70
                )
            )
            .frame(width: 140, height: 140)
            .scaleEffect(pulsing ? 1.15 : 0.9)
            .offset(x: 24, y: -28)
            .allowsHitTesting(false)
    }

    /// Stack-mark: три наклонённые карты — серая, plasma, золотая.
    private var stackMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.inkRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.inkMuted.opacity(0.5), lineWidth: 1)
                )
                .rotationEffect(.degrees(-10))
                .offset(x: -11, y: 5)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(LinearGradient.plasmaCta)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.plasma, lineWidth: 1)
                )
                .rotationEffect(.degrees(-4))
                .offset(x: -4, y: 2)
                .shadow(color: .black.opacity(0.4), radius: 5, y: 3)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(LinearGradient.legendaryFoil)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.rarityLegendary, lineWidth: 1.5)
                )
                .shadow(color: Color.rarityLegendary.opacity(0.55), radius: 8)
        }
        .frame(width: 50, height: 68)
    }
}

#Preview {
    PackCTAButton(onTap: {})
        .padding()
        .background(Color.inkCanvas)
}
