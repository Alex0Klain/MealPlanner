import ComposableArchitecture
import SwiftUI

public struct AddMealSlotView: View {
    @Bindable public var store: StoreOf<AddMealSlotFeature>

    public init(store: StoreOf<AddMealSlotFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.inkCanvas.ignoresSafeArea()
                VStack(spacing: Spacing.lg) {
                    slotPicker
                    dishList
                }
                .padding(Spacing.lg)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Отмена") { store.send(.cancelTapped) }
                        .foregroundStyle(Color.plasma)
                }
            }
            .navigationTitle("Добавить блюдо")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { store.send(.onAppear) }
    }

    private var slotPicker: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(MealSlot.displayOrder) { slot in
                Button {
                    store.send(.slotChanged(slot))
                } label: {
                    Text(slot.displayName)
                        .font(.captionM)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            Capsule().fill(
                                store.selectedSlot == slot
                                ? slot.accentColor.opacity(0.4)
                                : Color.inkSurface
                            )
                        )
                        .foregroundStyle(Color.inkText)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dishList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(store.availableDishes) { dish in
                    Button {
                        store.send(.dishTapped(dish))
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Text(dish.emoji).font(.title)
                            VStack(alignment: .leading) {
                                Text(dish.name)
                                    .font(.cardName)
                                    .foregroundStyle(Color.inkText)
                                HStack(spacing: Spacing.xs) {
                                    CuisineChip(cuisine: dish.cuisine)
                                    RarityBadge(rarity: dish.rarity)
                                }
                            }
                            Spacer()
                        }
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.slot)
                                .fill(Color.inkSurface)
                        )
                    }
                    .buttonStyle(.plain)
                    .pressScale()
                }
            }
        }
    }
}

#Preview {
    AddMealSlotView(
        store: Store(initialState: AddMealSlotFeature.State(date: .now)) {
            AddMealSlotFeature()
        }
    )
}
