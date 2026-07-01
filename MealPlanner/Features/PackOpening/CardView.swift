import SwiftUI

/// Карта пака — обёртка над DishCard со встроенной flip-анимацией.
/// Полная анимация PhaseAnimator/KeyframeAnimator подключается в шаге 9 imp. order.
public struct CardView: View {
    public let card: PackCard
    public var onTap: () -> Void = {}

    public init(card: PackCard, onTap: @escaping () -> Void = {}) {
        self.card = card
        self.onTap = onTap
    }

    public var body: some View {
        ZStack {
            if card.isRevealed {
                DishCard(
                    dish: card.dish,
                    isSelected: card.isSelected,
                    isInPlan: card.isInPlan,
                    onTap: onTap
                )
                .transition(.scale.combined(with: .opacity))
            } else {
                CardBack()
                    .transition(.opacity)
            }
        }
        .animation(Motion.flip.delay(Double(card.revealIndex) * Motion.stagger), value: card.isRevealed)
    }
}

#Preview {
    HStack {
        CardView(card: PackCard(dish: Dish.previewCatalog[0], isRevealed: false, revealIndex: 0))
        CardView(card: PackCard(dish: Dish.previewCatalog[1], isRevealed: true, revealIndex: 1))
    }
    .padding()
    .background(Color.inkCanvas)
}
