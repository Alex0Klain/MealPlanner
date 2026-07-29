import SwiftUI

/// Карточка блюда — Window-вариант из дизайна: full-bleed фон, glass-chips,
/// scrim под текстом. Состояния default / selected / inPlan.
/// Размер задаёт контейнер: карточка держит пропорцию 7:10.
public struct DishCard: View {
    public let dish: Dish
    public var isSelected: Bool = false
    public var isInPlan: Bool   = false
    public var onTap: () -> Void = {}

    public init(
        dish: Dish,
        isSelected: Bool = false,
        isInPlan: Bool = false,
        onTap: @escaping () -> Void = {}
    ) {
        self.dish = dish
        self.isSelected = isSelected
        self.isInPlan = isInPlan
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            ZStack {
                background
                scrim
                content
                overlayBadges
            }
            .aspectRatio(7.0 / 10.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(border)
            .offset(y: isSelected ? -6 : 0)
            .shadow(
                color: isSelected ? Color.plasma.opacity(0.5) : .clear,
                radius: isSelected ? 9 : 0, x: 0, y: isSelected ? 8 : 0
            )
            .opacity(isInPlan ? 0.45 : 1)
            .saturation(isInPlan ? 0.5 : 1)
            .rarityGlow(dish.rarity)
            .animation(Motion.select, value: isSelected)
        }
        .pressScale()
    }

    // MARK: layers

    private var background: some View {
        DishPhoto(dish: dish, emojiSize: 52)
    }

    /// Градиент затемнения сверху и снизу — читаемость chips и текста.
    private var scrim: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.30), location: 0),
                .init(color: .clear,               location: 0.28),
                .init(color: .clear,               location: 0.50),
                .init(color: .black.opacity(0.90), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 2) {
            Spacer(minLength: 0)
            cuisineMiniChip
            Text(dish.name)
                .font(.system(size: 12, weight: nameWeight, design: .rounded))
                .foregroundStyle(titleColor)
                .minimumScaleFactor(0.8)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            HStack(spacing: 5) {
                Text("⏱ \(dish.cookTimeMinutes)м")
                Text("🔥 \(dish.calories)")
            }
            .font(.mono(8, weight: .medium))
            .foregroundStyle(Color.inkText.opacity(0.9))
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var overlayBadges: some View {
        VStack {
            HStack(alignment: .top) {
                rarityLetterChip
                Spacer()
                if isSelected { selectionMark }
                if isInPlan { inPlanBadge }
            }
            Spacer()
        }
        .padding(5)
    }

    // MARK: chips

    private var rarityLetterChip: some View {
        Text(rarityLetter)
            .font(.mono(8))
            .kerning(1)
            .foregroundStyle(dish.rarity == .common ? Color.inkText : dish.rarity.borderColor)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().stroke(dish.rarity.borderColor.opacity(0.8), lineWidth: 1))
    }

    private var cuisineMiniChip: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(dish.cuisine.accentColor)
                .frame(width: 4, height: 4)
            Text(dish.cuisine.displayName.uppercased())
                .font(.mono(6, weight: .bold))
                .kerning(0.6)
                .lineLimit(1)
        }
        .foregroundStyle(dish.cuisine.accentColor)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().stroke(dish.cuisine.accentColor.opacity(0.55), lineWidth: 1))
    }

    private var selectionMark: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: 19, height: 19)
            .background(Circle().fill(Color.plasma))
            .shadow(color: Color.plasmaDeep.opacity(0.6), radius: 3, y: 2)
    }

    private var inPlanBadge: some View {
        Text("В ПЛАНЕ")
            .font(.mono(7))
            .kerning(0.8)
            .foregroundStyle(Color.inkText)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule().fill(.ultraThinMaterial))
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(
                isSelected ? Color.plasma : dish.rarity.borderColor,
                lineWidth: isSelected || dish.rarity != .common ? 2 : 1
            )
    }

    // MARK: helpers

    private var rarityLetter: String {
        switch dish.rarity {
        case .common:    "C"
        case .rare:      "R"
        case .legendary: "★ L"
        }
    }

    private var nameWeight: Font.Weight {
        switch dish.rarity {
        case .common:    .semibold
        case .rare:      .bold
        case .legendary: .heavy
        }
    }

    private var titleColor: Color {
        dish.rarity == .legendary ? .rarityLegendary : .inkText
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        DishCard(dish: Dish.previewCatalog[0])
        DishCard(dish: Dish.previewCatalog[1], isSelected: true)
        DishCard(dish: Dish.previewCatalog[2], isInPlan: true)
    }
    .frame(height: 170)
    .padding()
    .background(Color.inkCanvas)
}
