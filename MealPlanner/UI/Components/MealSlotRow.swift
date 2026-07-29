import SwiftUI

/// Заполненный слот плана из дизайна Home: миниатюра 44×60, caption слота
/// с точкой, название, мета «⏱ · 🔥 · 💪», chevron. Rare/Legendary получают
/// цветной accent-bar слева, тонированный бордер и chip редкости.
public struct MealSlotRow: View {
    public let slot: MealSlot
    public let dish: Dish
    public var onTap: () -> Void = {}
    public var onRemove: () -> Void = {}

    public init(slot: MealSlot, dish: Dish, onTap: @escaping () -> Void = {}, onRemove: @escaping () -> Void = {}) {
        self.slot = slot
        self.dish = dish
        self.onTap = onTap
        self.onRemove = onRemove
    }

    private var isRareOrBetter: Bool { dish.rarity != .common }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                thumbnail
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        slotLabel
                        if isRareOrBetter { rarityChip }
                    }
                    Text(dish.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkText)
                        .lineLimit(1)
                    Text("⏱ \(dish.cookTimeMinutes)м · 🔥 \(dish.calories) · 💪 \(dish.proteinGrams)г")
                        .font(.mono(10, weight: .medium))
                        .foregroundStyle(metaColor)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.inkMuted)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground)
            .overlay(alignment: .leading) {
                if isRareOrBetter {
                    accentBar
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.slot, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .pressScale()
        .contextMenu {
            Button(role: .destructive, action: onRemove) {
                Label("Убрать", systemImage: "trash")
            }
        }
    }

    // MARK: pieces

    private var thumbnail: some View {
        ZStack {
            LinearGradient(
                colors: [dish.cuisine.accentColor.opacity(0.5), Color.inkBase],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(dish.emoji).font(.system(size: 24))
        }
        .frame(width: 44, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    isRareOrBetter ? dish.rarity.borderColor : Color.inkRaised,
                    lineWidth: isRareOrBetter ? 1.5 : 1
                )
        )
    }

    private var slotLabel: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(slot.accentColor)
                .frame(width: 4, height: 4)
            Text(slot.displayName.uppercased())
                .font(.mono(9))
                .kerning(1.1)
        }
        .foregroundStyle(Color.inkMuted)
    }

    private var rarityChip: some View {
        Text(dish.rarity == .legendary ? "★ LEGENDARY" : "RARE")
            .font(.mono(8))
            .kerning(1.1)
            .foregroundStyle(dish.rarity.borderColor)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(dish.rarity.borderColor.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(dish.rarity.borderColor.opacity(0.7), lineWidth: 1)
            )
    }

    private var accentBar: some View {
        Rectangle()
            .fill(dish.rarity.borderColor)
            .frame(width: 3)
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isRareOrBetter {
            LinearGradient(
                colors: [dish.rarity.borderColor.opacity(0.16), Color.inkSurface],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            Color.inkSurface
        }
    }

    private var metaColor: Color {
        isRareOrBetter ? dish.rarity.borderColor.opacity(0.9) : .inkMuted
    }

    private var borderColor: Color {
        isRareOrBetter ? dish.rarity.borderColor.opacity(0.55) : .inkRaised
    }
}

#Preview {
    VStack(spacing: Spacing.sm) {
        MealSlotRow(slot: .breakfast, dish: Dish.previewCatalog[0])
        MealSlotRow(slot: .lunch, dish: Dish.previewCatalog[1])
        MealSlotRow(slot: .dinner, dish: Dish.previewCatalog[2])
    }
    .padding()
    .background(Color.inkCanvas)
}
