import SwiftUI

/// Заполненный слот плана: иконка слота + блюдо.
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

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                slotBadge
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(slot.displayName)
                        .font(.captionM)
                        .foregroundStyle(slot.accentColor)
                    Text(dish.name)
                        .font(.cardName)
                        .foregroundStyle(Color.inkText)
                    HStack(spacing: Spacing.xs) {
                        Text("\(dish.cookTimeMinutes) мин")
                        Text("·")
                        Text("\(dish.calories) ккал")
                    }
                    .font(.captionM)
                    .foregroundStyle(Color.inkMuted)
                }
                Spacer()
                Text(dish.emoji).font(.title)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
                    .fill(Color.inkSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
                    .stroke(slot.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .pressScale()
        .contextMenu {
            Button(role: .destructive, action: onRemove) {
                Label("Убрать", systemImage: "trash")
            }
        }
    }

    private var slotBadge: some View {
        ZStack {
            Circle().fill(slot.accentColor.opacity(0.2))
            Text(slot.emoji).font(.title3)
        }
        .frame(width: 36, height: 36)
    }
}

#Preview {
    MealSlotRow(slot: .breakfast, dish: Dish.previewCatalog[0])
        .padding()
        .background(Color.inkCanvas)
}
