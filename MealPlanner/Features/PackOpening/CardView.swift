import SwiftUI

/// Карта пака: flip-волна rotation3DEffect Y 180°→0° со stagger 150ms.
/// Rare — диагональный holo sweep 400ms + haptic.light после переворота.
/// Legendary — KeyframeAnimator: scale 1.15 → spring 1.0 + золотое halo,
/// haptic.success.
public struct CardView: View {
    public let card: PackCard
    public var onTap: () -> Void = {}

    @State private var sweepProgress: CGFloat = 0
    @State private var legendaryTrigger = false

    public init(card: PackCard, onTap: @escaping () -> Void = {}) {
        self.card = card
        self.onTap = onTap
    }

    private var flipDelay: Double { Double(card.revealIndex) * Motion.stagger }

    public var body: some View {
        ZStack {
            CardBack()
                .rotation3DEffect(
                    .degrees(card.isRevealed ? -180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.6
                )
                .opacity(card.isRevealed ? 0 : 1)

            DishCard(
                dish: card.dish,
                isSelected: card.isSelected,
                isInPlan: card.isInPlan,
                onTap: onTap
            )
            .overlay(holoSweep)
            .rotation3DEffect(
                .degrees(card.isRevealed ? 0 : 180),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.6
            )
            .opacity(card.isRevealed ? 1 : 0)
        }
        .animation(Motion.flip.delay(flipDelay), value: card.isRevealed)
        .keyframeAnimator(
            initialValue: LegendaryBurstFrame(),
            trigger: legendaryTrigger
        ) { content, frame in
            content
                .scaleEffect(legendaryTrigger ? frame.scale : 1.0)
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.rarityLegendary.opacity(0.7), .clear],
                                center: .center, startRadius: 0, endRadius: 90
                            )
                        )
                        .scaleEffect(1.6)
                        .opacity(legendaryTrigger ? frame.haloOpacity : 0)
                        .allowsHitTesting(false)
                )
        } keyframes: { _ in
            KeyframeTrack(\.scale) {
                CubicKeyframe(1.15, duration: 0.25)
                SpringKeyframe(1.0, duration: 0.35)
            }
            KeyframeTrack(\.haloOpacity) {
                LinearKeyframe(1.0, duration: 0.2)
                LinearKeyframe(0.0, duration: 0.6)
            }
        }
        .onChange(of: card.isRevealed) { _, revealed in
            guard revealed else {
                sweepProgress = 0
                legendaryTrigger = false
                return
            }
            scheduleRevealEffects()
        }
    }

    /// Rare: блик по диагонали. Legendary: hold + halo + haptic.
    private func scheduleRevealEffects() {
        let afterFlip = flipDelay + 0.45
        switch card.dish.rarity {
        case .common:
            break
        case .rare:
            withAnimation(.linear(duration: 0.4).delay(afterFlip)) {
                sweepProgress = 1
            }
            Task {
                try? await Task.sleep(for: .seconds(afterFlip))
                Haptics.light()
            }
        case .legendary:
            Task {
                try? await Task.sleep(for: .seconds(afterFlip))
                legendaryTrigger = true
                Haptics.success()
            }
        }
    }

    @ViewBuilder
    private var holoSweep: some View {
        if card.dish.rarity == .rare {
            GeometryReader { proxy in
                let width = proxy.size.width
                LinearGradient(
                    colors: [.clear, Color.rarityRare.opacity(0.5), .white.opacity(0.35), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: width * 0.8)
                .offset(x: -width + sweepProgress * width * 2.4)
                .blendMode(.screen)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .allowsHitTesting(false)
        }
    }
}

private struct LegendaryBurstFrame {
    var scale: CGFloat = 1.0
    var haloOpacity: Double = 0.0
}

#Preview {
    HStack(spacing: 12) {
        CardView(card: PackCard(dish: Dish.previewCatalog[0], isRevealed: false, revealIndex: 0))
        CardView(card: PackCard(dish: Dish.previewCatalog[1], isRevealed: true, revealIndex: 1))
        CardView(card: PackCard(dish: Dish.previewCatalog[2], isRevealed: true, revealIndex: 2))
    }
    .frame(height: 170)
    .padding()
    .background(Color.inkCanvas)
}
