import SwiftUI

/// Пустой слот из дизайна: dashed-рамка, «+»-плитка 28×28,
/// caption слота и подсказка «Открой пак».
public struct EmptySlotView: View {
  public let slot: MealSlot
  public var onAdd: () -> Void = {}

  public init(slot: MealSlot, onAdd: @escaping () -> Void = {}) {
    self.slot = slot
    self.onAdd = onAdd
  }

  public var body: some View {
    Button(action: onAdd) {
      HStack(spacing: 10) {
        plusTile
        VStack(alignment: .leading, spacing: 2) {
          Text(slot.displayName.uppercased())
            .font(.mono(9))
            .kerning(1.1)
            .foregroundStyle(Color.inkMuted)
          Text("Открой пак")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.inkText.opacity(0.75))
        }
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .overlay(
        RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
          .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
          .foregroundStyle(Color.inkRaised)
      )
      .contentShape(RoundedRectangle(cornerRadius: Radius.slot, style: .continuous))
    }
    .pressScale()
  }

  private var plusTile: some View {
    Text("+")
      .font(.system(size: 15, weight: .semibold))
      .foregroundStyle(slot.accentColor)
      .frame(width: 28, height: 28)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(slot.accentColor.opacity(0.18))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
          .foregroundStyle(slot.accentColor.opacity(0.6))
      )
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
