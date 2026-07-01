import SwiftUI

public struct EmptySlotView: View {
    public let slot: MealSlot
    public var onAdd: () -> Void = {}

    public init(slot: MealSlot, onAdd: @escaping () -> Void = {}) {
        self.slot = slot
        self.onAdd = onAdd
    }

    public var body: some View {
        Button(action: onAdd) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(slot.accentColor)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(slot.displayName)
                        .font(.cardName)
                        .foregroundStyle(Color.inkText)
                    Text("Добавить блюдо")
                        .font(.captionM)
                        .foregroundStyle(Color.inkMuted)
                }
                Spacer()
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .foregroundStyle(slot.accentColor.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
        .pressScale()
    }
}

#Preview {
    VStack(spacing: Spacing.sm) {
        ForEach(MealSlot.displayOrder) { slot in
            EmptySlotView(slot: slot)
        }
    }
    .padding()
    .background(Color.inkCanvas)
}
