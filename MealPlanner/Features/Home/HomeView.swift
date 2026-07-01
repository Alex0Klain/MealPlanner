import ComposableArchitecture
import SwiftUI

public struct HomeView: View {
    @Bindable public var store: StoreOf<HomeFeature>

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.inkBase.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        header
                        DayPlanColumn(
                            meals: store.plan.meals,
                            dishesByID: store.dishesByID,
                            onSlotTap: { store.send(.slotTapped($0)) },
                            onMealTap: { store.send(.mealTapped($0)) },
                            onRemove:  { store.send(.removeMealTapped($0)) }
                        )
                        packCta
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle("Сегодня")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { store.send(.onAppear) }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.packOpening, action: \.destination.packOpening)
        ) { packStore in
            PackOpeningView(store: packStore)
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
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(store.date, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.captionM)
                    .foregroundStyle(Color.inkMuted)
                Text("\(store.plan.meals.count) блюд в плане")
                    .font(.bodyM)
                    .foregroundStyle(Color.inkText)
            }
            Spacer()
        }
    }

    private var packCta: some View {
        Button {
            store.send(.packCtaTapped)
        } label: {
            HStack(spacing: Spacing.md) {
                Text("🎁").font(.largeTitle)
                VStack(alignment: .leading) {
                    Text("Открыть пак").font(.cardName).foregroundStyle(Color.inkText)
                    Text("9 карточек, до 7 в план").font(.captionM).foregroundStyle(Color.inkText.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Color.inkText.opacity(0.7))
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(LinearGradient.plasmaCta)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .pressScale()
    }
}

/// Переиспользуемая колонка слотов плана — используется и в Home, и в DayDetail.
public struct DayPlanColumn: View {
    public let meals: [PlannedMeal]
    public let dishesByID: [Dish.ID: Dish]
    public var onSlotTap: (MealSlot) -> Void
    public var onMealTap: (PlannedMeal) -> Void
    public var onRemove:  (PlannedMeal) -> Void

    public init(
        meals: [PlannedMeal],
        dishesByID: [Dish.ID: Dish],
        onSlotTap: @escaping (MealSlot) -> Void,
        onMealTap: @escaping (PlannedMeal) -> Void,
        onRemove: @escaping (PlannedMeal) -> Void
    ) {
        self.meals = meals
        self.dishesByID = dishesByID
        self.onSlotTap = onSlotTap
        self.onMealTap = onMealTap
        self.onRemove = onRemove
    }

    public var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(MealSlot.displayOrder) { slot in
                let mealsInSlot = meals.filter { $0.slot == slot }
                if mealsInSlot.isEmpty {
                    EmptySlotView(slot: slot) { onSlotTap(slot) }
                } else {
                    ForEach(mealsInSlot) { meal in
                        if let dish = dishesByID[meal.dishID] {
                            MealSlotRow(
                                slot: slot,
                                dish: dish,
                                onTap: { onMealTap(meal) },
                                onRemove: { onRemove(meal) }
                            )
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.dishRepository = .preview
            $0.mealPlanRepository = .preview
        }
    )
}
