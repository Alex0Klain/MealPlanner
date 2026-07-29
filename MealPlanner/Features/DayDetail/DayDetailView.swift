import ComposableArchitecture
import SwiftUI

/// Side flow B из дизайна: Day Detail — тот же шаблон, что Home,
/// но с навигацией «‹ дата ›» в шапке. Можно открывать пак и планировать
/// задним числом и наперёд.
public struct DayDetailView: View {
    @Bindable public var store: StoreOf<DayDetailFeature>

    @Namespace private var heroNamespace

    public init(store: StoreOf<DayDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.inkBase.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    dayNav
                    PackCTAButton {
                        store.send(.packCtaTapped)
                    }
                    .matchedTransitionSource(id: "day-pack", in: heroNamespace)
                    planSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.send(.onAppear) }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.packOpening, action: \.destination.packOpening)
        ) { packStore in
            PackOpeningView(store: packStore)
                .navigationTransition(.zoom(sourceID: "day-pack", in: heroNamespace))
        }
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
                .navigationTransition(.zoom(sourceID: recipeStore.dish.id, in: heroNamespace))
        }
    }

    // MARK: day navigation

    private var dayNav: some View {
        HStack {
            CircleIconButton(systemName: "chevron.left") {
                store.send(.previousDayTapped, animation: .snappy)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(store.date.formatted(.dateTime.day().month(.wide).weekday(.abbreviated)))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkText)
                    .contentTransition(.numericText())
                Text("\(store.plan.meals.count) из \(MealSlot.displayOrder.count) приёмов")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkMuted)
            }
            Spacer()
            CircleIconButton(systemName: "chevron.right") {
                store.send(.nextDayTapped, animation: .snappy)
            }
        }
    }

    // MARK: plan

    private var planSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            MonoCaption("План на день", size: 11)
            DayPlanColumn(
                meals: store.plan.meals,
                dishesByID: store.dishesByID,
                heroNamespace: heroNamespace,
                onSlotTap: { store.send(.slotTapped($0)) },
                onMealTap: { store.send(.mealTapped($0)) },
                onRemove:  { store.send(.removeMealTapped($0)) }
            )
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
