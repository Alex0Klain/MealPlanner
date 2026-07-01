import SwiftUI

/// Glow вокруг карточки в зависимости от редкости.
/// Common — без свечения; Rare — синий пульс; Legendary — золотое сияние.
public struct RarityGlowModifier: ViewModifier {
    public let rarity: Rarity

    @State private var pulse = false

    public func body(content: Content) -> some View {
        content
            .shadow(color: glowColor.opacity(pulse ? 0.7 : 0.35),
                    radius: glowRadius,
                    x: 0, y: 0)
            .onAppear {
                guard rarity != .common else { return }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }

    private var glowColor: Color {
        switch rarity {
        case .common:    .clear
        case .rare:      .rarityRare
        case .legendary: .rarityLegendary
        }
    }

    private var glowRadius: CGFloat {
        switch rarity {
        case .common:    0
        case .rare:      14
        case .legendary: 22
        }
    }
}

extension View {
    public func rarityGlow(_ rarity: Rarity) -> some View {
        modifier(RarityGlowModifier(rarity: rarity))
    }
}
