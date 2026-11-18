import ComposableArchitecture
import SwiftUI

/// Bottom-sheet добавления блюда в слот (side flow A из дизайна):
/// grabber, заголовок, chips слотов, список блюд.
public struct AddMealSlotView: View {
    @Bindable public var store: StoreOf<AddMealSlotFeature>

    public init(store: StoreOf<AddMealSlotFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.inkCanvas.ignoresSafeArea()
            VStack(spacing: Spacing.md) {
                header
                slotPicker
                dishList
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.inkCanvas)
        .onAppear { store.send(.onAppear) }
    }

    private var header: some View {
        HStack {
            Text("Какой приём?")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.inkText)
            Spacer()
            Button("Отмена") { store.send(.cancelTapped) }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.plasma)
        }
    }

    private var slotPicker: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(MealSlot.displayOrder) { slot in
                Button {
                    Haptics.selection()
                    store.send(.slotChanged(slot), animation: .snappy)
                } label: {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(slot.accentColor)
                            .frame(width: 5, height: 5)
                        Text(slot.displayName)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            store.selectedSlot == slot
                            ? slot.accentColor.opacity(0.35)
                            : Color.inkSurface
                        )
                    )
                    .overlay(
                        Capsule().stroke(
                            store.selectedSlot == slot
                            ? slot.accentColor.opacity(0.8)
                            : Color.inkRaised,
                            lineWidth: 1
                        )
                    )
                    .foregroundStyle(Color.inkText)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dishList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(store.availableDishes) { dish in
                    dishRow(dish)
                }
            }
            .padding(.bottom, Spacing.lg)
        }
    }

    private func dishRow(_ dish: Dish) -> some View {
        Button {
            Haptics.success()
            store.send(.dishTapped(dish))
        } label: {
            HStack(spacing: 10) {
                DishPhoto(dish: dish, emojiSize: 20)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                dish.rarity == .common ? Color.inkRaised : dish.rarity.borderColor,
                                lineWidth: dish.rarity == .common ? 1 : 1.5
                            )
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(dish.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkText)
                        .lineLimit(1)
                    Text("⏱ \(dish.cookTimeMinutes)м · 🔥 \(dish.calories) · 💪 \(dish.proteinGrams)г")
                        .font(.mono(10, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.inkMuted)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
                    .fill(Color.inkSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
                    .stroke(Color.inkRaised, lineWidth: 1)
            )
        }
        .pressScale()
    }
}

#Preview {
    AddMealSlotView(
        store: Store(initialState: AddMealSlotFeature.State(date: .now)) {
            AddMealSlotFeature()
        } withDependencies: {
            $0.dishRepository = .preview
        }
    )
}
