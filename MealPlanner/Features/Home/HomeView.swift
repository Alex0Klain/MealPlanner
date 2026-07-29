import ComposableArchitecture
import SwiftUI

/// Экран 01 из дизайна: «Сегодня — план дня».
/// Header (дата-caption, приветствие, статистика) → Pack CTA →
/// «План на день» → слоты → «+ Добавить ещё один приём».
public struct HomeView: View {
    @Bindable public var store: StoreOf<HomeFeature>

    @Namespace private var heroNamespace

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
                        PackCTAButton {
                            store.send(.packCtaTapped)
                        }
                        .matchedTransitionSource(id: "pack", in: heroNamespace)
                        planSection
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear { store.send(.onAppear) }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.packOpening, action: \.destination.packOpening)
        ) { packStore in
            PackOpeningView(store: packStore)
                .navigationTransition(.zoom(sourceID: "pack", in: heroNamespace))
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

    // MARK: header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            MonoCaption(store.date.formatted(.dateTime.weekday(.wide).day().month(.wide)), size: 11)
            Text(greeting)
                .font(.screenTitle)
                .foregroundStyle(Color.inkText)
            HStack(spacing: 8) {
                Text("\(store.plan.meals.count) из \(MealSlot.displayOrder.count) приёмов")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.inkText.opacity(0.8))
                dotSeparator
                Text("\(totalCalories) ккал")
                    .font(.mono(12, weight: .medium))
                    .foregroundStyle(Color.inkText.opacity(0.8))
            }
            .padding(.top, 2)
        }
    }

    private var dotSeparator: some View {
        Circle()
            .fill(Color.inkMuted.opacity(0.6))
            .frame(width: 3, height: 3)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12:  "Доброе утро"
        case 12..<18: "Добрый день"
        case 18..<23: "Добрый вечер"
        default:      "Доброй ночи"
        }
    }

    private var totalCalories: Int {
        store.plan.meals
            .compactMap { store.dishesByID[$0.dishID]?.calories }
            .reduce(0, +)
    }

    // MARK: plan

    private var planSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            MonoCaption("План на день", size: 11)
                .padding(.top, Spacing.xs)
            DayPlanColumn(
                meals: store.plan.meals,
                dishesByID: store.dishesByID,
                heroNamespace: heroNamespace,
                onSlotTap: { store.send(.slotTapped($0)) },
                onMealTap: { store.send(.mealTapped($0)) },
                onRemove:  { store.send(.removeMealTapped($0)) }
            )
            addExtraMealButton
        }
    }

    private var addExtraMealButton: some View {
        Button {
            store.send(.slotTapped(.snack))
        } label: {
            HStack(spacing: 6) {
                Text("+")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.plasma)
                Text("Добавить ещё один приём")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkText.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(RoundedRectangle(cornerRadius: Radius.slot))
        }
        .pressScale()
    }
}

/// Переиспользуемая колонка слотов плана — используется и в Home, и в DayDetail.
public struct DayPlanColumn: View {
    public let meals: [PlannedMeal]
    public let dishesByID: [Dish.ID: Dish]
    public var heroNamespace: Namespace.ID?
    public var onSlotTap: (MealSlot) -> Void
    public var onMealTap: (PlannedMeal) -> Void
    public var onRemove:  (PlannedMeal) -> Void

    public init(
        meals: [PlannedMeal],
        dishesByID: [Dish.ID: Dish],
        heroNamespace: Namespace.ID? = nil,
        onSlotTap: @escaping (MealSlot) -> Void,
        onMealTap: @escaping (PlannedMeal) -> Void,
        onRemove: @escaping (PlannedMeal) -> Void
    ) {
        self.meals = meals
        self.dishesByID = dishesByID
        self.heroNamespace = heroNamespace
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
                            mealRow(slot: slot, meal: meal, dish: dish)
                        }
                    }
                }
            }
        }
        .animation(.snappy, value: meals)
    }

    @ViewBuilder
    private func mealRow(slot: MealSlot, meal: PlannedMeal, dish: Dish) -> some View {
        let row = MealSlotRow(
            slot: slot,
            dish: dish,
            onTap: { onMealTap(meal) },
            onRemove: { onRemove(meal) }
        )
        if let heroNamespace {
            row.matchedTransitionSource(id: dish.id, in: heroNamespace)
        } else {
            row
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
