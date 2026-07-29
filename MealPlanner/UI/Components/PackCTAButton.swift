import SwiftUI

/// Компактный CTA «Открыть пак» из дизайна Home: plasma-градиент,
/// caption DAILY PACK, stack-mark из трёх карт справа и pulseCta-glow 2.4s.
public struct PackCTAButton: View {
    public var onTap: () -> Void

    @State private var pulsing = false

    public init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                LinearGradient.plasmaCta
                radialGlow
                stackMark
                    .padding(.trailing, 22)
                    .padding(.top, 16)
                VStack(alignment: .leading, spacing: 4) {
                    MonoCaption("Daily Pack", size: 10, color: Color.inkText.opacity(0.85))
                    Text("Открыть пак")
                        .font(.system(size: 21, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.inkText)
                    Text("9 карточек · шанс ★ Legendary")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.inkText.opacity(0.85))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(
                color: Color.plasmaDeep.opacity(pulsing ? 0.65 : 0.35),
                radius: pulsing ? 22 : 12, x: 0, y: 8
            )
        }
        .pressScale()
        .onAppear {
            withAnimation(Motion.pulse) { pulsing = true }
        }
    }

    private var radialGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.plasma.opacity(0.45), .clear],
                    center: .center, startRadius: 0, endRadius: 70
                )
            )
            .frame(width: 140, height: 140)
            .offset(x: 20, y: -30)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .allowsHitTesting(false)
    }

    /// Stack-mark: три наклонённые карты — серая, plasma, золотая.
    private var stackMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.inkRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.inkMuted.opacity(0.5), lineWidth: 1)
                )
                .rotationEffect(.degrees(-10))
                .offset(x: -12, y: 6)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient.plasmaCta)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.plasma, lineWidth: 1)
                )
                .rotationEffect(.degrees(-4))
                .offset(x: -4, y: 2)
                .shadow(color: .black.opacity(0.4), radius: 6, y: 4)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient.legendaryFoil)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.rarityLegendary, lineWidth: 1.5)
                )
                .shadow(color: Color.rarityLegendary.opacity(0.55), radius: 9)
        }
        .frame(width: 56, height: 76)
    }
}

#Preview {
    PackCTAButton(onTap: {})
        .padding()
        .background(Color.inkCanvas)
}
