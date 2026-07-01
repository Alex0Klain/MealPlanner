import SwiftUI

/// Карточка блюда — full-bleed эмодзи + glass-chips. Состояния:
/// default / selected / inPlan управляются параметрами.
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
            ZStack(alignment: .topTrailing) {
                background
                content
                if isInPlan { inPlanBadge }
                if isSelected { selectionMark }
            }
            .frame(width: 109, height: 156)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(border)
            .offset(y: isSelected ? -6 : 0)
            .opacity(isInPlan ? 0.45 : 1)
            .saturation(isInPlan ? 0.5 : 1)
            .rarityGlow(dish.rarity)
            .animation(Motion.select, value: isSelected)
        }
        .buttonStyle(.plain)
        .pressScale()
    }

    private var background: some View {
        ZStack {
            Color.inkSurface
            LinearGradient(
                colors: [dish.cuisine.accentColor.opacity(0.35), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(dish.emoji)
                .font(.system(size: 48))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, Spacing.sm)
            Spacer(minLength: 0)
            Text(dish.name)
                .font(cardNameFont)
                .foregroundStyle(Color.inkText)
                .minimumScaleFactor(0.8)
                .lineLimit(2)
                .padding(.horizontal, Spacing.sm)
            HStack(spacing: Spacing.xs) {
                Text("\(dish.calories) ккал")
                Text("·")
                Text("\(dish.proteinGrams)g")
            }
            .font(.captionM)
            .foregroundStyle(Color.inkMuted)
            .padding(.horizontal, Spacing.sm)
            .padding(.bottom, Spacing.sm)
        }
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
            .stroke(borderStyle, lineWidth: isSelected ? 2 : 1)
    }

    private var borderStyle: Color {
        isSelected ? .plasma : dish.rarity.borderColor
    }

    private var cardNameFont: Font {
        switch dish.rarity {
        case .common:    .cardName
        case .rare:      .cardNameRare
        case .legendary: .cardNameLegen
        }
    }

    private var selectionMark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(Color.plasma)
            .padding(Spacing.xs)
    }

    private var inPlanBadge: some View {
        Text("В ПЛАНЕ")
            .font(.captionM)
            .foregroundStyle(Color.inkText)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Capsule().fill(.ultraThinMaterial))
            .padding(Spacing.xs)
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        DishCard(dish: Dish.previewCatalog[0])
        DishCard(dish: Dish.previewCatalog[1], isSelected: true)
        DishCard(dish: Dish.previewCatalog[2], isInPlan: true)
    }
    .padding()
    .background(Color.inkCanvas)
}
