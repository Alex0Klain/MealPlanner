import ComposableArchitecture
import SwiftUI

public struct DayDetailView: View {
    @Bindable public var store: StoreOf<DayDetailFeature>

    public init(store: StoreOf<DayDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        content
            .navigationTitle(Text(store.date, format: .dateTime.weekday(.wide).day().month(.wide)))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { store.send(.onAppear) }
            .sheet(
                item: $store.scope(state: \.destination?.addMealSlot, action: \.destination.addMealSlot)
            ) { addStore in
                AddMealSlotView(store: addStore)
                    .presentationDetents([.medium])
            }
            .sheet(
                item: $store.scope(state: \.destination?.recipeDetail, action: \.destination.recipeDetail)
            ) { recipeStore in
                RecipeDetailView(store: recipeStore)
            }
    }

    private var content: some View {
        ZStack {
            Color.inkBase.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    planColumn
                }
                .padding(Spacing.lg)
            }
        }
    }

    private var planColumn: some View {
        DayPlanColumn(
            meals: store.plan.meals,
            dishesByID: store.dishesByID,
            onSlotTap: { store.send(.slotTapped($0)) },
            onMealTap: { store.send(.mealTapped($0)) },
            onRemove:  { store.send(.removeMealTapped($0)) }
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("\(store.plan.meals.count) блюд в плане")
                    .font(.bodyM)
                    .foregroundStyle(Color.inkText)
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        DayDetailView(
            store: Store(initialState: DayDetailFeature.State(date: .now)) {
                DayDetailFeature()
            } withDependencies: {
                $0.dishRepository = .preview
                $0.mealPlanRepository = .preview
            }
        )
    }
}
