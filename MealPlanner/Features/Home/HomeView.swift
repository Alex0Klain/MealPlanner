import ComposableArchitecture
import SwiftUI

/// Экран 01 из дизайна: «Сегодня — план дня».
/// Header закреплён и не уезжает при скролле; контент — List, чтобы строки
/// плана поддерживали нативный swipe-to-delete/replace.
public struct HomeView: View {
    @Bindable public var store: StoreOf<HomeFeature>

    @Namespace private var heroNamespace

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.md)
                    .background(Color.inkBase)
                List {
                    Group {
                        PackCTAButton {
                            store.send(.packCtaTapped)
                        }
                        .matchedTransitionSource(id: "pack", in: heroNamespace)

                        MonoCaption("План на день", size: 11)
                            .padding(.top, Spacing.sm)

                        planRows

                        addExtraMealButton
                    }
                    .listRowInsets(EdgeInsets(top: 5, leading: Spacing.lg, bottom: 5, trailing: Spacing.lg))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(Color.inkBase.ignoresSafeArea())
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

    // MARK: header (pinned)

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            MonoCaption(store.date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.appRU)), size: 11)
            Text(greeting)
                .font(.screenTitle)
                .foregroundStyle(Color.inkText)
            HStack(spacing: 8) {
                Text("\(filledSlots) из \(MealSlot.displayOrder.count) приёмов")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.inkText.opacity(0.8))
                dotSeparator
                Text("\(totalCalories) ккал")
                    .font(.mono(12, weight: .medium))
                    .foregroundStyle(Color.inkText.opacity(0.8))
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    /// Приёмы считаем по заполненным слотам, а не по числу блюд:
    /// в слоте может лежать до двух блюд.
    private var filledSlots: Int {
        Set(store.plan.meals.map(\.slot)).count
    }

    private var totalCalories: Int {
        store.plan.meals
            .compactMap { store.dishesByID[$0.dishID]?.calories }
            .reduce(0, +)
    }

    // MARK: plan rows

    @ViewBuilder
    private var planRows: some View {
        ForEach(MealSlot.displayOrder) { slot in
            let mealsInSlot = store.plan.meals.filter { $0.slot == slot }
            if mealsInSlot.isEmpty {
                EmptySlotView(slot: slot) { store.send(.slotTapped(slot)) }
            } else {
                ForEach(mealsInSlot) { meal in
                    if let dish = store.dishesByID[meal.dishID] {
                        MealSlotRow(
                            slot: slot,
                            dish: dish,
                            onTap: { store.send(.mealTapped(meal)) },
                            onRemove: { store.send(.removeMealTapped(meal)) }
                        )
                        .matchedTransitionSource(id: dish.id, in: heroNamespace)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.send(.removeMealTapped(meal))
                            } label: {
                                Label("Убрать", systemImage: "trash")
                            }
                            Button {
                                store.send(.replaceMealTapped(meal))
                            } label: {
                                Label("Заменить", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .tint(Color.plasmaDeep)
                        }
                    }
                }
            }
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
