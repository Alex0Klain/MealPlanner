import ComposableArchitecture
import SwiftUI

public struct DistributeView: View {
    @Bindable public var store: StoreOf<PackOpeningFeature>

    public init(store: StoreOf<PackOpeningFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Text("Разложи по слотам")
                    .font(.appTitle)
                    .foregroundStyle(Color.inkText)
                Spacer()
                Text("шаг 2 из 2")
                    .font(.captionM)
                    .foregroundStyle(Color.inkMuted)
            }
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(store.selectedCards) { card in
                        slotPicker(for: card)
                    }
                }
            }
            Button {
                store.send(.confirmDistributionTapped)
            } label: {
                Text("Добавить в план")
                    .font(.cardName)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(
                        store.canConfirmDistribution
                        ? AnyShapeStyle(LinearGradient.plasmaCta)
                        : AnyShapeStyle(Color.inkRaised)
                    )
                    .foregroundStyle(Color.inkText)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.button))
            }
            .disabled(!store.canConfirmDistribution)
        }
        .padding(Spacing.lg)
    }

    private func slotPicker(for card: PackCard) -> some View {
        HStack(spacing: Spacing.md) {
            Text(card.dish.emoji).font(.title)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(card.dish.name)
                    .font(.cardName)
                    .foregroundStyle(Color.inkText)
                HStack(spacing: Spacing.xs) {
                    ForEach(MealSlot.displayOrder) { slot in
                        Button {
                            store.send(.slotAssigned(card.id, slot))
                        } label: {
                            Text(slot.displayName)
                                .font(.captionM)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(
                                    Capsule().fill(
                                        store.distribution[card.id] == slot
                                        ? slot.accentColor.opacity(0.4)
                                        : Color.inkRaised
                                    )
                                )
                                .foregroundStyle(Color.inkText)
                        }
                        .buttonStyle(.plain)
                    }
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
}

#Preview {
    DistributeView(
        store: Store(initialState: PackOpeningFeature.State(date: .now)) {
            PackOpeningFeature()
        }
    )
    .background(Color.inkCanvas)
}
