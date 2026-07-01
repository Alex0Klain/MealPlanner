import ComposableArchitecture
import SwiftUI

public struct PackRevealView: View {
    @Bindable public var store: StoreOf<PackOpeningFeature>

    public init(store: StoreOf<PackOpeningFeature>) {
        self.store = store
    }

    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: Spacing.md),
        count: 3
    )

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Text("Выбери карточки")
                    .font(.appTitle)
                    .foregroundStyle(Color.inkText)
                Spacer()
                Text("\(store.selectedIDs.count) / \(store.maxSelectable)")
                    .font(.numeric)
                    .foregroundStyle(Color.plasma)
            }
            ScrollView {
                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    ForEach(store.cards) { card in
                        DishCard(
                            dish: card.dish,
                            isSelected: card.isSelected,
                            isInPlan: card.isInPlan
                        ) {
                            store.send(.cardTapped(card.id))
                        }
                    }
                }
            }
            Button {
                store.send(.confirmRevealTapped)
            } label: {
                Text("Разложить по слотам")
                    .font(.cardName)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(
                        store.canConfirmReveal
                        ? AnyShapeStyle(LinearGradient.plasmaCta)
                        : AnyShapeStyle(Color.inkRaised)
                    )
                    .foregroundStyle(Color.inkText)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.button))
            }
            .disabled(!store.canConfirmReveal)
        }
        .padding(Spacing.lg)
    }
}

#Preview {
    PackRevealView(
        store: Store(initialState: PackOpeningFeature.State(date: .now)) {
            PackOpeningFeature()
        } withDependencies: {
            $0.dishRepository = .preview
            $0.packGenerator  = .live
        }
    )
    .background(Color.inkCanvas)
}
